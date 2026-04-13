import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/services/profile_service.dart';
import 'package:otakuverse/features/profile/widgets/edit_profile_field.dart';
import 'package:otakuverse/features/profile/widgets/edit_profile_header.dart';
import 'package:otakuverse/features/profile/widgets/edit_profile_save_bar.dart';


class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {

  // ─── Contrôleurs texte ───────────────────────────────────────────
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;

  // ─── Focus nodes ─────────────────────────────────────────────────
  final _displayNameFocus = FocusNode();
  final _usernameFocus    = FocusNode();
  final _bioFocus         = FocusNode();

  // ─── État ────────────────────────────────────────────────────────
  final _profileService = ProfileService();
  bool       _isSaving      = false;
  XFile?     _avatarFile;
  Uint8List? _avatarPreview;
  XFile?     _bannerFile;
  Uint8List? _bannerPreview;

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
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

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

  // ─── Pickers ─────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    HapticFeedback.lightImpact();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() { _avatarFile = file; _avatarPreview = bytes; });
  }

  Future<void> _pickBanner() async {
    HapticFeedback.lightImpact();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() { _bannerFile = file; _bannerPreview = bytes; });
  }

  // ─── Sauvegarde ──────────────────────────────────────────────────

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final username    = _usernameCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();
    final bio         = _bioCtrl.text.trim();

    if (username.isEmpty) {
      Helpers.showErrorSnackbar('Le nom d\'utilisateur est obligatoire');
      return;
    }
    if (username.contains(' ')) {
      Helpers.showErrorSnackbar(
          'Le nom d\'utilisateur ne peut pas contenir d\'espaces');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    // ✅ Uploads indépendants : un échec n'annule pas la sauvegarde texte
    final newAvatarUrl = await _tryUploadAvatar();
    final newBannerUrl = await _tryUploadBanner();

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
      debugPrint('❌ updateProfile: $e\n$s');
      if (!mounted) return;
      Helpers.showErrorSnackbar('Impossible de sauvegarder : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _tryUploadAvatar() async {
    if (_avatarFile == null) return null;
    try {
      final bytes = await _avatarFile!.readAsBytes();
      final ext   = _avatarFile!.path.split('.').last.toLowerCase();
      return await _profileService.uploadAvatar(bytes, ext);
    } catch (e) {
      debugPrint('⚠️ Avatar upload: $e');
      return null;
    }
  }

  Future<String?> _tryUploadBanner() async {
    if (_bannerFile == null) return null;
    try {
      final bytes = await _bannerFile!.readAsBytes();
      final ext   = _bannerFile!.path.split('.').last.toLowerCase();
      return await _profileService.uploadBanner(bytes, ext);
    } catch (e) {
      debugPrint('⚠️ Banner upload: $e');
      return null;
    }
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:   AppColors.bgPrimary,
      bottomNavigationBar: EditProfileSaveBar(
        isSaving: _isSaving,
        onCancel: () => Navigator.pop(context, false),
        onSave:   _save,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: EditProfileHeader(
                  profile:       widget.profile,
                  avatarPreview: _avatarPreview,
                  bannerPreview: _bannerPreview,
                  onPickAvatar:  _pickAvatar,
                  onPickBanner:  _pickBanner,
                  onBack:        () => Navigator.pop(context, false),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver:  SliverList(
                  delegate: SliverChildListDelegate([
                    _sectionLabel('IDENTITÉ'),
                    const SizedBox(height: 12),
                    EditProfileField(
                      label:     'Nom affiché',
                      controller: _displayNameCtrl,
                      focusNode:  _displayNameFocus,
                      hint:       'Ton nom public',
                      icon:       Icons.badge_outlined,
                      nextFocus:  _usernameFocus,
                    ),
                    const SizedBox(height: 12),
                    EditProfileField(
                      label:      'Nom d\'utilisateur',
                      controller: _usernameCtrl,
                      focusNode:  _usernameFocus,
                      hint:       'username',
                      icon:       Icons.alternate_email,
                      nextFocus:  _bioFocus,
                      formatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        LengthLimitingTextInputFormatter(30),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('BIO'),
                    const SizedBox(height: 12),
                    EditProfileBioField(
                      controller: _bioCtrl,
                      focusNode:  _bioFocus,
                      onChanged:  () => setState(() {}),
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Label section ───────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Row(children: [
      Text(
        label,
        style: GoogleFonts.inter(
          color:         AppColors.primary,
          fontSize:      11,
          fontWeight:    FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          height: 1,
          color:  AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
    ]);
  }
}