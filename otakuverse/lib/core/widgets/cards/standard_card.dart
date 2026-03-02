import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/constants/dimensions.dart';

class StandardCard extends StatelessWidget {
  final Widget child;
  const StandardCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGray : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
          width: 1
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackWithOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2)
          )
        ]
      ),
      child: child,
    );
  }
}