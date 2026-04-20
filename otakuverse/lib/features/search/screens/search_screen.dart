import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/core/widgets/connectivity_wrapper.dart';
import 'package:otakuverse/features/profile/controllers/follow_controller.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/screens/profile_screen.dart';
import 'package:otakuverse/features/search/controller/search_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      onRetry: _ctrl.loadSuggestions,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: _buildAppBar(),
        body: Obx(() {
          if (_ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (_ctrl.isSearching.value) {
            return _ctrl.results.isEmpty
                ? _buildEmpty()
                : _buildResults(_ctrl.results);
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
        key: AppKeys.searchField,
        controller: _textController,
        focusNode:  _focusNode,
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
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

  // ─── Résultats ───────────────────────────────────────────────────

  Widget _buildResults(List<ProfileModel> users) {
    return ListView.builder(
      padding:     const EdgeInsets.symmetric(vertical: 8),
      itemCount:   users.length,
      itemBuilder: (_, i) =>
          _UserTile(profile: users[i], followController: _followCtrl),
    );
  }

  // ─── Suggestions ─────────────────────────────────────────────────

  Widget _buildSuggestions() {
    if (_ctrl.suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Suggestions',
              style: GoogleFonts.poppins(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize:   16)),
        ),
        Expanded(
          child: ListView.builder(
            padding:     const EdgeInsets.symmetric(vertical: 4),
            itemCount:   _ctrl.suggestions.length,
            itemBuilder: (_, i) => _UserTile(
                profile: _ctrl.suggestions[i], followController: _followCtrl),
          ),
        ),
      ],
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(HeroiconsOutline.userGroup,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('Aucun résultat',
              style: GoogleFonts.poppins(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize:   16)),
          const SizedBox(height: 6),
          Obx(() => Text(
            'Aucun utilisateur trouvé pour "${_ctrl.query.value}"',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          )),
        ],
      ),
    );
  }
}

// ─── User Tile ────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final ProfileModel     profile;
  final FollowController followController;

  const _UserTile({
    required this.profile,
    required this.followController,
  });

  @override
  Widget build(BuildContext context) {
    followController.loadFollowState(profile.userId);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: profile.userId)),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          CachedAvatar(
            url:            profile.avatarUrl,
            radius:         24,
            fallbackLetter: profile.displayNameOrUsername,
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildUserInfo()),
          _buildFollowButton(),
        ]),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            profile.displayNameOrUsername,
            style: GoogleFonts.inter(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize:   14,
            ),
          ),
          if (profile.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: AppColors.primary, size: 14),
          ],
        ]),
        const SizedBox(height: 2),
        Text('@${profile.username}',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 12)),
        if (profile.followersCount > 0) ...[
          const SizedBox(height: 2),
          Text(
            // ✅ Helpers.formatNumber remplace _formatCount local
            '${Helpers.formatNumber(profile.followersCount)} abonnés',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildFollowButton() {
    return Obx(() {
      final isFollowing = followController.isFollowing(profile.userId);
      final isLoading   = followController.isLoading.value;

      return GestureDetector(
        onTap: isLoading
            ? null
            : () => followController.toggleFollow(profile.userId),
        child: AnimatedContainer(
          duration:  const Duration(milliseconds: 250),
          curve:     Curves.easeOutCubic,
          padding:   const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.transparent : AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFollowing
                  ? AppColors.textPrimary.withValues(alpha: 0.4)
                  : AppColors.primary,
              width: 1.5,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  isFollowing ? 'Abonné' : 'Suivre',
                  style: GoogleFonts.inter(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                  ),
                ),
        ),
      );
    });
  }
}
