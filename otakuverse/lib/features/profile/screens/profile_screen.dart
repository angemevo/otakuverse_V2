import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/services/realtime_service.dart';
import 'package:otakuverse/features/profile/widgets/profile_banner.dart';
import 'package:otakuverse/features/profile/widgets/profile_settings_sheet.dart';
import 'package:otakuverse/features/profile/widgets/profile_user_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/features/message/models/conversation_model.dart';
import 'package:otakuverse/features/message/screens/chat_screen.dart';
import 'package:otakuverse/features/message/services/message_service.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/screens/edit_profile_screen.dart';
import 'tabs/profile_posts_tab.dart';
import 'tabs/profile_placeholder_tabs.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

  final _supabase = Supabase.instance.client;
  String get _myUid => _supabase.auth.currentUser!.id;

  ProfileModel? _profile;
  bool          _isLoading     = true;
  bool          _isMe          = false;
  bool          _isFollowing   = false;
  bool          _isOpeningChat = false;

  late final TabController _tabCtrl;

  // ✅ Channels Realtime
  RealtimeChannel? _followsChannel;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _followsChannel?.unsubscribe();

    // ✅ Nettoyer le callback RealtimeService
    if (Get.isRegistered<RealtimeService>()) {
      RealtimeService.to.onRankUpdated = null;
    }
    super.dispose();
  }

  // ─── Chargement ──────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final targetId = widget.userId ?? _myUid;
      _isMe = widget.userId == null || widget.userId == _myUid;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', targetId)
          .maybeSingle();

      if (data == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final profile = ProfileModel.fromJson(data);

      if (!_isMe) {
        final follow = await _supabase
            .from('follows')
            .select('id')
            .eq('follower_id',  _myUid)
            .eq('following_id', targetId)
            .maybeSingle();
        _isFollowing = follow != null;
      }

      if (mounted) {
        setState(() { _profile = profile; _isLoading = false; });
        _subscribeFollowsRealtime(targetId);
        // ✅ Souscription rang uniquement pour son propre profil
        if (_isMe) _listenToRankUpdates();
      }
    } catch (e, st) {
      debugPrint('❌ loadProfile: $e\n$st');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Realtime follows ────────────────────────────────────────────

  void _subscribeFollowsRealtime(String targetId) {
    _followsChannel?.unsubscribe();

    _followsChannel = _supabase
        .channel('profile_follows:$targetId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'follows',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'following_id',
            value:  targetId,
          ),
          callback: (_) {
            if (!mounted || _profile == null) return;
            setState(() => _profile = _profile!.copyWith(
              followersCount: _profile!.followersCount + 1,
            ));
          },
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.delete,
          schema: 'public',
          table:  'follows',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'following_id',
            value:  targetId,
          ),
          callback: (_) {
            if (!mounted || _profile == null) return;
            setState(() => _profile = _profile!.copyWith(
              followersCount:
                  (_profile!.followersCount - 1).clamp(0, 999999999),
            ));
          },
        )
        .subscribe();
  }

  // ─── Realtime rang / niveau ───────────────────────────────────────
  // ✅ Écoute les changements sur profiles → otaku_rank/level/points
  // Déclenché par les triggers SQL on_like_points, on_follow_points, etc.

  void _listenToRankUpdates() {
    if (!Get.isRegistered<RealtimeService>()) return;
  
    RealtimeService.to.onRankUpdated = (rank, level, points) {
      if (!mounted || _profile == null) return;
  
      final oldRank = _profile!.otakuRank;
  
      setState(() {
        _profile = _profile!.copyWith(
          otakuRank:   rank,
          otakuLevel:  level,
          otakuPoints: points,
        );
      });
  
      // ✅ Snackbar uniquement si montée de rang
      if (rank != oldRank) {
        Helpers.showSuccessSnackbar('🏆 Nouveau rang : $rank !');
      }
    };
  }
  // ─── Follow / Unfollow ───────────────────────────────────────────

  Future<void> _toggleFollow() async {
    if (_profile == null) return;
    HapticFeedback.lightImpact();

    final targetId     = _profile!.userId;
    final nowFollowing = !_isFollowing;
    final delta        = nowFollowing ? 1 : -1;

    setState(() {
      _isFollowing = nowFollowing;
      _profile = _profile!.copyWith(
        followersCount:
            (_profile!.followersCount + delta).clamp(0, 999999999),
      );
    });

    try {
      if (nowFollowing) {
        await _supabase.from('follows').insert({
          'follower_id':  _myUid,
          'following_id': targetId,
        });
      } else {
        await _supabase.from('follows').delete()
            .eq('follower_id',  _myUid)
            .eq('following_id', targetId);
      }
    } catch (e) {
      setState(() {
        _isFollowing = !nowFollowing;
        _profile = _profile!.copyWith(
          followersCount:
              (_profile!.followersCount - delta).clamp(0, 999999999),
        );
      });
    }
  }

  // ─── Chat ────────────────────────────────────────────────────────

  Future<void> _openChat() async {
    if (_profile == null) return;
    setState(() => _isOpeningChat = true);
    try {
      final convId = await MessageService()
          .getOrCreateConversation(_profile!.userId);
      if (!mounted || convId == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conv: ConversationModel(
              id:               convId,
              type:             'direct',
              otherUserId:      _profile!.userId,
              otherUsername:    _profile!.username,
              otherDisplayName: _profile!.displayName,
              otherAvatarUrl:   _profile!.avatarUrl,
            ),
          ),
        ),
      );
    } catch (e) {
      Helpers.showErrorSnackbar('Impossible d\'ouvrir la conversation');
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  // ─── Navigation ──────────────────────────────────────────────────

  void _goToEditProfile() async {
    if (_profile == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => EditProfileScreen(profile: _profile!)),
    );
    if (updated == true) _loadProfile();
  }

  void _showSettings() {
    showSettingsSheet(
      context:          context,
      profile:          _profile!,
      onProfileUpdated: _loadProfile,
      onLogoutRequested: () async {
        await Supabase.instance.client.auth.signOut();
        Get.offAllNamed('/');
      },
    );
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          leading: const BackButton(color: AppColors.textPrimary),
        ),
        body: Center(
            child: Text('Profil introuvable', style: AppTextStyles.body)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverOverlapAbsorber(
            handle:
                NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverAppBar(
              expandedHeight:         240,
              floating:               false,
              pinned:                 true,
              forceElevated:          innerBoxIsScrolled,
              backgroundColor:        AppColors.bgPrimary,
              elevation:              0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title:        _buildCollapsedTitle(),
              titleSpacing: 0,
              actions: [
                if (_isMe)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.textPrimary),
                    onPressed: _showSettings,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.more_horiz,
                        color: AppColors.textPrimary),
                    onPressed: () {},
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: ProfileBanner(
                  profile:      _profile!,
                  isMe:         _isMe,
                  onEditAvatar: _goToEditProfile,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ProfileUserInfo(
              profile:        _profile!,
              isMe:           _isMe,
              isFollowing:    _isFollowing,
              isOpeningChat:  _isOpeningChat,
              onToggleFollow: _toggleFollow,
              onOpenChat:     _openChat,
              onEditProfile:  _goToEditProfile,
            ),
          ),
        ],
        body: Column(children: [
          Container(
            color: AppColors.bgPrimary,
            child: TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Avis'),
                Tab(text: 'Fan Art'),
                Tab(text: 'Clips'),
              ],
              labelStyle: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primary),
              unselectedLabelStyle: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.textMuted),
              indicatorColor: AppColors.primary,
              indicatorSize:  TabBarIndicatorSize.label,
              dividerColor:   Colors.transparent,
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                ProfilePostsTab(userId: _profile!.userId),
                const ProfileReviewsTab(),
                const ProfileFanArtTab(),
                const ProfileClipsTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Titre collapsé ──────────────────────────────────────────────

  Widget _buildCollapsedTitle() {
    if (_profile == null) return const SizedBox.shrink();
    final p         = _profile!;
    final rankColor = AppColors.rankColor(p.otakuRank);

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
        child: Text(p.displayNameOrUsername,
            style: AppTextStyles.h3,
            overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        rankColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: rankColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          '${p.otakuRank} · Lv.${p.otakuLevel}',
          style: AppTextStyles.statSmall.copyWith(color: rankColor),
        ),
      ),
    ]);
  }
}