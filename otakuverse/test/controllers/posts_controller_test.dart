import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/services/post_service.dart';
import '../helpers/fixtures.dart';

// ─── Fake PostService (no Supabase needed) ────────────────────────────────────

class _FakePostService extends PostService {
  // PostService() constructor accesses Supabase.instance — override to skip it.
  // All methods that PostsController calls are overridden to avoid network calls.

  @override
  Future<List<PostModel>> getFeed({int offset = 0}) async => [];

  @override
  Future<List<String>> getFollowingIds(String userId) async => [];

  @override
  Future<bool> toggleLike(String postId) async => true;

  @override
  Future<PostModel> createPost({
    required String caption,
    required List<String> mediaUrls,
    String? location,
    bool allowComments = true,
    String? musicTitle,
    String? musicArtist,
    String? musicTrackId,
    String? musicPreviewUrl,
    String? musicImageUrl,
  }) async =>
      PostModel.fromJson(postJson());
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

PostModel _post({
  String id            = 'post-001',
  int    likesCount    = 10,
  bool   isLiked       = false,
  int    commentsCount = 0,
}) =>
    PostModel.fromJson(postJson(
      id:            id,
      likesCount:    likesCount,
      commentsCount: commentsCount,
    )).copyWith(isLiked: isLiked);

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  late PostsController ctrl;

  setUp(() {
    Get.testMode = true;
    ctrl = PostsController(_FakePostService());
  });

  tearDown(Get.reset);

  // ─── Initial state ────────────────────────────────────────────────

  group('initial state', () {
    test('posts is empty', () {
      expect(ctrl.posts, isEmpty);
    });

    test('isLoading is false', () {
      expect(ctrl.isLoading.value, isFalse);
    });

    test('isLoadingMore is false', () {
      expect(ctrl.isLoadingMore.value, isFalse);
    });

    test('hasMore is true', () {
      expect(ctrl.hasMore.value, isTrue);
    });

    test('isDiscoveryFeed is false', () {
      expect(ctrl.isDiscoveryFeed.value, isFalse);
    });

    test('errorMessage is empty', () {
      expect(ctrl.errorMessage.value, '');
    });
  });

  // ─── toggleLike — optimistic update logic ─────────────────────────

  group('toggleLike — optimistic update (copyWith logic)', () {
    setUp(() {
      ctrl.posts.assignAll([
        _post(id: 'post-001', likesCount: 10, isLiked: false),
        _post(id: 'post-002', likesCount: 5,  isLiked: true),
      ]);
    });

    test('like: isLiked becomes true, likesCount +1', () {
      final post    = ctrl.posts.firstWhere((p) => p.id == 'post-001');
      final updated = post.copyWith(isLiked: true, likesCount: post.likesCount + 1);

      expect(updated.isLiked,    isTrue);
      expect(updated.likesCount, 11);
    });

    test('unlike: isLiked becomes false, likesCount -1', () {
      final post    = ctrl.posts.firstWhere((p) => p.id == 'post-002');
      final updated = post.copyWith(
        isLiked:    false,
        likesCount: (post.likesCount - 1).clamp(0, 999999),
      );

      expect(updated.isLiked,    isFalse);
      expect(updated.likesCount, 4);
    });

    test('clamp prevents likesCount going negative', () {
      final post    = _post(id: 'p', likesCount: 0, isLiked: true);
      final updated = post.copyWith(
        isLiked:    false,
        likesCount: (post.likesCount - 1).clamp(0, 999999),
      );

      expect(updated.likesCount, 0);
    });
  });

  // ─── updatePostLikeCount ─────────────────────────────────────────

