import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/auth/services/google_auth_service.dart';
import 'package:otakuverse/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/auth/widgets/auth_background.dart';
import 'package:otakuverse/features/auth/widgets/auth_error_banner.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _supabase          = Supabase.instance.client;
  final _googleAuthService = GoogleAuthService();
  final _emailCtrl         = TextEditingController();
  final _passwordCtrl      = TextEditingController();
  final _formKey           = GlobalKey<FormState>();

  bool    _isLoading       = false;
  bool    _isGoogleLoading = false;
  bool    _showPassword    = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _errorMessage = null; _isLoading = true; });
    try {
      await _supabase.auth.signInWithPassword(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Get.offAllNamed(Routes.home);
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapError(e.message));
    } catch (_) {
      setState(() => _errorMessage = 'Erreur inattendue');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() { _errorMessage = null; _isGoogleLoading = true; });
    try {
      final response = await _googleAuthService.signInWithGoogle();
      if (!mounted) return;
      if (response == null) return;
      final user = response.user;
      if (user == null) throw Exception('Utilisateur introuvable');

      final existing = await _supabase
          .from('profiles')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        Get.offAllNamed(Routes.home);
        return;
      }

      final email       = user.email ?? '';
      final displayName = user.userMetadata?['full_name'] as String? ??
                          user.userMetadata?['name']      as String? ??
                          email.split('@').first;
      final avatarUrl   = user.userMetadata?['avatar_url'] as String? ??
                          user.userMetadata?['picture']     as String?;
      final baseUsername = email.split('@').first.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      final username = '${baseUsername}_${user.id.substring(0, 6)}';

      await _supabase.from('profiles').insert({
        'user_id':         user.id,
        'username':        username,
        'email':           email,
        'display_name':    displayName,
        'avatar_url':      avatarUrl,
        'favorite_anime':  [],
        'favorite_manga':  [],
        'favorite_games':  [],
        'favorite_genres': [],
        'followers_count': 0,
        'following_count': 0,
        'posts_count':     0,
        'is_private':      false,
        'is_verified':     false,
        'created_at':      DateTime.now().toIso8601String(),
        'updated_at':      DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Get.offAllNamed(Routes.onboarding);
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapError(e.message));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Connexion Google échouée');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar('Email requis', 'Saisis ton email pour réinitialiser',
        backgroundColor: AppColors.bgCard, colorText: AppColors.textPrimary,
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16),
        borderRadius: 12);
      return;
    }
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      Get.snackbar('Email envoyé', 'Vérifie ta boîte mail',
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: AppColors.white, snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16), borderRadius: 12);
    } catch (_) {
      Get.snackbar('Erreur', 'Impossible d\'envoyer l\'email',
        backgroundColor: AppColors.error, colorText: AppColors.white,
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16),
        borderRadius: 12);
    }
  }

  String _mapError(String msg) {
    if (msg.contains('Invalid login'))       return 'Email ou mot de passe incorrect';
    if (msg.contains('Email not confirmed')) return 'Confirme ton email avant de te connecter';
    if (msg.contains('Too many requests'))   return 'Trop de tentatives, réessaie dans 1 minute';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Column(children: [
        _HeroSection(),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bon retour !', style: AppTextStyles.h1),
                    const SizedBox(height: 4),
                    Text('Connecte-toi pour retrouver ta tribu',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 28),

                    if (_errorMessage != null) ...[
                      AuthErrorBanner(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    // ✅ Key sur le champ email
                    _AuthField(
                      key:          AppKeys.emailField,
                      controller:   _emailCtrl,
                      label:        'Adresse email',
                      hint:         'ton@email.com',
                      prefixIcon:   Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Email requis';
                        if (!v!.contains('@'))  return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ✅ Key sur le champ mot de passe
                    _AuthField(
                      key:         AppKeys.passwordField,
                      controller:  _passwordCtrl,
                      label:       'Mot de passe',
                      hint:        '••••••••',
                      prefixIcon:  Icons.lock_outline_rounded,
                      obscure:     !_showPassword,
                      suffixIcon:  _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onSuffixTap: () => setState(() => _showPassword = !_showPassword),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Mot de passe requis';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _handleForgotPassword,
                        child: Text('Mot de passe oublié ?',
                            style: GoogleFonts.inter(
                              color: AppColors.primary, fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ✅ Key sur le bouton de connexion
                    _PrimaryButton(
                      key:       AppKeys.loginButton,
                      label:     'Se connecter',
                      isLoading: _isLoading,
                      onTap:     _handleSignIn,
                    ),
                    const SizedBox(height: 20),
                    _Divider(),
                    const SizedBox(height: 20),
                    _GoogleButton(isLoading: _isGoogleLoading, onTap: _handleGoogle),
                    const SizedBox(height: 32),

                    Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Pas encore de compte ? ',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => Get.toNamed(Routes.signup),
                          child: Text('S\'inscrire',
                              style: GoogleFonts.inter(
                                color: AppColors.primary, fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          Container(
            width: 92, height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 24, spreadRadius: 4)],
            ),
          ),
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              gradient:     AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.white, size: 30),
          ),
        ]),
        const SizedBox(height: 18),
        Text('OTAKUVERSE',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary, fontSize: 22,
              fontWeight: FontWeight.w800, letterSpacing: 4)),
        const SizedBox(height: 4),
        Text('Ta communauté anime',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
      ]),
    );
  }
}

// ─── Champ de saisie ──────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     label;
  final String                     hint;
  final IconData                   prefixIcon;
  final bool                       obscure;
  final IconData?                  suffixIcon;
  final VoidCallback?              onSuffixTap;
  final TextInputType?             keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscure      = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style:        AppTextStyles.inputText,
      validator:    validator,
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        hintStyle:  AppTextStyles.inputHint,
        filled:     true,
        fillColor:  AppColors.bgCard,
        prefixIcon: Icon(prefixIcon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(suffixIcon, color: AppColors.textMuted, size: 20))
            : null,
        border:            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border, width: 1)),
        focusedBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder:       OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        focusedErrorBorder:OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        errorStyle:        AppTextStyles.caption.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }
}

// ─── Bouton principal ─────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String       label;
  final bool         isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56, width: double.infinity,
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.primaryGradient,
          color:    isLoading
              ? AppColors.primary.withValues(alpha: 0.35)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading ? null : [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: GoogleFonts.poppins(
                    color: AppColors.white, fontSize: 15,
                    fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.white, size: 18),
                ]),
        ),
      ),
    );
  }
}

// ─── Séparateur ───────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: AppColors.border, thickness: 1)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text('OU', style: GoogleFonts.inter(
        color: AppColors.textMuted, fontSize: 11,
        fontWeight: FontWeight.w600, letterSpacing: 1.5)),
    ),
    Expanded(child: Divider(color: AppColors.border, thickness: 1)),
  ]);
}

// ─── Bouton Google ────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool         isLoading;
  final VoidCallback onTap;

  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54, width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLoading ? AppColors.border : AppColors.borderLight,
            width: 1),
        ),
        child: isLoading
            ? const Center(child: SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset('assets/logo/google.png', width: 22, height: 22),
                const SizedBox(width: 12),
                Text('Continuer avec Google',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 14,
                      fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }
}
