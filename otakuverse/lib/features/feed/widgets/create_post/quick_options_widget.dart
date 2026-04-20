import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'widgets/poll_sheet.dart';

export 'widgets/poll_sheet.dart' show PollData;

class QuickOptionsWidget extends StatelessWidget {
  final ValueChanged<PollData>? onPollCreated;
  const QuickOptionsWidget({super.key, this.onPollCreated});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColors.bgPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        _QuickChip(
          icon: Icons.bar_chart_outlined, label: 'Sondage',
          onTap: () => showModalBottomSheet(
            context:            context,
            backgroundColor:    AppColors.bgCard,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => PollSheet(onPollCreated: onPollCreated),
          ),
        ),
        const SizedBox(width: 8),
        _QuickChip(
          icon: Icons.person_outline, label: 'Inviter',
          onTap: () => showModalBottomSheet(
            context:         context,
            backgroundColor: AppColors.bgCard,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => const _InviteSheet(),
          ),
        ),
      ]),
    );
  }
}

// ─── Invite sheet ────────────────────────────────────────────────────

class _InviteSheet extends StatelessWidget {
  const _InviteSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        const Icon(Icons.person_add_outlined,
            color: AppColors.primary, size: 48),
        const SizedBox(height: 12),
        Text('Inviter des amis',
            style: GoogleFonts.poppins(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 17)),
        const SizedBox(height: 8),
        Text('Cette fonctionnalité arrive prochainement 🚧',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 44,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Fermer',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ─── Quick chip ──────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;
  const _QuickChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.textPrimary, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
              color:           AppColors.textPrimary,
              fontSize:        13,
              fontWeight:      FontWeight.w600,
              decoration:      TextDecoration.none,
              decorationColor: Colors.transparent,
            )),
      ]),
    ),
  );
} 
