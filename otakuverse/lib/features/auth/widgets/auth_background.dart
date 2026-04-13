import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // ─ Cercle déco haut droite ──────────────────────────
          Positioned(
            top:   -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary
                    .withValues(alpha: 0.07),
              ),
            ),
          ),

          // ─ Cercle déco bas gauche ───────────────────────────
          Positioned(
            bottom: -80, left: -50,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent
                    .withValues(alpha: 0.05),
              ),
            ),
          ),

          // ─ Contenu ─────────────────────────────────────────
          SafeArea(child: child),
        ],
      ),
    );
  }
}