import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/constants/text_styles.dart';
import 'package:otakuverse/core/constants/app_constants.dart';
import 'package:otakuverse/core/utils/validators.dart';
import 'package:otakuverse/core/widgets/button/app_button.dart';
import 'package:otakuverse/core/widgets/divider.dart' show buildDivider;
import 'package:otakuverse/core/widgets/input/input_standard.dart';
import 'package:otakuverse/features/auth/controllers/auth_controller.dart';
import 'package:otakuverse/features/auth/widgets/build_header_widget.dart';
import 'package:otakuverse/features/auth/widgets/signin_link.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  // ✅ GetX controllers (plus de StatefulWidget)
  final _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // ✅ séparé
  final _acceptTerms = false.obs; // ✅ observable

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms.value) {
      Get.snackbar(
        'Conditions requises',
        'Vous devez accepter les conditions d\'utilisation',
        backgroundColor: AppColors.errorRed,
        colorText: AppColors.pureWhite,
      );
      return;
    }

    await _authController.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      displayName: _displayNameController.text.trim().isEmpty
          ? null
          : _displayNameController.text.trim(),
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
                buildHeader(),
                const SizedBox(height: 40),

                // ✅ Message d'erreur réactif via GetX
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
                ),
                const SizedBox(height: 16),

                InputStandard(
                  controller: _usernameController,
                  label: 'Nom d\'utilisateur',
                  prefixIcon: Icons.person_outline,
                  validator: Validators.validateUsername,
                ),
                const SizedBox(height: 16),

                InputStandard(
                  controller: _displayNameController,
                  label: 'Nom d\'affichage (optionnel)',
                  prefixIcon: Icons.badge_outlined,
                  validator: Validators.validateDisplayName,
                  helperText: 'Le nom affiché sur votre profil',
                ),
                const SizedBox(height: 16),

                InputStandard(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  prefixIcon: Icons.lock_outlined,
                  validator: Validators.validatePassword,
                  isPassword: true,
                  helperText: 'Minimum ${AppConstants.minPasswordLength} caractères',
                ),
                const SizedBox(height: 16),

                // ✅ Utilise _confirmPasswordController (pas _passwordController)
                InputStandard(
                  controller: _confirmPasswordController,
                  label: 'Confirmer le mot de passe',
                  prefixIcon: Icons.lock_outlined,
                  isPassword: true,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 20),

                _buildTermsCheckbox(),
                const SizedBox(height: 32),

                // ✅ isLoading piloté par le controller
                Obx(() => AppButton(
                  label: 'S\'inscrire',
                  type: AppButtonType.primary,
                  isLoading: _authController.isLoading.value,
                  onPressed: _handleSignUp,
                )),

                const SizedBox(height: 24),
                buildDivider(),
                const SizedBox(height: 24),
                buildSignInLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.1),
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
              style: const TextStyle(color: AppColors.errorRed, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Obx(() => Row(
      children: [
        Checkbox(
          value: _acceptTerms.value,
          onChanged: (value) => _acceptTerms.value = value ?? false,
          activeColor: AppColors.crimsonRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _acceptTerms.value = !_acceptTerms.value,
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall,
                children: [
                  const TextSpan(text: 'J\'accepte les '),
                  const TextSpan(
                    text: 'conditions d\'utilisation',
                    style: TextStyle(
                      color: AppColors.crimsonRed,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' et la '),
                  const TextSpan(
                    text: 'politique de confidentialité',
                    style: TextStyle(
                      color: AppColors.crimsonRed,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }
}