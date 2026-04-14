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
          // ─ Glow principal — violet haut centre ──────────────────
          Positioned(
            top: -100, left: -60,
            child: _Blob(
              size:    340,
              color:   AppColors.primary,
              opacity: 0.13,
            ),
          ),

          // ─ Glow secondaire — sakura haut droit ──────────────────
          Positioned(
            top: -40, right: -80,
            child: _Blob(
              size:    220,
              color:   AppColors.sakura,
              opacity: 0.07,
            ),
          ),

          // ─ Glow accent — orange bas droite ──────────────────────
          Positioned(
            bottom: -60, right: -40,
            child: _Blob(
              size:    260,
              color:   AppColors.accent,
              opacity: 0.08,
            ),
          ),

          // ─ Glow bleu — bas gauche ───────────────────────────────
          Positioned(
            bottom: 80, left: -70,
            child: _Blob(
              size:    180,
              color:   AppColors.neonBlue,
              opacity: 0.05,
            ),
          ),

          // ─ Contenu ──────────────────────────────────────────────
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color  color;
  final double opacity;

  const _Blob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) => Container(
    width:  size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ],
      ),
    ),
  );
}
