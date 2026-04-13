import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/widgets/connectivity_wrapper.dart';
import 'package:otakuverse/core/services/realtime_service.dart';
import 'package:otakuverse/features/notification/controller/notification_controller.dart';
import 'package:otakuverse/features/notification/screens/notification_screen.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/screens/comments_sheet.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';
import 'package:otakuverse/features/message/screens/messages_screen.dart';
import 'package:otakuverse/features/search/screens/search_screen.dart';
import 'package:otakuverse/features/stories/widgets/stories_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  late final PostsController _controller;

  // ✅ Indicateur de nouveau contenu disponible
  bool _hasNewContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = Get.find<PostsController>();

    // ✅ Charger le feed au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.posts.isEmpty) {
        _controller.loadFeed();
      }
      // ✅ Démarrer le Realtime
      _initRealtime();
    });

    // ✅ Écouter les nouveaux posts via Realtime
    _controller.posts.listen((_) {
      // Si on reçoit un nouveau post via Realtime
      // et que l'utilisateur a scrollé → afficher le badge
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─── REPRENDRE L'APP → refresh silencieux ────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ✅ Refresh silencieux quand l'app revient au premier plan
      _controller.refreshFeed();
    }
  }

  // ─── INITIALISER REALTIME ─────────────────────────────────────────
  Future<void> _initRealtime() async {
    try {
      if (Get.isRegistered<RealtimeService>()) {
        final realtime = RealtimeService.to;
        await realtime.initialize();

        // ✅ Quand un nouveau post arrive → afficher le badge
        realtime.onNewPost = () {
          if (mounted) {
            setState(() => _hasNewContent = true);
          }
        };

        debugPrint('✅ HomeScreen: Realtime initialisé');
      }
    } catch (e) {
      debugPrint('⚠️ HomeScreen Realtime: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      onRetry: _controller.loadFeed,
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: AppColors.deepBlack,
          elevation:       0,
          title: Text('Otakuverse',
              style: AppTextStyles.appBarTitle),
          actions: [
            const _NotificationBell(),
            IconButton(
              icon: const Icon(
                HeroiconsOutline.chatBubbleLeftRight,
                color: AppColors.pureWhite,
                size:  24,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const MessagesScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(
                HeroiconsOutline.magnifyingGlass,
                color: AppColors.pureWhite,
                size:  24,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SearchScreen()),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Obx(() {
          // ─ Chargement initial ──────────────────────────────────
          if (_controller.isLoading.value &&
              _controller.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.crimsonRed),
            );
          }

          // ─ Erreur ─────────────────────────────────────────────
          if (_controller.errorMessage.value.isNotEmpty &&
              _controller.posts.isEmpty) {
            return _buildError();
          }

          return Stack(
            children: [
              // ─ Feed principal ────────────────────────────────
              RefreshIndicator(
                color:           AppColors.crimsonRed,
                backgroundColor: AppColors.deepBlack,
                onRefresh: () async {
                  setState(() => _hasNewContent = false);
                  await _controller.loadFeed();
                },
                child: CustomScrollView(
                  slivers: [
                    // Story
                    const SliverToBoxAdapter(
                      child: StoriesRow(),
                    ),
                    // Divider
                    const SliverToBoxAdapter(
                      child: Divider(
                        color: Color(0xFF1F1F1F),
                        height: 1,
                      ),
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 8)),

                    if (_controller.posts.isEmpty)
                      const SliverFillRemaining(
                          child: _EmptyFeed())
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // ─ Bandeau découverte ────────────
                            if (index == 0) {
                              return Obx(() {
                                if (!_controller
                                    .isDiscoveryFeed.value) {
                                  return const SizedBox.shrink();
                                }
                                return _DiscoveryBanner();
                              });
                            }

                            // ─ Posts ─────────────────────────
                            final post = _controller
                                .posts[index - 1];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical:   4,
                              ),
                              child: PostCard(
                                post:      post,
                                isLiked:   post.isLiked,
                                isMe:      false,
                                onLike: () => _controller
                                    .toggleLike(post.id),
                                onComment: () =>
                                    showCommentsSheet(
                                  context,
                                  postId:     post.id,
                                  postAuthor: post
                                      .displayNameOrUsername,
                                ),
                              ),
                            );
                          },
                          childCount:
                              _controller.posts.length + 1,
                        ),
                      ),

                    // ─ Loader pagination ─────────────────────
                    SliverToBoxAdapter(
                      child: Obx(() {
                        if (!_controller.isLoadingMore.value) {
                          return const SizedBox(height: 80);
                        }
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color:       AppColors.crimsonRed,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // ─ Badge "Nouveaux posts" (Realtime) ─────────────
              if (_hasNewContent)
                Positioned(
                  top: 8, left: 0, right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        setState(
                            () => _hasNewContent = false);
                        await _controller.loadFeed();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 300),
                        curve: Curves.easeOutBack,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.crimsonRed,
                          borderRadius:
                              BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.crimsonRed
                                  .withValues(alpha: 0.4),
                              blurRadius:   12,
                              offset:
                                  const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size:  16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nouveaux posts',
                              style: GoogleFonts.inter(
                                color:      Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize:   13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ─── ERREUR ────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.mediumGray, size: 48),
          const SizedBox(height: 12),
          Text(
            _controller.errorMessage.value,
            style: const TextStyle(
                color: AppColors.mediumGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _controller.loadFeed,
            child: const Text('Réessayer',
                style: TextStyle(
                    color: AppColors.crimsonRed)),
          ),
        ],
      ),
    );
  }
}

// ─── BADGE CLOCHE ────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    final notifCtrl =
        Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : null;

    final icon = IconButton(
      icon: const Icon(
        HeroiconsOutline.bell,
        color: AppColors.pureWhite,
        size:  24,
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const NotificationScreen()),
      ),
    );

    if (notifCtrl == null) return icon;

    return Obx(() {
      final count = notifCtrl.unreadCount.value;
      if (count == 0) return icon;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            top: 6, right: 6,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(
                    minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 4),
                decoration: BoxDecoration(
                  color:        AppColors.crimsonRed,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.deepBlack,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: GoogleFonts.inter(
                    color:      Colors.white,
                    fontSize:   9,
                    fontWeight: FontWeight.w700,
                    height:     1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─── BANDEAU DÉCOUVERTE ──────────────────────────────────────────────
class _DiscoveryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.crimsonRed
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(children: [
        const Icon(Icons.explore_outlined,
            color: AppColors.crimsonRed, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feed de découverte',
                style: GoogleFonts.poppins(
                  color:      AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                ),
              ),
              Text(
                'Suis des utilisateurs pour personnaliser ton feed',
                style: GoogleFonts.inter(
                  color:    AppColors.mediumGray,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── EMPTY FEED ──────────────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dynamic_feed_outlined,
              color: AppColors.mediumGray, size: 48),
          const SizedBox(height: 12),
          Text(
            'Aucun post pour le moment',
            style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w600,
                fontSize:   16),
          ),
          const SizedBox(height: 8),
          Text(
            'Sois le premier à publier quelque chose !',
            style: GoogleFonts.inter(
                color:    AppColors.mediumGray,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}