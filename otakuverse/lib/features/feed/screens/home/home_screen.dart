import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/services/realtime_service.dart';
import 'package:otakuverse/core/widgets/connectivity_wrapper.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/screens/comments/comments_sheet.dart';
import 'package:otakuverse/features/feed/screens/home/widgets/feed_widgets.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';
import 'package:otakuverse/features/stories/widgets/stories_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final PostsController _ctrl;
  bool _hasNewContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = Get.find<PostsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ctrl.posts.isEmpty) _ctrl.loadFeed();
      _initRealtime();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _ctrl.refreshFeed();
  }

  Future<void> _initRealtime() async {
    try {
      if (!Get.isRegistered<RealtimeService>()) return;
      final realtime = RealtimeService.to;
      await realtime.initialize();
      realtime.onNewPost = () {
        if (mounted) setState(() => _hasNewContent = true);
      };
    } catch (e) {
      debugPrint('⚠️ Realtime: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      onRetry: _ctrl.loadFeed,
      child: Obx(() {
        if (_ctrl.isLoading.value && _ctrl.posts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (_ctrl.errorMessage.value.isNotEmpty && _ctrl.posts.isEmpty) {
          return _buildError();
        }
        return Stack(children: [
          _buildFeed(),
          if (_hasNewContent)
            NewContentBadge(
              onTap: () async {
                setState(() => _hasNewContent = false);
                await _ctrl.loadFeed();
              },
            ),
        ]);
      }),
    );
  }

  // ─── Feed ────────────────────────────────────────────────────────

  Widget _buildFeed() {
    return RefreshIndicator(
      color:           AppColors.primary,
      backgroundColor: AppColors.bgPrimary,
      onRefresh: () async {
        setState(() => _hasNewContent = false);
        await _ctrl.loadFeed();
      },
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: StoriesRow()),
          const SliverToBoxAdapter(
            child: Divider(color: Color(0xFF1F1F1F), height: 1),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          if (_ctrl.posts.isEmpty)
            const SliverFillRemaining(child: EmptyFeed())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return Obx(() => _ctrl.isDiscoveryFeed.value
                        ? const DiscoveryBanner()
                        : const SizedBox.shrink());
                  }
                  final post = _ctrl.posts[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: PostCard(
                      post:      post,
                      isLiked:   post.isLiked,
                      isMe:      false,
                      onLike:    () => _ctrl.toggleLike(post.id),
                      onComment: () => showCommentsSheet(
                        context,
                        postId:     post.id,
                        postAuthor: post.displayNameOrUsername,
                      ),
                    ),
                  );
                },
                childCount: _ctrl.posts.length + 1,
              ),
            ),

          SliverToBoxAdapter(
            child: Obx(() => _ctrl.isLoadingMore.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  )
                : const SizedBox(height: 80)),
          ),
        ],
      ),
    );
  }

  // ─── Erreur ──────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline,
            color: AppColors.textMuted, size: 48),
        const SizedBox(height: 12),
        Text(
          _ctrl.errorMessage.value,
          style: const TextStyle(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _ctrl.loadFeed,
          child: Text('Réessayer',
              style: GoogleFonts.inter(color: AppColors.primary)),
        ),
      ]),
    );
  }
}
