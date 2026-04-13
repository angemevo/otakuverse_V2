import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class DateSeparator extends StatelessWidget {
  final DateTime date;
  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Divider(
          color: AppColors.textMuted.withValues(alpha: 0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _buildLabel(date),
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ),
        Expanded(child: Divider(
          color: AppColors.textMuted.withValues(alpha: 0.2))),
      ]),
    );
  }

  String _buildLabel(DateTime date) {
    final now      = DateTime.now();
    final today    = DateTime(now.year, now.month, now.day);
    final local    = date.toLocal();
    final msgDay   = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(msgDay).inDays;

    if (diffDays == 0) return 'Aujourd\'hui';
    if (diffDays == 1) return 'Hier';
    if (diffDays < 7) {
      const jours = [
        'Lundi', 'Mardi', 'Mercredi',
        'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
      ];
      return jours[local.weekday - 1];
    }
    return '${local.day}/${local.month}/${local.year}';
  }
}