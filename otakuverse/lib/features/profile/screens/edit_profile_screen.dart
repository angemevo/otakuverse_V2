import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {

  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;

  final _profileService = ProfileService();
  bool _isSaving        = false;

  // ─── Médias ──────────────────────────────────────────────────────
  XFile?     _avatarFile;
  Uint8List? _avatarPreview;
  XFile?     _bannerFile;
  Uint8List? _bannerPreview;

  // ─── Focus ───────────────────────────────────────────────────────
  final _displayNameFocus = FocusNode();
  final _usernameFocus    = FocusNode();
  final _bioFocus         = FocusNode();

  // ─── Animation entrée ────────────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();

    _displayNameCtrl = TextEditingController(
        text: widget.profile.displayName ?? '');
    _usernameCtrl    = TextEditingController(
        text: widget.profile.username);
    _bioCtrl         = TextEditingController(
        text: widget.profile.bio ?? '');

    _enterCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(
        parent: _enterCtrl, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
        parent: _enterCtrl, curve: Curves.easeOutCubic));

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _displayNameFocus.dispose();
    _usernameFocus.dispose();
    _bioFocus.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  // ─── PICKERS ─────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    HapticFeedback.lightImpact();
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _avatarFile    = file;
      _avatarPreview = bytes;
    });
  }

  Future<void> _pickBanner() async {
    HapticFeedback.lightImpact();
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _bannerFile    = file;
      _bannerPreview = bytes;
    });
  }

  // ─── SAUVEGARDER ─────────────────────────────────────────────────
  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final username    = _usernameCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();
    final bio         = _bioCtrl.text.trim();

    if (username.isEmpty) {
      _showError('Le nom d\'utilisateur est obligatoire');
      return;
    }

    if (username.contains(' ')) {
      _showError(
          'Le nom d\'utilisateur ne peut pas contenir d\'espaces');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    String? newAvatarUrl;
    String? newBannerUrl;

    // ✅ Upload avatar — indépendant du reste
    if (_avatarFile != null) {
      try {
        final bytes = await _avatarFile!.readAsBytes();
        final ext   = _avatarFile!.path
            .split('.').last.toLowerCase();
        newAvatarUrl =
            await _profileService.uploadAvatar(bytes, ext);
      } catch (e) {
        debugPrint('⚠️ Avatar upload failed: $e');
        // ✅ Ne pas bloquer la sauvegarde si l'upload échoue
      }
    }

    // ✅ Upload bannière — indépendant du reste
    if (_bannerFile != null) {
      try {
        final bytes = await _bannerFile!.readAsBytes();
        final ext   = _bannerFile!.path
            .split('.').last.toLowerCase();
        newBannerUrl =
            await _profileService.uploadBanner(bytes, ext);
      } catch (e) {
        debugPrint('⚠️ Banner upload failed: $e');
      }
    }

    // ✅ Toujours sauvegarder le texte
    try {
      await _profileService.updateProfile(
        displayName: displayName.isEmpty ? null : displayName,
        username:    username,
        bio:         bio.isEmpty ? null : bio,
        avatarUrl:   newAvatarUrl,
        bannerUrl:   newBannerUrl,
      );

      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.pop(context, true);
    } catch (e, s) {
      if (!mounted) return;
      debugPrint('❌ updateProfile error: $e');
      debugPrint('❌ StackTrace: $s');
      _showError('Impossible de sauvegarder : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  void _showError(String msg) {
    Get.snackbar(
      'Erreur',
      msg,
      backgroundColor: AppColors.errorRed,
      colorText:       AppColors.pureWhite,
      snackPosition:   SnackPosition.BOTTOM,
      margin:          const EdgeInsets.all(16),
      borderRadius:    12,
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              // ─ App bar + médias ────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              // ─ Champs ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    20, 24, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionLabel('IDENTITÉ'),
                    const SizedBox(height: 12),
                    _buildField(
                      label:      'Nom affiché',
                      controller: _displayNameCtrl,
                      focusNode:  _displayNameFocus,
                      hint:       'Ton nom public',
                      icon:       Icons.badge_outlined,
                      nextFocus:  _usernameFocus,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label:      'Nom d\'utilisateur',
                      controller: _usernameCtrl,
                      focusNode:  _usernameFocus,
                      hint:       'username',
                      icon:       Icons.alternate_email,
                      // prefix:     '@',
                      nextFocus:  _bioFocus,
                      formatter: [
                        // ✅ Pas d'espaces dans le username
                        FilteringTextInputFormatter
                            .deny(RegExp(r'\s')),
                        LengthLimitingTextInputFormatter(
                            30),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionLabel('BIO'),
                    const SizedBox(height: 12),
                    _buildBioField(),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),

      // ─ Bouton sauvegarder ────────────────────────────────────────
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  // ─── HEADER : BANNER + AVATAR + NAVIGATION ───────────────────────
  Widget _buildHeader() {
    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ─ Bannière ──────────────────────────────────────────
          GestureDetector(
            onTap: _pickBanner,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                key: ValueKey(_bannerPreview),
                width:  double.infinity,
                height: 200,
                child: _bannerPreview != null
                    ? Image.memory(
                        _bannerPreview!,
                        fit: BoxFit.cover,
                        width:  double.infinity,
                      )
                    : widget.profile.hasBanner
                        ? Image.network(
                            widget.profile.bannerUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient:
                                  AppColors.primaryGradient,
                            ),
                          ),
              ),
            ),
          ),

          // ─ Gradient bas de bannière ───────────────────────────
          Positioned(
            bottom: 80, left: 0, right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.deepBlack,
                  ],
                ),
              ),
            ),
          ),

          // ─ Bouton edit bannière ───────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    // ─ Retour ──────────────────────────────────
                    _NavButton(
                      icon:  Icons.arrow_back_ios_new,
                      onTap: () =>
                          Navigator.pop(context, false),
                    ),

                    // ─ Modifier bannière ───────────────────────
                    _NavButton(
                      icon:  Icons.photo_outlined,
                      label: 'Bannière',
                      onTap: _pickBanner,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─ Avatar ────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 20,
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  // ─ Cercle fond ───────────────────────────────
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.deepBlack,
                        width: 4,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(
                          milliseconds: 300),
                      child: CircleAvatar(
                        key: ValueKey(
                            _avatarPreview?.length),
                        radius:          41,
                        backgroundColor: AppColors.darkGray,
                        backgroundImage: _avatarPreview !=
                                null
                            ? MemoryImage(_avatarPreview!)
                            : widget.profile.avatarUrl !=
                                    null
                                ? NetworkImage(widget
                                        .profile.avatarUrl!)
                                    as ImageProvider
                                : null,
                        child: _avatarPreview == null &&
                                widget.profile.avatarUrl ==
                                    null
                            ? Text(
                                widget.profile
                                    .displayNameOrUsername[0]
                                    .toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color:      Colors.white,
                                  fontSize:   28,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),

                  // ─ Bouton caméra ─────────────────────────────
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color:  AppColors.crimsonRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.deepBlack,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size:  13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─ Hint modifier avatar ───────────────────────────────
          Positioned(
            bottom: 6, left: 120,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.profile.displayNameOrUsername,
                  style: GoogleFonts.poppins(
                    color:      AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                    fontSize:   16,
                  ),
                ),
                Text(
                  '@${widget.profile.username}',
                  style: GoogleFonts.inter(
                    color:    AppColors.mediumGray,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── LABEL SECTION ───────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color:      AppColors.crimsonRed,
            fontSize:   11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.crimsonRed
                .withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  // ─── CHAMP TEXTE ─────────────────────────────────────────────────
  Widget _buildField({
    required String                 label,
    required TextEditingController  controller,
    required FocusNode              focusNode,
    required String                 hint,
    required IconData               icon,
    String?                         prefix,
    FocusNode?                      nextFocus,
    List<TextInputFormatter>?       formatter,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (_, child) {
        final focused = focusNode.hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Label ─────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: GoogleFonts.inter(
                color: focused
                    ? AppColors.crimsonRed
                    : AppColors.mediumGray,
                fontSize:   11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              child: Text(label.toUpperCase()),
            ),
            const SizedBox(height: 6),

            // ─ Champ ─────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:        AppColors.darkGray,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: focused
                      ? AppColors.crimsonRed
                          .withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // ─ Icône ───────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 14),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(
                          milliseconds: 150),
                      style: TextStyle(
                          color: focused
                              ? AppColors.crimsonRed
                              : AppColors.mediumGray),
                      child: Icon(icon,
                          size:  18,
                          color: focused
                              ? AppColors.crimsonRed
                              : AppColors.mediumGray),
                    ),
                  ),

                  // ─ Prefix ──────────────────────────────────
                  if (prefix != null)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8),
                      child: Text(prefix,
                          style: GoogleFonts.inter(
                            color: AppColors.mediumGray,
                            fontSize:   15,
                          )),
                    ),

                  // ─ Input ───────────────────────────────────
                  Expanded(
                    child: TextField(
                      controller:        controller,
                      focusNode:         focusNode,
                      inputFormatters:   formatter,
                      textInputAction:
                          nextFocus != null
                              ? TextInputAction.next
                              : TextInputAction.done,
                      onSubmitted: (_) => nextFocus
                          ?.requestFocus(),
                      style: GoogleFonts.inter(
                        color:    AppColors.pureWhite,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText:  hint,
                        hintStyle: GoogleFonts.inter(
                          color:    AppColors.mediumGray
                              .withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        border:         InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical:   14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── CHAMP BIO ───────────────────────────────────────────────────
  Widget _buildBioField() {
    return AnimatedBuilder(
      animation: _bioFocus,
      builder: (_, __) {
        final focused = _bioFocus.hasFocus;
        final charCount = _bioCtrl.text.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Label + compteur ──────────────────────────────
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                AnimatedDefaultTextStyle(
                  duration:
                      const Duration(milliseconds: 150),
                  style: GoogleFonts.inter(
                    color: focused
                        ? AppColors.crimsonRed
                        : AppColors.mediumGray,
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  child: const Text('BIO'),
                ),
                AnimatedDefaultTextStyle(
                  duration:
                      const Duration(milliseconds: 150),
                  style: GoogleFonts.inter(
                    color: charCount > 120
                        ? AppColors.crimsonRed
                        : AppColors.mediumGray,
                    fontSize: 11,
                  ),
                  child: Text('$charCount / 150'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ─ Champ texte multiligne ─────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:        AppColors.darkGray,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: focused
                      ? AppColors.crimsonRed
                          .withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _bioCtrl,
                focusNode:  _bioFocus,
                maxLines:   4,
                maxLength:  150,
                onChanged:  (_) => setState(() {}),
                style: GoogleFonts.inter(
                  color:    AppColors.pureWhite,
                  fontSize: 15,
                  height:   1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Parle de toi, de tes animés préférés...',
                  hintStyle: GoogleFonts.inter(
                    color:    AppColors.mediumGray
                        .withValues(alpha: 0.5),
                    fontSize: 14,
                    height:   1.5,
                  ),
                  border:  InputBorder.none,
                  counterText: '', // ✅ Cacher le counter natif
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── BARRE SAUVEGARDER ───────────────────────────────────────────
  Widget _buildSaveBar() {
    return Container(
      color: AppColors.deepBlack,
      padding: EdgeInsets.only(
        left:   20, right: 20,
        top:    12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          // ─ Annuler ─────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  Navigator.pop(context, false),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.darkGray,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white
                        .withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: Text('Annuler',
                      style: GoogleFonts.inter(
                        color:      AppColors.mediumGray,
                        fontWeight: FontWeight.w600,
                        fontSize:   15,
                      )),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ─ Sauvegarder ─────────────────────────────────────
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isSaving ? null : _save,
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: _isSaving
                      ? null
                      : const LinearGradient(
                          colors: [
                            Color(0xFFE01A3C),
                            Color(0xFFFF4F6E),
                          ],
                          begin: Alignment.centerLeft,
                          end:   Alignment.centerRight,
                        ),
                  color: _isSaving
                      ? AppColors.crimsonRed
                          .withValues(alpha: 0.4)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isSaving
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.crimsonRed
                                .withValues(alpha: 0.4),
                            blurRadius:   20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size:  18,
                            ),
                            const SizedBox(width: 8),
                            Text('Sauvegarder',
                                style: GoogleFonts.inter(
                                  color:      Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize:   15,
                                )),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BOUTON NAVIGATION TRANSPARENT ───────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData     icon;
  final String?      label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: label != null
              ? const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8)
              : const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(
                label != null ? 20 : 12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(label!,
                    style: GoogleFonts.inter(
                      color:      Colors.white,
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ],
          ),
        ),
      );
}