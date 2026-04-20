import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/screens/comments/comments_sheet.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePostsTab extends StatefulWidget {
  final String userId;
  const ProfilePostsTab({super.key, required this.userId});

  @override
  State<ProfilePostsTab> createState() => _ProfilePostsTabState();
}

class _ProfilePostsTabState extends State<ProfilePostsTab>
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

      if (mounted) setState(() {
        _posts   = (data as List).map((j) => PostModel.fromJson(j)).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ ProfilePostsTab: $e');
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final myUid = _supabase.auth.currentUser?.id;

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 12),
          Text('Erreur de chargement', style: AppTextStyles.body),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadPosts,
            child: Text('Réessayer',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.primary)),
          ),
        ]),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.grid_off_outlined,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text("Aucun post pour l'instant", style: AppTextStyles.body),
        ]),
      );
    }

    return RefreshIndicator(
      color:           AppColors.primary,
      backgroundColor: AppColors.bgPrimary,
      onRefresh:       _loadPosts,
      child: ListView.builder(
        padding:     const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount:   _posts.length,
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
