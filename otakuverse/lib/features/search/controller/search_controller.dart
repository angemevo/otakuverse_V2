import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/search/services/search_service.dart';

class SearchUsersController extends GetxController {
  final _service = SearchService();

  final RxList<ProfileModel> results     = <ProfileModel>[].obs;
  final RxList<ProfileModel> suggestions = <ProfileModel>[].obs;
  final RxBool  isLoading                = false.obs;
  final RxBool  isSearching              = false.obs;
  final RxString query                   = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSuggestions();

    // ✅ Debounce — attendre 400ms après la dernière frappe
    debounce(
      query,
      (q) => _search(q),
      time: const Duration(milliseconds: 400),
    );
  }

  // ─── CHARGER SUGGESTIONS ─────────────────────────────────────────
  Future<void> loadSuggestions() async {
    try {
      final data = await _service.getSuggestions();
      suggestions.assignAll(data);
    } catch (e) {
      debugPrint('⚠️ Erreur suggestions : $e');
    }
  }

  // ─── RECHERCHE ───────────────────────────────────────────────────
  void onQueryChanged(String value) {
    query.value    = value;
    isSearching.value = value.trim().isNotEmpty;
  }

  Future<void> _search(String value) async {
    if (value.trim().isEmpty) {
      results.clear();
      return;
    }

    isLoading.value = true;
    try {
      final data = await _service.searchUsers(value);
      results.assignAll(data);
    } catch (e) {
      debugPrint('🔴 Erreur recherche : $e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    query.value       = '';
    isSearching.value = false;
    results.clear();
  }
}