  group('updatePostLikeCount', () {
    setUp(() {
      ctrl.posts.assignAll([_post(id: 'post-001', likesCount: 10)]);
    });

    test('positive delta increases likesCount', () {
      ctrl.updatePostLikeCount(postId: 'post-001', delta: 3);
      expect(ctrl.posts.first.likesCount, 13);
    });

    test('negative delta decreases likesCount', () {
      ctrl.updatePostLikeCount(postId: 'post-001', delta: -4);
      expect(ctrl.posts.first.likesCount, 6);
    });

    test('clamps at 0 — no negative value', () {
      ctrl.updatePostLikeCount(postId: 'post-001', delta: -999);
      expect(ctrl.posts.first.likesCount, 0);
    });

    test('unknown postId does not crash', () {
      expect(
        () => ctrl.updatePostLikeCount(postId: 'ghost', delta: 1),
        returnsNormally,
      );
    });
  });

  // ─── updatePostCommentCount ──────────────────────────────────────

  group('updatePostCommentCount', () {
    setUp(() {
      ctrl.posts.assignAll([_post(id: 'post-001', commentsCount: 5)]);
    });

    test('positive delta increases commentsCount', () {
      ctrl.updatePostCommentCount(postId: 'post-001', delta: 2);
      expect(ctrl.posts.first.commentsCount, 7);
    });

    test('negative delta decreases commentsCount', () {
      ctrl.updatePostCommentCount(postId: 'post-001', delta: -2);
      expect(ctrl.posts.first.commentsCount, 3);
    });

    test('clamps at 0', () {
      ctrl.updatePostCommentCount(postId: 'post-001', delta: -999);
      expect(ctrl.posts.first.commentsCount, 0);
    });
  });

  // ─── incrementCommentsCount / decrementCommentsCount ─────────────

  group('incrementCommentsCount / decrementCommentsCount', () {
    setUp(() {
      ctrl.posts.assignAll([_post(id: 'post-001', commentsCount: 3)]);
    });

    test('increment +1', () {
      ctrl.incrementCommentsCount('post-001');
      expect(ctrl.posts.first.commentsCount, 4);
    });

    test('decrement -1', () {
      ctrl.decrementCommentsCount('post-001');
      expect(ctrl.posts.first.commentsCount, 2);
    });

    test('decrement clamps at 0', () {
      ctrl.posts.assignAll([_post(id: 'post-001', commentsCount: 0)]);
      ctrl.decrementCommentsCount('post-001');
      expect(ctrl.posts.first.commentsCount, 0);
    });

    test('unknown postId does not crash', () {
      expect(() => ctrl.incrementCommentsCount('ghost'), returnsNormally);
      expect(() => ctrl.decrementCommentsCount('ghost'), returnsNormally);
    });
  });

  // ─── refreshBookmarks ─────────────────────────────────────────────

  group('refreshBookmarks', () {
    test('increments bookmarksRefreshTrigger on each call', () {
      final before = ctrl.bookmarksRefreshTrigger.value;
      ctrl.refreshBookmarks();
      expect(ctrl.bookmarksRefreshTrigger.value, before + 1);
    });

    test('multiple calls → successive increments', () {
      ctrl.refreshBookmarks();
      ctrl.refreshBookmarks();
      ctrl.refreshBookmarks();
      expect(ctrl.bookmarksRefreshTrigger.value, 3);
    });
  });

  // ─── loadFeed error handling ─────────────────────────────────────
  // loadFeed calls Supabase.instance directly (line 36 of post_controller.dart)
  // so it always fails in unit tests. We verify the error is handled gracefully.

  group('loadFeed — error handling (no Supabase in unit tests)', () {
    test('sets isLoading to false even when an error occurs', () async {
      await ctrl.loadFeed();
      expect(ctrl.isLoading.value, isFalse);
    });

    test('sets errorMessage when Supabase is unavailable', () async {
      await ctrl.loadFeed();
      expect(ctrl.errorMessage.value, 'Impossible de charger le feed');
    });

    test('does not throw — error is caught internally', () async {
      expect(() => ctrl.loadFeed(), returnsNormally);
    });
  });
}
