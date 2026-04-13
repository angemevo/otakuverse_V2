import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/connectivity_wrapper.dart';
import 'package:otakuverse/features/profile/controllers/follow_controller.dart';
import 'package:otakuverse/features/search/controller/search_controller.dart';
import 'package:otakuverse/features/search/widgets/search_empty_state.dart';
import 'package:otakuverse/features/search/widgets/search_user_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl           = Get.put(SearchUsersController());
  final _followCtrl     = Get.find<FollowController>();
  final _textController = TextEditingController();
  final _focusNode      = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      onRetry: _ctrl.loadSuggestions,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar:          _buildAppBar(),
        body: Obx(() {
          if (_ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (_ctrl.isSearching.value) {
            return _ctrl.results.isEmpty
                ? SearchEmptyState(query: _ctrl.query.value)
                : _buildList(_ctrl.results);
          }
          return _buildSuggestions();
        }),
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor:           AppColors.bgPrimary,
      elevation:                 0,
      automaticallyImplyLeading: false,
      titleSpacing:              0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(HeroiconsOutline.arrowLeft,
                color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchField()),
        ]),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06), width: 0.5),
      ),
      child: TextField(
        controller: _textController,
        focusNode:  _focusNode,
        style: GoogleFonts.inter(
            color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher un utilisateur...',
          hintStyle: GoogleFonts.inter(
              color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(HeroiconsOutline.magnifyingGlass,
              color: AppColors.textMuted, size: 18),
          suffixIcon: Obx(() => _ctrl.isSearching.value
              ? GestureDetector(
                  onTap: () {
                    _textController.clear();
                    _ctrl.clearSearch();
                  },
                  child: const Icon(HeroiconsOutline.xMark,
                      color: AppColors.textMuted, size: 16),
                )
              : const SizedBox.shrink()),
          border:         InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: _ctrl.onQueryChanged,
      ),
    );
  }

  // ─── Listes ──────────────────────────────────────────────────────

  Widget _buildList(users) {
    return ListView.builder(
      padding:     const EdgeInsets.symmetric(vertical: 8),
      itemCount:   users.length,
      itemBuilder: (_, i) => SearchUserTile(
          profile: users[i], followController: _followCtrl),
    );
  }

  Widget _buildSuggestions() {
    if (_ctrl.suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchSuggestionsHeader(),
        Expanded(
          child: ListView.builder(
            padding:     const EdgeInsets.symmetric(vertical: 4),
            itemCount:   _ctrl.suggestions.length,
            itemBuilder: (_, i) => SearchUserTile(
                profile: _ctrl.suggestions[i], followController: _followCtrl),
          ),
        ),
      ],
    );
  }
}