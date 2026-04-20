import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/auth/widgets/auth_background.dart';
import 'package:otakuverse/features/auth/widgets/auth_error_banner.dart';
import 'package:otakuverse/features/auth/widgets/auth_header.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _supabase     = Supabase.instance.client;
  final _emailCtrl    = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool    _isLoading    = false;
  bool    _showPassword = false;
  bool    _showConfirm  = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _errorMessage = null; _isLoading = true; });
    try {
      final response = await _supabase.auth.signUp(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {
          'username':     _usernameCtrl.text.trim(),
          'display_name': _usernameCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      if (response.user != null) {
        Get.offAllNamed(Routes.onboarding);
      } else {
        setState(() => _errorMessage = 'Erreur lors de l\'inscription');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapError(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Erreur inattendue');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapError(String msg) {
    if (msg.contains('already registered')) return 'Cet email est déjà utilisé';
    if (msg.contains('Password should be')) return 'Le mot de passe doit faire au moins 6 caractères';
    if (msg.contains('Unable to validate')) return 'Email invalide';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Get.back(),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthHeader(
                    showLogo: false,
                    title:    'Crée ton compte',
                    subtitle: 'Rejoins la tribu des otakus',
                  ),
                  const SizedBox(height: 28),

                  if (_errorMessage != null)
                    AuthErrorBanner(message: _errorMessage!),

                  _buildLabel('Email'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller:   _emailCtrl,
                    hint:         'ton@email.com',
                    icon:         Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Email requis';
                      if (!v!.contains('@'))  return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Nom d\'utilisateur'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _usernameCtrl,
                    hint:       'username',
                    icon:       Icons.person_outline_rounded,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Username requis';
                      if (v!.length < 3)      return '3 caractères minimum';
                      if (v.contains(' '))    return 'Pas d\'espaces';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Mot de passe'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller:  _passwordCtrl,
                    hint:        '8 caractères minimum',
                    icon:        Icons.lock_outline_rounded,
                    obscure:     !_showPassword,
                    suffixIcon:  _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onSuffixTap: () => setState(() => _showPassword = !_showPassword),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Mot de passe requis';
                      if (v!.length < 8)      return '8 caractères minimum';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Confirmer le mot de passe'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller:  _confirmCtrl,
                    hint:        'Répète ton mot de passe',
                    icon:        Icons.lock_outline_rounded,
                    obscure:     !_showConfirm,
                    suffixIcon:  _showConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onSuffixTap: () => setState(() => _showConfirm = !_showConfirm),
                    validator: (v) {
                      if (v != _passwordCtrl.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ✅ Key sur le bouton d'inscription
                  GestureDetector(
                    key:   AppKeys.signupButton,
                    onTap: _isLoading ? null : _handleSignUp,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52, width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: _isLoading ? null : AppColors.primaryGradient,
                        color:    _isLoading
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _isLoading ? null : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: AppColors.white, strokeWidth: 2.5))
                            : Text('Créer mon compte',
                                style: AppTextStyles.button
                                    .copyWith(color: AppColors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Déjà un compte ? ',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text('Se connecter',
                          style: AppTextStyles.bodySemiBold
                              .copyWith(color: AppColors.primary)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildLabel(String label) =>
      Text(label, style: AppTextStyles.inputLabel);

  Widget _buildField({
    required TextEditingController     controller,
    required String                    hint,
    required IconData                  icon,
    bool                               obscure     = false,
    IconData?                          suffixIcon,
    VoidCallback?                      onSuffixTap,
    TextInputType?                     keyboardType,
    String? Function(String?)?         validator,
  }) =>
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
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          suffixIcon: suffixIcon != null
              ? GestureDetector(onTap: onSuffixTap,
                  child: Icon(suffixIcon, color: AppColors.textMuted, size: 20))
              : null,
          border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          errorStyle:     AppTextStyles.caption.copyWith(color: AppColors.error),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
