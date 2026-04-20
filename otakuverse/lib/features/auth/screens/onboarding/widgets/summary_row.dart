import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;

  const SummaryRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.bodySemiBold.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
