import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/constants/text_styles.dart';
import 'package:otakuverse/core/utils/validators.dart';
import 'package:otakuverse/core/widgets/button/app_button.dart';
import 'package:otakuverse/core/widgets/input/input_standard.dart';
import 'package:otakuverse/features/auth/controllers/auth_controller.dart';
import 'package:otakuverse/features/auth/screens/signup_screen.dart'; // ✅ import absolu

class SignInScreen extends StatelessWidget {
  SignInScreen({super.key});

  final _authController  = Get.find<AuthController>();
  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Signature correcte avec paramètres nommés
    await _authController.signIn(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                _buildHeader(),
                const SizedBox(height: 60),

                // ─── Erreur réactive ──────────────────────────────
                Obx(() {
                  if (_authController.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _buildErrorBanner(_authController.errorMessage.value);
                }),

                InputStandard(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                InputStandard(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  prefixIcon: Icons.lock_outlined,
                  validator: Validators.validatePassword,
                  isPassword: true,
                ),
                const SizedBox(height: 12),

                _buildForgotPassword(context),
                const SizedBox(height: 32),

                Obx(() => AppButton(
                  label: 'Se connecter',
                  type: AppButtonType.primary,
                  isLoading: _authController.isLoading.value,
                  onPressed: _handleSignIn,
                )),

                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildSignUpLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Image.asset('assets/logo/otakuverse_logo.png'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Bon retour !',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connecte-toi pour continuer',
          style: TextStyle(fontSize: 15, color: Colors.grey[400]),
        ),
      ],
    );
  }

  // ─── BANNER ERREUR ─────────────────────────────────────────────────
  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.errorRed, fontSize: 14),
            ),
          ),
          // ✅ Bouton fermer le banner
          GestureDetector(
            onTap: () => _authController.errorMessage.value = '',
            child: const Icon(Icons.close,
                color: AppColors.errorRed, size: 18),
          ),
        ],
      ),
    );
  }

  // ─── MOT DE PASSE OUBLIÉ ───────────────────────────────────────────
  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Get.snackbar(
          'Bientôt disponible',
          'La réinitialisation du mot de passe arrive prochainement',
          backgroundColor: AppColors.darkGray,
          colorText: AppColors.pureWhite,
          snackPosition: SnackPosition.BOTTOM,
        ),
        child: const Text(
          'Mot de passe oublié ?',
          style: TextStyle(color: AppColors.crimsonRed, fontSize: 14),
        ),
      ),
    );
  }

  // ─── DIVIDER ───────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[800])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[800])),
      ],
    );
  }

  // ─── LIEN INSCRIPTION ──────────────────────────────────────────────
  Widget _buildSignUpLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ? ',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        TextButton(
          onPressed: () => Get.to(() => SignUpScreen()), // ✅ GetX au lieu de Navigator
          child: Text("S'inscrire", style: AppTextStyles.link),
        ),
      ],
    );
  }
}