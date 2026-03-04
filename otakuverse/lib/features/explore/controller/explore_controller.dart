import 'package:get/get.dart';
import 'package:otakuverse/features/explore/services/explore_service.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';

class ExploreController extends GetxController {
  final _service = ExploreService();

  // ─── State ───────────────────────────────────────────────────────
  final RxList<PostModel> posts         = <PostModel>[].obs;
  final RxBool            isLoading     = false.obs;
  final RxBool            isLoadingMore = false.obs;
  final RxBool            hasMore       = true.obs;
  final RxString          selectedGenre = ''.obs;
  final RxString          errorMessage  = ''.obs;

  // ─── Pagination ──────────────────────────────────────────────────
  int              _offset   = 0;
  static const int _pageSize = 20;

  // ─── Genres disponibles ──────────────────────────────────────────
  static const List<String> genres = [
    'Shonen',
    'Shojo',
    'Seinen',
    'Josei',
    'Isekai',
    'Mecha',
    'Slice of Life',
    'Fantasy',
    'Romance',
    'Horreur',
    'Sport',
    'Mystère',
  ];

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  // ─── CHARGER (première page) ─────────────────────────────────────
  Future<void> loadPosts() async {
    isLoading.value    = true;
    errorMessage.value = '';
    _offset            = 0;
    hasMore.value      = true;

    try {
      final result = await _service.getTrendingPosts(
        offset: 0,
        genre:  selectedGenre.value.isEmpty
            ? null
            : selectedGenre.value,
      );
      posts.assignAll(result);
      if (result.length < _pageSize) hasMore.value = false;
      _offset = result.length;
    } catch (e) {
      errorMessage.value = 'Impossible de charger les tendances';
      print('🔴 Erreur ExploreController : $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── CHARGER la page suivante ────────────────────────────────────
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final result = await _service.getTrendingPosts(
        offset: _offset,
        genre:  selectedGenre.value.isEmpty
            ? null
            : selectedGenre.value,
      );
      if (result.isEmpty || result.length < _pageSize) {
        hasMore.value = false;
      }
      posts.addAll(result);
      _offset += result.length;
    } catch (e) {
      print('🔴 Erreur loadMore explore : $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── SÉLECTIONNER un genre ───────────────────────────────────────
  void selectGenre(String genre) {
    // ✅ Toggle — cliquer deux fois déselectionne
    selectedGenre.value =
        selectedGenre.value == genre ? '' : genre;
    loadPosts();
  }

  // ─── TOGGLE LIKE ─────────────────────────────────────────────────
  void updateLike(String postId, {
    required bool  isLiked,
    required int   likesCount,
  }) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    posts[index] = posts[index].copyWith(
      isLiked:    isLiked,
      likesCount: likesCount,
    );
  }
}