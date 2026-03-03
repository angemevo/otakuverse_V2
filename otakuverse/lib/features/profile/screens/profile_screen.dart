import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/auth/controllers/auth_controller.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/services/post_service.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';
import 'package:otakuverse/features/profile/controllers/follow_controller.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/screens/edit_profile_screen.dart';
import 'package:otakuverse/features/profile/services/profile_service.dart';
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
  bool _isLoading   = true;
  bool _isMe        = false;
  bool _isFollowing = false;
  late TabController _tabController;
  final _followController = Get.find<FollowController>();

  final _profileService = ProfileService();
  final _postService    = PostService();

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    if (widget.userId != null) {
      _followController.loadFollowState(widget.userId!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── CHARGEMENT ──────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final targetId = widget.userId ?? _currentUserId;
      _isMe = widget.userId == null || widget.userId == _currentUserId;

      final profile = _isMe
          ? await _profileService.getMyProfile()
          : await _profileService.getProfile(targetId);

      List<PostModel> posts = [];
      try {
        posts = await _postService.getPostsByUser(targetId);
      } catch (e) {
        print('⚠️ Erreur posts : $e');
      }

      List<PostModel> likedPosts = [];
      if (_isMe) {
        try {
          likedPosts = await _postService.getLikedPosts(_currentUserId);
        } catch (e) {
          print('⚠️ Erreur likes : $e');
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
      print('🔴 Erreur profil : $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── DÉCONNEXION ─────────────────────────────────────────────────
  Future<void> _logout() async {
    await Get.find<AuthController>().signOut();
  }

  // ─── SETTINGS SHEET ──────────────────────────────────────────────
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGray,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.mediumGray,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          _settingsItem(Icons.edit_outlined, 'Modifier le profil', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => EditProfileScreen(profile: _profile!),
            )).then((_) => _loadData());
          }),
          _settingsItem(Icons.lock_outline, 'Changer le mot de passe',
              () => Navigator.pop(context)),
          _settingsItem(Icons.notifications_outlined, 'Notifications',
              () => Navigator.pop(context)),
          _settingsItem(Icons.privacy_tip_outlined, 'Confidentialité',
              () => Navigator.pop(context)),
          const Divider(color: AppColors.mediumGray, height: 1),
          _settingsItem(Icons.logout, 'Se déconnecter', () {
            Navigator.pop(context);
            _showLogoutConfirmation();
          }, color: AppColors.crimsonRed),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _settingsItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.pureWhite, size: 22),
      title: Text(label,
          style: GoogleFonts.inter(
              color: color ?? AppColors.pureWhite, fontSize: 15)),
      trailing: color == null
          ? const Icon(Icons.arrow_forward_ios,
              color: AppColors.mediumGray, size: 14)
          : null,
      onTap: onTap,
    );
  }

  // ─── LOGOUT DIALOG ───────────────────────────────────────────────
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkGray,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Se déconnecter ?',
            style: GoogleFonts.poppins(
                color: AppColors.pureWhite, fontWeight: FontWeight.w600)),
        content: Text('Tu seras redirigé vers la page de connexion.',
            style: GoogleFonts.inter(color: AppColors.mediumGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: AppColors.mediumGray)),
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
                style: GoogleFonts.inter(color: AppColors.pureWhite)),
          ),
        ],
      ),
    );
  }

  // ─── DELETE POST ─────────────────────────────────────────────────
  Future<void> _deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      setState(() => _posts.removeWhere((p) => p.id == postId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post supprimé'),
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

  // ─── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.crimsonRed)),
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
                      color: AppColors.pureWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: _loadData,
                child: Text('Réessayer',
                    style:
                        GoogleFonts.inter(color: AppColors.crimsonRed)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: RefreshIndicator(
        color: AppColors.crimsonRed,
        backgroundColor: AppColors.darkGray,
        onRefresh: _loadData,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildProfileHeader()),
            SliverToBoxAdapter(child: _buildStats()),
            SliverToBoxAdapter(child: _buildBio()),
            if (_profile!.favoriteGenres.isNotEmpty)
              SliverToBoxAdapter(child: _buildGenres()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(TabBar(
                controller: _tabController,
                indicatorColor: AppColors.crimsonRed,
                indicatorWeight: 3,
                labelColor: AppColors.crimsonRed,
                unselectedLabelColor: AppColors.mediumGray,
                labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'À propos'),
                  Tab(text: 'Animés'),
                  Tab(text: 'Likes'),
                ],
              )),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(),
              _buildAboutTab(),
              _buildAnimesTab(),
              _buildLikesTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SLIVER APP BAR ──────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      backgroundColor: AppColors.deepBlack,
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      title: Text(_profile!.displayNameOrUsername,
          style: GoogleFonts.poppins(
              color: AppColors.pureWhite, fontWeight: FontWeight.w600)),
      actions: [
        if (_isMe)
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.pureWhite),
            onPressed: _showSettingsSheet,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          _profile!.hasBanner
              ? Image.network(_profile!.bannerUrl!, fit: BoxFit.cover)
              : Container(
                  decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient)),
          DecoratedBox(
              decoration:
                  BoxDecoration(gradient: AppColors.overlayGradient)),
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Stack(children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.crimsonRed, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.darkGray,
                      backgroundImage: _profile!.hasAvatar
                          ? NetworkImage(_profile!.avatarUrl!)
                          : null,
                      child: !_profile!.hasAvatar
                          ? const Icon(Icons.person,
                              color: AppColors.pureWhite, size: 32)
                          : null,
                    ),
                  ),
                  if (_isMe)
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileScreen(profile: _profile!),
                            ),
                          );
                          _loadData();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: AppColors.crimsonRed,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              color: AppColors.pureWhite, size: 12),
                        ),
                      ),
                    ),
                ]),
                const Spacer(),
                if (_isMe)
                  _buildActionButton('Modifier', onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile!)));
                    _loadData();
                  }, outlined: true)
                else
                  Obx(() {
                    final following = _followController.isFollowing(widget.userId!);
                    return _buildFollowButton(
                      isFollowing: following,
                      isLoading:   _followController.isLoading.value,
                      onTap:       () => _followController.toggleFollow(widget.userId!),
                    );
                  }),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildActionButton(String label,
      {required VoidCallback onTap, bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : AppColors.crimsonRed,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: outlined
                  ? AppColors.pureWhite
                  : AppColors.crimsonRed,
              width: 2),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
    );
  }

  Widget _buildFollowButton({
    required bool          isFollowing,
    required bool          isLoading,
    required VoidCallback  onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve:    Curves.easeOutCubic,
        padding:  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color:        isFollowing ? Colors.transparent : AppColors.crimsonRed,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isFollowing
                ? AppColors.pureWhite.withValues(alpha: 0.5)
                : AppColors.crimsonRed,
            width: 2,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color:       Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFollowing
                        ? Icons.check
                        : Icons.person_add_outlined,
                    color: AppColors.pureWhite,
                    size:  16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFollowing ? 'Abonné' : 'Suivre',
                    style: GoogleFonts.inter(
                      color:      AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                      fontSize:   14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── PROFILE HEADER ──────────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_profile!.displayNameOrUsername,
                style: GoogleFonts.poppins(
                    color: AppColors.pureWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            if (_profile!.isVerified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified,
                  color: AppColors.crimsonRed, size: 20),
            ],
          ]),
          if (_profile!.location != null || _profile!.website != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (_profile!.location != null) ...[
                const Icon(Icons.location_on_outlined,
                    color: AppColors.mediumGray, size: 14),
                const SizedBox(width: 4),
                Text(_profile!.location!,
                    style: GoogleFonts.inter(
                        color: AppColors.mediumGray, fontSize: 13)),
                const SizedBox(width: 12),
              ],
              if (_profile!.website != null) ...[
                const Icon(Icons.link,
                    color: AppColors.crimsonRed, size: 14),
                const SizedBox(width: 4),
                Text(_profile!.website!,
                    style: GoogleFonts.inter(
                        color: AppColors.crimsonRed,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.crimsonRed)),
              ],
            ]),
          ],
        ],
      ),
    );
  }

  // ─── STATS ───────────────────────────────────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        const Icon(Icons.people_outline,
            color: AppColors.mediumGray, size: 16),
        const SizedBox(width: 6),
        RichText(
            text: TextSpan(children: [
          TextSpan(
              text: '${_profile!.followersCount}',
              style: GoogleFonts.inter(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          TextSpan(
              text: ' Abonnés',
              style: GoogleFonts.inter(
                  color: AppColors.mediumGray, fontSize: 14)),
        ])),
        const SizedBox(width: 16),
        RichText(
            text: TextSpan(children: [
          TextSpan(
              text: '${_profile!.postsCount}',
              style: GoogleFonts.inter(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          TextSpan(
              text: ' Posts',
              style: GoogleFonts.inter(
                  color: AppColors.mediumGray, fontSize: 14)),
        ])),
      ]),
    );
  }

  // ─── BIO ─────────────────────────────────────────────────────────
  Widget _buildBio() {
    if (!_profile!.hasBio) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Text(_profile!.bio!,
          style: GoogleFonts.inter(
              color: AppColors.lightGray, fontSize: 14, height: 1.5)),
    );
  }

  // ─── GENRES ──────────────────────────────────────────────────────
  Widget _buildGenres() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _profile!.favoriteGenres
            .map((g) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonWithOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.crimsonWithOpacity(0.4)),
                  ),
                  child: Text('#$g',
                      style: GoogleFonts.inter(
                          color: AppColors.lightCrimson,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ))
            .toList(),
      ),
    );
  }

  // ─── TAB : POSTS ─────────────────────────────────────────────────
  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.post_add,
                color: AppColors.mediumGray, size: 48),
            const SizedBox(height: 12),
            Text('Aucun post',
                style:
                    GoogleFonts.inter(color: AppColors.mediumGray)),
          ],
        ),
      );
    }

    // ✅ PostCard générale + bouton suppression pour ses propres posts
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Stack(
          children: [
            // ✅ PostCard générale
            PostCard(
              post:    post,
              isLiked: post.isLiked,
            ),

            // ✅ Bouton suppression uniquement pour ses propres posts
            if (_isMe)
              Positioned(
                top: 10, right: 4,
                child: PopupMenuButton<String>(
                  color: AppColors.darkGray,
                  icon: const SizedBox.shrink(), // Caché — PostCard a déjà son menu
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await _confirmDelete();
                      if (confirm == true) await _deletePost(post.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline,
                            color: AppColors.crimsonRed, size: 18),
                        const SizedBox(width: 8),
                        Text('Supprimer',
                            style: GoogleFonts.inter(
                                color: AppColors.crimsonRed)),
                      ]),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkGray,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer ce post ?',
            style: GoogleFonts.poppins(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w600)),
        content: Text('Cette action est irréversible.',
            style: GoogleFonts.inter(color: AppColors.mediumGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style:
                    GoogleFonts.inter(color: AppColors.mediumGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimsonRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Supprimer',
                style:
                    GoogleFonts.inter(color: AppColors.pureWhite)),
          ),
        ],
      ),
    );
  }

  // ─── TAB : À PROPOS ──────────────────────────────────────────────
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _aboutSection('Informations', [
          if (_profile!.location != null)
            _aboutItem(Icons.location_on_outlined, 'Localisation',
                _profile!.location!),
          if (_profile!.website != null)
            _aboutItem(Icons.link, 'Site web', _profile!.website!,
                isLink: true),
          if (_profile!.gender != null)
            _aboutItem(Icons.person_outline, 'Genre',
                _genderLabel(_profile!.gender!)),
        ]),
        const SizedBox(height: 16),
        _aboutSection('Statistiques', [
          _aboutItem(Icons.article_outlined, 'Posts',
              '${_profile!.postsCount}'),
          _aboutItem(Icons.people_outline, 'Abonnés',
              '${_profile!.followersCount}'),
          _aboutItem(Icons.person_add_outlined, 'Abonnements',
              '${_profile!.followingCount}'),
        ]),
      ],
    );
  }

  Widget _aboutSection(String title, List<Widget> items) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.mediumGray.withValues(alpha: 0.3)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _aboutItem(IconData icon, String label, String value,
      {bool isLink = false}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: AppColors.crimsonRed, size: 20),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.mediumGray, fontSize: 14)),
        const Spacer(),
        Flexible(
          child: Text(value,
              style: GoogleFonts.inter(
                color: isLink
                    ? AppColors.crimsonRed
                    : AppColors.pureWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration:
                    isLink ? TextDecoration.underline : null,
                decorationColor: AppColors.crimsonRed,
              ),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  // ─── TAB : ANIMÉS ────────────────────────────────────────────────
  Widget _buildAnimesTab() {
    final hasContent = _profile!.favoriteAnime.isNotEmpty ||
        _profile!.favoriteManga.isNotEmpty;

    if (!hasContent) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                color: AppColors.mediumGray, size: 48),
            const SizedBox(height: 12),
            Text('Aucun animé/manga favori',
                style:
                    GoogleFonts.inter(color: AppColors.mediumGray)),
            if (_isMe) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditProfileScreen(profile: _profile!),
                    ),
                  );
                  _loadData();
                },
                child: Text('Ajouter des favoris',
                    style: GoogleFonts.inter(
                        color: AppColors.crimsonRed,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_profile!.favoriteAnime.isNotEmpty) ...[
          Text('Animés favoris',
              style: GoogleFonts.poppins(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _profile!.favoriteAnime
                .map((a) => _favoriteChip(a))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (_profile!.favoriteManga.isNotEmpty) ...[
          Text('Mangas favoris',
              style: GoogleFonts.poppins(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _profile!.favoriteManga
                .map((m) => _favoriteChip(m))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _favoriteChip(String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.crimsonWithOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.crimsonWithOpacity(0.4)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: AppColors.lightCrimson,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    );
  }

  // ─── TAB : LIKES ─────────────────────────────────────────────────
  Widget _buildLikesTab() {
    if (!_isMe) {
      return Center(
        child: Text('Privé',
            style: GoogleFonts.inter(color: AppColors.mediumGray)),
      );
    }

    if (_likedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                color: AppColors.mediumGray, size: 48),
            const SizedBox(height: 12),
            Text('Aucun post liké',
                style:
                    GoogleFonts.inter(color: AppColors.mediumGray)),
          ],
        ),
      );
    }

    // ✅ PostCard générale pour les likes aussi
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _likedPosts.length,
      itemBuilder: (context, index) {
        final post = _likedPosts[index];
        return PostCard(
          post:    post,
          isLiked: true, // ✅ Tous ces posts sont likés
        );
      },
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  String _genderLabel(String gender) {
    const labels = {
      'male':             'Homme',
      'female':           'Femme',
      'other':            'Autre',
      'prefer_not_to_say':'Préfère ne pas dire',
    };
    return labels[gender] ?? gender;
  }
}

// ─── TAB BAR DELEGATE ────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(_, __, ___) =>
      Container(color: AppColors.deepBlack, child: tabBar);

  @override double get maxExtent => tabBar.preferredSize.height;
  @override double get minExtent => tabBar.preferredSize.height;
  @override bool   shouldRebuild(_) => false;
}