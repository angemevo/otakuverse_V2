import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/auth/services/google_auth_service.dart';
import 'package:otakuverse/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/auth/widgets/auth_background.dart';
import 'package:otakuverse/features/auth/widgets/auth_error_banner.dart';
import 'package:otakuverse/features/auth/widgets/auth_header.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _supabase         = Supabase.instance.client;
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

  // ─── EMAIL / PASSWORD ────────────────────────────────────────────
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isLoading    = true;
    });

    try {
      await _supabase.auth.signInWithPassword(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;
      Get.offAllNamed(Routes.home);
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapError(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Erreur inattendue');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── GOOGLE ──────────────────────────────────────────────────────
  Future<void> _handleGoogle() async {
    setState(() {
      _errorMessage    = null;
      _isGoogleLoading = true;
    });

    try {
      await _googleAuthService.signInWithGoogle();
      if (!mounted) return;
      Get.offAllNamed(Routes.home);
    } catch (e) {
      setState(() => _errorMessage =
          'Connexion Google échouée');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ─── MAPPING ERREURS ─────────────────────────────────────────────
  String _mapError(String msg) {
    if (msg.contains('Invalid login')) {
      return 'Email ou mot de passe incorrect';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Confirme ton email avant de te connecter';
    }
    if (msg.contains('Too many requests')) {
      return 'Trop de tentatives, réessaie dans 1 minute';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            24, 40, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthHeader(
                title:    'Bon retour ! 👋',
                subtitle: 'Connecte-toi pour rejoindre ta tribu',
              ),
              const SizedBox(height: 36),

              if (_errorMessage != null)
                AuthErrorBanner(message: _errorMessage!),

              // ─ Email ───────────────────────────────────────
              _Label('Email'),
              const SizedBox(height: 6),
              _Field(
                controller:   _emailCtrl,
                hint:         'ton@email.com',
                prefixIcon:   Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Email requis';
                  if (!v!.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ─ Mot de passe ────────────────────────────────
              _Label('Mot de passe'),
              const SizedBox(height: 6),
              _Field(
                controller: _passwordCtrl,
                hint:       '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscure:    !_showPassword,
                suffixIcon: _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () => setState(
                    () => _showPassword = !_showPassword),
                validator: (v) {
                  if (v?.isEmpty ?? true) {
                    return 'Mot de passe requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(
                    padding:       EdgeInsets.zero,
                    minimumSize:   Size.zero,
                    tapTargetSize: MaterialTapTargetSize
                        .shrinkWrap,
                  ),
                  child: Text(
                    'Mot de passe oublié ?',
                    style: AppTextStyles.bodySmall
                        .copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─ Bouton connexion ────────────────────────────
              _PrimaryButton(
                label:     'Se connecter',
                isLoading: _isLoading,
                onTap:     _handleSignIn,
              ),
              const SizedBox(height: 24),

              _AuthDivider(),
              const SizedBox(height: 24),

              // ─ Google ──────────────────────────────────────
              _GoogleButton(
                isLoading: _isGoogleLoading,
                onTap:     _handleGoogle,
              ),
              const SizedBox(height: 32),

              // ─ Lien inscription ────────────────────────────
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ? ',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Get.toNamed(Routes.signup),
                    child: Text(
                      'S\'inscrire',
                      style: AppTextStyles.bodySemiBold
                          .copyWith(
                              color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar(
        'Email requis',
        'Saisis ton email pour réinitialiser',
        backgroundColor: AppColors.bgCard,
        colorText:       AppColors.textPrimary,
        snackPosition:   SnackPosition.BOTTOM,
        margin:          const EdgeInsets.all(16),
        borderRadius:    12,
      );
      return;
    }

    try {
      await _supabase.auth.resetPasswordForEmail(email);
      Get.snackbar(
        '✅ Email envoyé',
        'Vérifie ta boîte mail',
        backgroundColor: AppColors.success
            .withValues(alpha: 0.9),
        colorText:     AppColors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin:        const EdgeInsets.all(16),
        borderRadius:  12,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer l\'email',
        backgroundColor: AppColors.error,
        colorText:       AppColors.white,
        snackPosition:   SnackPosition.BOTTOM,
        margin:          const EdgeInsets.all(16),
        borderRadius:    12,
      );
    }
  }
}

// ─── WIDGETS LOCAUX ──────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.inputLabel);
}

class _Field extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final IconData                   prefixIcon;
  final bool                       obscure;
  final IconData?                  suffixIcon;
  final VoidCallback?              onSuffixTap;
  final TextInputType?             keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscure      = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) =>
      TextFormField(
        controller:   controller,
        obscureText:  obscure,
        keyboardType: keyboardType,
        style:        AppTextStyles.inputText,
        validator:    validator,
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: AppTextStyles.inputHint,
          filled:    true,
          fillColor: AppColors.bgCard,
          prefixIcon: Icon(prefixIcon,
              color: AppColors.textMuted, size: 20),
          suffixIcon: suffixIcon != null
              ? GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(suffixIcon,
                      color: AppColors.textMuted,
                      size: 20),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.error, width: 1.5),
          ),
          errorStyle: AppTextStyles.caption
              .copyWith(color: AppColors.error),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String       label;
  final bool         isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
      GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height:   52,
          width:    double.infinity,
          decoration: BoxDecoration(
            gradient: isLoading
                ? null
                : AppColors.primaryGradient,
            color: isLoading
                ? AppColors.primary
                    .withValues(alpha: 0.4)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isLoading
                ? null
                : [
                    BoxShadow(
                      color:      AppColors.primary
                          .withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset:     const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color:       AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(label,
                    style: AppTextStyles.button
                        .copyWith(color: AppColors.white)),
          ),
        ),
      );
}

class _AuthDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Divider(
          color: AppColors.border, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16),
        child: Text('OU', style: AppTextStyles.label),
      ),
      Expanded(child: Divider(
          color: AppColors.border, thickness: 1)),
    ],
  );
}

class _GoogleButton extends StatelessWidget {
  final bool         isLoading;
  final VoidCallback onTap;

  const _GoogleButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
      GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          height: 52,
          width:  double.infinity,
          decoration: BoxDecoration(
            color:        AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.border, width: 1),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color:       AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo/google.png',
                      width: 22, height: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continuer avec Google',
                      style: AppTextStyles.button
                          .copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      );
}