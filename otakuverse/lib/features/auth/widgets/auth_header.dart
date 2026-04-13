import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool   showLogo;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─ Logo + Nom ────────────────────────────────────────
        if (showLogo) ...[
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient:     AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.white,
                  size:  18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'OTAKUVERSE',
                style: AppTextStyles.appBarTitle,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // ─ Titre ─────────────────────────────────────────────
        Text(title,    style: AppTextStyles.h1),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTextStyles.bodySmall),
      ],
    );
  }
}