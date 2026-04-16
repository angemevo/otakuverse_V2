import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/screens/edit_profile_screen.dart';
import 'package:otakuverse/features/profile/widgets/genre_tags.dart';
import 'package:otakuverse/features/profile/widgets/rank_badge.dart';
import 'package:otakuverse/features/profile/widgets/watchlist_preview.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/screens/comments/comments_sheet.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';
import 'package:otakuverse/features/message/models/conversation_model.dart';
import 'package:otakuverse/features/message/services/message_service.dart';
import 'package:otakuverse/features/message/screens/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool          _isLoading  = true;
  bool          _isMe       = false;
  bool          _isFollowing = false;
  bool          _isOpeningChat = false;

  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── CHARGEMENT ──────────────────────────────────────────────────
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

      debugPrint('🔍 loadProfile[$targetId] → $data');

      if (data == null) {
        debugPrint('⚠️ Aucun profil trouvé pour $targetId');
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

      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } catch (e, st) {
      debugPrint('❌ loadProfile error: $e\n$st');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── FOLLOW / UNFOLLOW ───────────────────────────────────────────
  Future<void> _toggleFollow() async {
    if (_profile == null) return;
    HapticFeedback.lightImpact();

    final targetId     = _profile!.userId;
    final nowFollowing = !_isFollowing;
    final delta        = nowFollowing ? 1 : -1;

    // ✅ Optimistic update — état + compteur
    setState(() {
      _isFollowing = nowFollowing;
      _profile = _profile!.copyWith(
        followersCount: (_profile!.followersCount + delta).clamp(0, 999999999),
      );
    });

    try {
      if (nowFollowing) {
        await _supabase.from('follows').insert({
          'follower_id':  _myUid,
          'following_id': targetId,
        });
      } else {
        await _supabase.from('follows')
            .delete()
            .eq('follower_id',  _myUid)
            .eq('following_id', targetId);
      }
    } catch (e) {
      // ✅ Rollback complet si erreur
      setState(() {
        _isFollowing = !nowFollowing;
        _profile = _profile!.copyWith(
          followersCount: (_profile!.followersCount - delta).clamp(0, 999999999),
        );
      });
    }
  }

  // ─── OUVRIR LE CHAT ──────────────────────────────────────────────
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          leading: const BackButton(
              color: AppColors.textPrimary),
        ),
        body: Center(
          child: Text(
            'Profil introuvable',
            style: AppTextStyles.body,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: NestedScrollView(
        // ─ Header : bannière + infos (scrollent et disparaissent) ──
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
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
              // ✅ Visible uniquement quand la toolbar est collapsée
              title: _buildCollapsedTitle(),
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
                // title à null dans flexibleSpace pour éviter le doublon
                collapseMode: CollapseMode.parallax,
                background:   _buildBanner(),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildUserInfo()),
        ],

        // ─ Body : TabBar collée en haut + contenu scrollable ────────
        body: Column(
          children: [
            // TabBar comme widget ordinaire → reste en haut du body
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

            // TabBarView prend tout l'espace restant
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _PostsTab(userId: _profile!.userId),
                  _ReviewsTab(userId: _profile!.userId),
                  _FanArtTab(),
                  _ClipsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOOLBAR COLLAPSÉE ───────────────────────────────────────────
  Widget _buildCollapsedTitle() {
    if (_profile == null) return const SizedBox.shrink();
    final p = _profile!;
    final rankColor = AppColors.rankColor(p.otakuRank);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            p.displayNameOrUsername,
            style: AppTextStyles.h3,
            overflow: TextOverflow.ellipsis,
          ),
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
      ],
    );
  }

  // ─── BANNIÈRE ────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ─ Image bannière ────────────────────────────────────────
        _profile!.hasBanner
            ? Image.network(
                _profile!.bannerUrl!,
                fit:   BoxFit.cover,
                color: Colors.black26,
                colorBlendMode: BlendMode.darken,
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                    colors: [
                      AppColors.primary
                          .withValues(alpha: 0.6),
                      AppColors.accent
                          .withValues(alpha: 0.4),
                      AppColors.bgPrimary,
                    ],
                  ),
                ),
              ),

        // ─ Gradient bas ──────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.bgPrimary,
                ],
              ),
            ),
          ),
        ),

        // ─ Avatar positionné en bas gauche ───────────────────────
        Positioned(
          bottom: 12, left: 16,
          child: _buildAvatar(),
        ),
      ],
    );
  }

  // ─── AVATAR ──────────────────────────────────────────────────────
  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.bgPrimary,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color:      AppColors.primary
                    .withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CachedAvatar(
            url:           _profile!.avatarUrl,
            radius:        38,
            fallbackLetter: _profile!
                .displayNameOrUsername,
          ),
        ),

        // ─ Bouton caméra si mon profil ───────────────────────────
        if (_isMe)
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: () => _goToEditProfile(),
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color:  AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.bgPrimary,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.white,
                  size:  13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── INFOS UTILISATEUR ───────────────────────────────────────────
  Widget _buildUserInfo() {
    final p = _profile!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Nom + Vérifié ─────────────────────────────────
          Row(
            children: [
              Text(p.displayNameOrUsername, style: AppTextStyles.h2),
              if (p.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded,
                    color: AppColors.primary, size: 18),
              ],
            ],
          ),
          Text('@${p.username}', style: AppTextStyles.bodySmall),
          const SizedBox(height: 14),

          // ─ Rang + Niveau + Progression ───────────────────────
          _buildRankSection(p),
          const SizedBox(height: 14),

          // ─ Bio ───────────────────────────────────────────────
          if (p.hasBio) ...[
            Text(p.bio!, style: AppTextStyles.body),
            const SizedBox(height: 10),
          ],

          // ─ Genres favoris ────────────────────────────────────
          if (p.favoriteGenres.isNotEmpty) ...[
            GenreTags(
              genres: p.favoriteGenres,
              wrap:   false,
            ),
            const SizedBox(height: 12),
          ],

          // ─ Stats ─────────────────────────────────────────────
          _buildStats(p),
          const SizedBox(height: 14),

          // ─ Boutons d'action ──────────────────────────────────
          _buildActions(),
          const SizedBox(height: 16),

          // ─ Watchlist preview ─────────────────────────────────
          WatchlistPreview(
            count:    p.watchlistCount,
            isMe:     _isMe,
            username: p.username,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── RANG + NIVEAU + PROGRESSION ────────────────────────────────
  Widget _buildRankSection(ProfileModel p) {
    final color = AppColors.rankColor(p.otakuRank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Rang + Niveau ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RankBadge(
                rank:  p.otakuRank,
                level: p.otakuLevel,
                large: true,
              ),
              if (_isMe)
                Text(
                  '${p.otakuPoints} pts',
                  style: AppTextStyles.statSmall
                      .copyWith(color: color),
                ),
            ],
          ),

          // ─ Barre + points (profil perso uniquement) ────────
          if (_isMe) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           p.levelProgress,
                minHeight:       5,
                backgroundColor: AppColors.bgElevated,
                valueColor:      AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${p.otakuPoints} pts actuels',
                  style: AppTextStyles.caption
                      .copyWith(color: color),
                ),
                Text(
                  '${p.pointsForNextLevel} pts → Lv.${p.otakuLevel + 1}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── STATS ───────────────────────────────────────────────────────
  Widget _buildStats(ProfileModel p) {
    return Row(
      children: [
        _StatItem(
          value: _fmt(p.postsCount),
          label: 'Posts',
        ),
        _Separator(),
        _StatItem(
          value: _fmt(p.followersCount),
          label: 'Abonnés',
          onTap: () {},
        ),
        _Separator(),
        _StatItem(
          value: _fmt(p.followingCount),
          label: 'Abonnements',
          onTap: () {},
        ),
        _Separator(),
        _StatItem(
          value: _fmt(p.reviewsCount),
          label: 'Avis',
        ),
      ],
    );
  }

  // ─── BOUTONS ACTION ──────────────────────────────────────────────
  Widget _buildActions() {
    if (_isMe) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              label:    'Modifier le profil',
              icon:     Icons.edit_outlined,
              outlined: true,
              onTap:    _goToEditProfile,
            ),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon:  Icons.share_outlined,
            onTap: () {},
          ),
        ],
      );
    }

    return Row(
      children: [
        // ─ Suivre / Ne plus suivre ──────────────────────────────
        Expanded(
          child: _ActionButton(
            label:    _isFollowing
                ? 'Abonné'
                : 'Suivre',
            icon:     _isFollowing
                ? Icons.person_remove_outlined
                : Icons.person_add_outlined,
            primary:  !_isFollowing,
            outlined: _isFollowing,
            onTap:    _toggleFollow,
          ),
        ),
        const SizedBox(width: 10),

        // ─ Message ─────────────────────────────────────────────
        Expanded(
          child: _ActionButton(
            label:    'Message',
            icon:     Icons.mail_outline_rounded,
            outlined: true,
            loading:  _isOpeningChat,
            onTap:    _openChat,
          ),
        ),
        const SizedBox(width: 10),

        _ActionButton(
          icon:  Icons.more_horiz,
          onTap: () {},
        ),
      ],
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _goToEditProfile() async {
    if (_profile == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditProfileScreen(profile: _profile!),
      ),
    );
    if (updated == true) _loadProfile();
  }

  void _showSettings() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppColors.bgSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _SettingsItem(
              icon:  Icons.edit_outlined,
              label: 'Modifier le profil',
              onTap: () {
                Navigator.pop(context);
                _goToEditProfile();
              },
            ),
            _SettingsItem(
              icon:  Icons.lock_outline_rounded,
              label: 'Confidentialité',
              onTap: () => Navigator.pop(context),
            ),
            _SettingsItem(
              icon:  Icons.logout_rounded,
              label: 'Déconnexion',
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client
                    .auth.signOut();
                Get.offAllNamed('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS HELPERS ─────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String   value;
  final String   label;
  final VoidCallback? onTap;

  const _StatItem({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(value, style: AppTextStyles.stat),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      );
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width:  1, height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color:  AppColors.border,
  );
}

class _ActionButton extends StatelessWidget {
  final String?   label;
  final IconData  icon;
  final bool      primary;
  final bool      outlined;
  final bool      loading;
  final VoidCallback onTap;

  const _ActionButton({
    this.label,
    required this.icon,
    required this.onTap,
    this.primary  = false,
    this.outlined = false,
    this.loading  = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIconOnly = label == null;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height:   40,
        width:    isIconOnly ? 40 : null,
        padding:  isIconOnly
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(
                horizontal: 14),
        decoration: BoxDecoration(
          color: primary
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: outlined
                ? AppColors.border
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    color:       AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: primary
                        ? AppColors.white
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                  if (label != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      label!,
                      style: AppTextStyles.buttonSmall
                          .copyWith(
                        color: primary
                            ? AppColors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color?   color;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      icon,
      color: color ?? AppColors.textSecondary,
      size:  22,
    ),
    title: Text(
      label,
      style: AppTextStyles.body.copyWith(
          color: color ?? AppColors.textPrimary),
    ),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 20),
  );
}


// ─── ONGLET POSTS ────────────────────────────────────────────────────

class _PostsTab extends StatefulWidget {
  final String userId;
  const _PostsTab({required this.userId});

  @override
  State<_PostsTab> createState() => __PostsTabState();
}

class __PostsTabState extends State<_PostsTab>
    with AutomaticKeepAliveClientMixin {

  final _supabase = Supabase.instance.client;
  List<PostModel> _posts   = [];
  bool            _loading = true;
  String?         _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _supabase
          .from('posts')
          .select('*, profiles(username, display_name, avatar_url)')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _posts   = (data as List).map((j) => PostModel.fromJson(j)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ _PostsTab: $e');
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final myUid = _supabase.auth.currentUser?.id;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text('Erreur de chargement', style: AppTextStyles.body),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadPosts,
              child: Text('Réessayer',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_off_outlined,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text("Aucun post pour l'instant",
                style: AppTextStyles.body),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color:           AppColors.primary,
      backgroundColor: AppColors.bgPrimary,
      onRefresh:       _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: _posts.length,
        itemBuilder: (context, i) {
          final post = _posts[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PostCard(
              post:      post,
              isLiked:   post.isLiked,
              isMe:      post.userId == myUid,
              onLike:    () {},
              onComment: () => showCommentsSheet(
                context,
                postId:     post.id,
                postAuthor: post.displayNameOrUsername,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── ONGLETS PLACEHOLDER ─────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  final String userId;
  const _ReviewsTab({required this.userId});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.rate_review_outlined,
            color: AppColors.textMuted, size: 48),
        SizedBox(height: 12),
        Text('Avis à venir',
            style: TextStyle(color: AppColors.textMuted)),
      ],
    ),
  );
}

class _FanArtTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.brush_outlined,
            color: AppColors.textMuted, size: 48),
        SizedBox(height: 12),
        Text('Fan Art à venir',
            style: TextStyle(color: AppColors.textMuted)),
      ],
    ),
  );
}

class _ClipsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.videocam_outlined,
            color: AppColors.textMuted, size: 48),
        SizedBox(height: 12),
        Text('Clips à venir',
            style: TextStyle(color: AppColors.textMuted)),
      ],
    ),
  );
}