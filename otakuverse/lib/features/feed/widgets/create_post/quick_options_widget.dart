import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class QuickOptionsWidget extends StatelessWidget {
  final VoidCallback? onPollTap;
  final VoidCallback? onInviteTap;

  const QuickOptionsWidget({
    super.key,
    this.onPollTap,
    this.onInviteTap,
  });

  void _showPollSheet(BuildContext context) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppColors.darkGray,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) => const _PollSheet(),
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppColors.darkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) => const _InviteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppColors.deepBlack,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _QuickChip(
            icon:  Icons.bar_chart_outlined,
            label: 'Sondage',
            onTap: () => _showPollSheet(context),
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon:  Icons.person_outline,
            label: 'Inviter',
            onTap: () => _showInviteSheet(context),
          ),
        ],
      ),
    );
  }
}

// ─── POLL SHEET ──────────────────────────────────────────────────────
class _PollSheet extends StatefulWidget {
  const _PollSheet();

  @override
  State<_PollSheet> createState() => _PollSheetState();
}

class _PollSheetState extends State<_PollSheet> {
  final _questionCtrl  = TextEditingController();
  final _option1Ctrl   = TextEditingController(text: 'Option 1');
  final _option2Ctrl   = TextEditingController(text: 'Option 2');
  int   _duration      = 24; // heures

  @override
  void dispose() {
    _questionCtrl.dispose();
    _option1Ctrl.dispose();
    _option2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Handle ─────────────────────────────────────
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color:        AppColors.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Créer un sondage',
                style: GoogleFonts.poppins(
                  color:      AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                  fontSize:   17,
                )),
            const SizedBox(height: 16),

            // ─ Question ───────────────────────────────────
            _PollField(
              controller: _questionCtrl,
              hint:       'Pose ta question...',
              label:      'Question',
            ),
            const SizedBox(height: 12),

            // ─ Options ────────────────────────────────────
            Row(children: [
              Expanded(
                child: _PollField(
                  controller: _option1Ctrl,
                  hint:       'Option 1',
                  label:      'Option A',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PollField(
                  controller: _option2Ctrl,
                  hint:       'Option 2',
                  label:      'Option B',
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ─ Durée ──────────────────────────────────────
            Text('Durée du sondage',
                style: GoogleFonts.inter(
                    color:      AppColors.mediumGray,
                    fontSize:   12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [6, 12, 24, 48].map((h) {
                final selected = _duration == h;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _duration = h),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.crimsonRed
                          : AppColors.deepBlack,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.crimsonRed
                            : AppColors.mediumGray
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text('${h}h',
                        style: GoogleFonts.inter(
                          color:      AppColors.pureWhite,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ─ Bouton valider ─────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimsonRed,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Ajouter le sondage',
                    style: GoogleFonts.inter(
                      color:      Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize:   15,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── POLL FIELD ──────────────────────────────────────────────────────
class _PollField extends StatelessWidget {
  final TextEditingController controller;
  final String                hint;
  final String                label;

  const _PollField({
    required this.controller,
    required this.hint,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: GoogleFonts.inter(
              color:    AppColors.mediumGray,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
          color:        AppColors.deepBlack,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.mediumGray
                .withValues(alpha: 0.3),
          ),
        ),
        child: TextField(
          controller: controller,
          style: GoogleFonts.inter(
              color: AppColors.pureWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText:       hint,
            hintStyle: GoogleFonts.inter(
                color:    AppColors.mediumGray,
                fontSize: 14),
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
        ),
      ),
    ],
  );
}

// ─── INVITE SHEET ────────────────────────────────────────────────────
class _InviteSheet extends StatelessWidget {
  const _InviteSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        AppColors.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.person_add_outlined,
              color: AppColors.crimsonRed, size: 48),
          const SizedBox(height: 12),
          Text('Inviter des amis',
              style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w700,
                fontSize:   17,
              )),
          const SizedBox(height: 8),
          Text(
            'Cette fonctionnalité arrive prochainement 🚧',
            style: GoogleFonts.inter(
                color:    AppColors.mediumGray,
                fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width:  double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimsonRed,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Fermer',
                  style: GoogleFonts.inter(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QUICK CHIP ──────────────────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.mediumGray
              .withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.pureWhite, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                color:           AppColors.pureWhite,
                fontSize:        13,
                fontWeight:      FontWeight.w600,
                decoration:      TextDecoration.none,
                decorationColor: Colors.transparent,
              )),
        ],
      ),
    ),
  );
}