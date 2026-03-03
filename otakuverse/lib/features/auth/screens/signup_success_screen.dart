import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/auth/controllers/auth_controller.dart';

class SignupSuccessScreen extends StatefulWidget {
  const SignupSuccessScreen({super.key});

  @override
  State<SignupSuccessScreen> createState() => _SignupSuccessScreenState();
}

class _SignupSuccessScreenState extends State<SignupSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    // ✅ Redirection GetX vers home après 2.5s
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Get.offAllNamed('/home');
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Username récupéré depuis le controller, pas en paramètre
    final username = Get.find<AuthController>().currentUser.value?.username ?? '';

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Icône animée ───────────────────────────────
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.successGreen,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: AppColors.successGreen,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ─── Titre ──────────────────────────────────────
                const Text(
                  'Inscription réussie !',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.pureWhite,
                  ),
                ),

                const SizedBox(height: 12),

                // ─── Message de bienvenue ────────────────────────
                Text(
                  'Bienvenue sur Otakuverse, $username 👋\nPrépare-toi à rejoindre la communauté 🎌',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.mediumGray,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // ─── Indicateur de chargement ────────────────────
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.crimsonRed,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Redirection en cours...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mediumGray.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}