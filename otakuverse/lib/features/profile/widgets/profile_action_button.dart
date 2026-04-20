import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

// ─── Bouton d'action profil ──────────────────────────────────────────

class ProfileActionButton extends StatelessWidget {
  final String?      label;
  final IconData     icon;
  final bool         primary;
  final bool         outlined;
  final bool         loading;
  final VoidCallback onTap;

  const ProfileActionButton({
    super.key,
    this.label,
    required this.icon,
    required this.onTap,
    this.primary  = false,
    this.outlined = false,
    this.loading  = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIconOnly = label == null;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height:   40,
        width:    isIconOnly ? 40 : null,
        padding:  isIconOnly
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color:        primary ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: outlined ? AppColors.border : Colors.transparent,
            width: 1,
          ),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    color:       AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:      MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: primary
                        ? AppColors.white
                        : AppColors.textSecondary,
                    size: 16,
                  ),
                  if (label != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      label!,
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: primary
                            ? AppColors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ─── Stat item ───────────────────────────────────────────────────────

class ProfileStatItem extends StatelessWidget {
  final String       value;
  final String       label;
  final VoidCallback? onTap;

  const ProfileStatItem({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Text(value, style: AppTextStyles.stat),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ]),
  );
}

// ─── Séparateur vertical ─────────────────────────────────────────────

class ProfileStatSeparator extends StatelessWidget {
  const ProfileStatSeparator({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width:  1, height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color:  AppColors.border,
  );
}
