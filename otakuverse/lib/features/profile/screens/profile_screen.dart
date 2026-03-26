import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/widgets/connectivity_wrapper.dart';
import 'package:otakuverse/features/auth/controllers/auth_controller.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/services/post_service.dart';
import 'package:otakuverse/features/profile/controllers/follow_controller.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/screens/edit_profile_screen.dart';
import 'package:otakuverse/features/profile/services/profile_service.dart';
import 'package:otakuverse/features/profile/widgets/profile_info_section.dart';
import 'package:otakuverse/features/profile/widgets/profile_settings_sheet.dart';
import 'package:otakuverse/features/profile/widgets/profile_sliver_app_bar.dart';
import 'package:otakuverse/features/profile/widgets/profile_tab_about.dart';
import 'package:otakuverse/features/profile/widgets/profile_tab_animes.dart';
import 'package:otakuverse/features/profile/widgets/profile_tab_bar_delegate.dart';
import 'package:otakuverse/features/profile/widgets/profile_tab_bookmarks.dart';
import 'package:otakuverse/features/profile/widgets/profile_tab_likes.dart';
import 'package:otakuverse/features/profile/widgets/profile_tab_posts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  ProfileModel?   _profile;
  List<PostModel> _posts      = [];
  List<PostModel> _likedPosts = [];
  bool            _isLoading  = true;
  bool            _isRefreshing = false; // ✅ Refresh silencieux
  late bool       _isMe;
  late TabController _tabController;

  final _followController = Get.find<FollowController>();
  final _profileService   = ProfileService();
  final _postService      = PostService();

  // ✅ Channels Realtime
  RealtimeChannel? _postsChannel;
  RealtimeChannel? _followsChannel;
  RealtimeChannel? _likesChannel;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser!.id;

  String get _targetId => widget.userId ?? _currentUserId;

  @override
  void initState() {
    super.initState();
    _isMe = widget.userId == null ||
            widget.userId == _currentUserId;

    _tabController = TabController(
      length: _isMe ? 5 : 4,
      vsync:  this,
    );

    _loadData();
    if (!_isMe) _followController.loadFollowState(_targetId);

    // ✅ Démarrer le Realtime après le premier chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeRealtime();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _unsubscribeRealtime();
    super.dispose();
  }

  // ─── REALTIME SUBSCRIPTIONS ──────────────────────────────────────
  void _subscribeRealtime() {
    final supabase = Supabase.instance.client;

    // ✅ Posts du profil ciblé
    _postsChannel = supabase
        .channel('profile_posts_$_targetId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'posts',
          filter: PostgresChangeFilter(
            type:  PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  _targetId,
          ),
          callback: (_) {
            debugPrint('🆕 Realtime: nouveau post profil');
            _silentRefresh();
          },
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.delete,
          schema: 'public',
          table:  'posts',
          filter: PostgresChangeFilter(
            type:  PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  _targetId,
          ),
          callback: (payload) {
            debugPrint('🗑 Realtime: post supprimé profil');
            // ✅ Retirer le post immédiatement
            final deletedId =
                payload.oldRecord['id'] as String?;
            if (deletedId != null && mounted) {
              setState(() {
                _posts.removeWhere(
                    (p) => p.id == deletedId);
                _likedPosts.removeWhere(
                    (p) => p.id == deletedId);
                // ✅ Décrémenter le compteur du profil
                if (_profile != null) {
                  _profile = _profile!.copyWith(
                    postsCount: (_profile!.postsCount - 1)
                        .clamp(0, double.maxFinite.toInt()),
                  );
                }
              });
            }
          },
        )
        .subscribe();

    // ✅ Follows — pour compteurs suiveurs/abonnements
    _followsChannel = supabase
        .channel('profile_follows_$_targetId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'follows',
          callback: (payload) {
            final followerId =
                payload.newRecord['follower_id'] as String?;
            final followingId =
                payload.newRecord['following_id'] as String?;

            if (followerId == _targetId ||
                followingId == _targetId) {
              _silentRefresh();
            }
          },
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.delete,
          schema: 'public',
          table:  'follows',
          callback: (payload) {
            final followerId =
                payload.oldRecord['follower_id'] as String?;
            final followingId =
                payload.oldRecord['following_id'] as String?;

            if (followerId == _targetId ||
                followingId == _targetId) {
              _silentRefresh();
            }
          },
        )
        .subscribe();

    // ✅ Likes sur les posts du profil
    _likesChannel = supabase
        .channel('profile_likes_$_targetId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'likes',
          callback: (payload) {
            final postId =
                payload.newRecord['post_id'] as String?;
            if (postId != null) {
              _updateLikeCount(postId, delta: 1);
            }
          },
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.delete,
          schema: 'public',
          table:  'likes',
          callback: (payload) {
            final postId =
                payload.oldRecord['post_id'] as String?;
            if (postId != null) {
              _updateLikeCount(postId, delta: -1);
            }
          },
        )
        .subscribe();

    debugPrint(
        '✅ Realtime profil souscrit: $_targetId');
  }

  void _unsubscribeRealtime() {
    _postsChannel?.unsubscribe();
    _followsChannel?.unsubscribe();
    _likesChannel?.unsubscribe();
    debugPrint('🔴 Realtime profil désouscrit');
  }

  // ─── UPDATE LIKE OPTIMISTE ───────────────────────────────────────
  void _updateLikeCount(
      String postId, {required int delta}) {
    if (!mounted) return;
    setState(() {
      final index =
          _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = post.copyWith(
          likesCount: (post.likesCount + delta)
              .clamp(0, double.maxFinite.toInt()),
        );
      }
    });
  }

  // ─── REFRESH SILENCIEUX (sans loader) ────────────────────────────
  Future<void> _silentRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final profile = _isMe
          ? await _profileService.getMyProfile()
          : await _profileService.getProfile(_targetId);

      final posts =
          await _postService.getPostsByUser(_targetId);

      List<PostModel> likedPosts = [];
      if (_isMe) {
        likedPosts = await _postService
            .getLikedPosts(_currentUserId);
      }

      if (mounted) {
        setState(() {
          _profile    = profile;
          _posts      = posts;
          _likedPosts = likedPosts;
        });
        debugPrint('✅ Profil refreshed silencieusement');
      }
    } catch (e) {
      debugPrint('❌ silentRefresh: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  // ─── CHARGEMENT INITIAL (avec loader) ────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = _isMe
          ? await _profileService.getMyProfile()
          : await _profileService.getProfile(_targetId);

      List<PostModel> posts = [];
      try {
        posts =
            await _postService.getPostsByUser(_targetId);
      } catch (e) {
        debugPrint('⚠️ Erreur posts: $e');
      }

      List<PostModel> likedPosts = [];
      if (_isMe) {
        try {
          likedPosts = await _postService
              .getLikedPosts(_currentUserId);
        } catch (e) {
          debugPrint('⚠️ Erreur likes: $e');
        }
      }

      if (mounted) {
        setState(() {
          _profile    = profile;
          _posts      = posts;
          _likedPosts = likedPosts;
          _isLoading  = false;
        });
      }
    } catch (e) {
      debugPrint('🔴 Erreur profil: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── FOLLOW ──────────────────────────────────────────────────────
  Future<void> _handleToggleFollow() async {
    await _followController.toggleFollow(_targetId);
    await _silentRefresh(); // ✅ Refresh silencieux au lieu de _loadData
  }

  // ─── DÉCONNEXION ─────────────────────────────────────────────────
  Future<void> _logout() async {
    _unsubscribeRealtime(); // ✅ Fermer les channels avant logout
    await Get.find<AuthController>().signOut();
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkGray,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Se déconnecter ?',
            style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w600)),
        content: Text(
            'Tu seras redirigé vers la page de connexion.',
            style: GoogleFonts.inter(
                color: AppColors.mediumGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.inter(
                    color: AppColors.mediumGray)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimsonRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Déconnecter',
                style: GoogleFonts.inter(
                    color: AppColors.pureWhite)),
          ),
        ],
      ),
    );
  }

  // ─── DELETE POST ─────────────────────────────────────────────────
  Future<void> _deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      // ✅ Mise à jour immédiate sans attendre Realtime
      if (mounted) {
        setState(() {
          _posts.removeWhere((p) => p.id == postId);
          _likedPosts.removeWhere((p) => p.id == postId);
          if (_profile != null) {
            _profile = _profile!.copyWith(
              postsCount: (_profile!.postsCount - 1)
                  .clamp(0, double.maxFinite.toInt()),
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('Post supprimé'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // ─── Redirection to Edit Profile Page ───────────────────────────────────────────────────────
  Future<void> _goToEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: _profile!,
        ),
      ),
    );
    if (updated == true && mounted) {
      await _loadData();
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ConnectivityWrapper(
        onRetry: _loadData,
        child: const Scaffold(
          backgroundColor: AppColors.deepBlack,
          body: Center(
            child: CircularProgressIndicator(
                color: AppColors.crimsonRed),
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined,
                  color: AppColors.mediumGray, size: 48),
              const SizedBox(height: 16),
              Text('Profil introuvable',
                  style: GoogleFonts.poppins(
                      color:      AppColors.pureWhite,
                      fontSize:   20,
                      fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: _loadData,
                child: Text('Réessayer',
                    style: GoogleFonts.inter(
                        color: AppColors.crimsonRed)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: RefreshIndicator(
        color:           AppColors.crimsonRed,
        backgroundColor: AppColors.darkGray,
        onRefresh:       _loadData,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            ProfileSliverAppBar(
              profile:       _profile!,
              isMe:          _isMe,
              targetId:      _targetId,
              onSettingsTap: () => showSettingsSheet(
                context:           context,
                profile:           _profile!,
                onProfileUpdated:  _loadData,
                onLogoutRequested: _showLogoutConfirmation,
              ),
              onEditProfile:  _goToEditProfile,
              onToggleFollow: _handleToggleFollow,
            ),
            SliverToBoxAdapter(
              child: ProfileInfoSection(
                  profile: _profile!),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: ProfileTabBarDelegate(
                TabBar(
                  controller:           _tabController,
                  indicatorColor:       AppColors.crimsonRed,
                  indicatorWeight:      3,
                  labelColor:           AppColors.crimsonRed,
                  unselectedLabelColor: AppColors.mediumGray,
                  isScrollable:         true,
                  tabAlignment:         TabAlignment.start,
                  labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize:   13),
                  unselectedLabelStyle:
                      GoogleFonts.inter(fontSize: 13),
                  tabs: [
                    const Tab(text: 'Posts'),
                    const Tab(text: 'À propos'),
                    const Tab(text: 'Animés'),
                    const Tab(text: 'Likes'),
                    if (_isMe)
                      const Tab(text: 'Sauvegardes'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              ProfileTabPosts(
                posts:         _posts,
                currentUserId: _currentUserId,
                isMe:          _isMe,
                onDeletePost:  _deletePost,
              ),
              ProfileTabAbout(profile: _profile!),
              ProfileTabAnimes(
                profile:          _profile!,
                isMe:             _isMe,
                onProfileUpdated: _loadData,
              ),
              ProfileTabLikes(
                likedPosts:    _likedPosts,
                isMe:          _isMe,
                currentUserId: _currentUserId,
                onDeletePost:  _deletePost,
              ),
              if (_isMe)
                ProfileTabBookmarks(
                  currentUserId: _currentUserId,
                  onDeletePost:  _deletePost,
                ),
            ],
          ),
        ),
      ),
    );
  }
}