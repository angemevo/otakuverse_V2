import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

// ─── Modèle de données du sondage ────────────────────────────────────
class PollData {
  final String question;
  final String optionA;
  final String optionB;
  final int    durationHours;

  const PollData({
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.durationHours,
  });
}

/// Sheet de création de sondage.
class PollSheet extends StatefulWidget {
  final ValueChanged<PollData>? onPollCreated;
  const PollSheet({super.key, this.onPollCreated});

  @override
  State<PollSheet> createState() => _PollSheetState();
}

class _PollSheetState extends State<PollSheet> {
  final _questionCtrl = TextEditingController();
  final _option1Ctrl  = TextEditingController(text: 'Option 1');
  final _option2Ctrl  = TextEditingController(text: 'Option 2');
  int   _duration     = 24;

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
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 16),
            Text('Créer un sondage',
                style: GoogleFonts.poppins(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 16),
            PollField(controller: _questionCtrl,
                hint: 'Pose ta question...', label: 'Question'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PollField(
                  controller: _option1Ctrl,
                  hint: 'Option 1', label: 'Option A')),
              const SizedBox(width: 8),
              Expanded(child: PollField(
                  controller: _option2Ctrl,
                  hint: 'Option 2', label: 'Option B')),
            ]),
            const SizedBox(height: 16),
            Text('Durée du sondage',
                style: GoogleFonts.inter(
                    color:      AppColors.textMuted,
                    fontSize:   12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [6, 12, 24, 48].map((h) {
                final sel = _duration == h;
                return GestureDetector(
                  onTap: () => setState(() => _duration = h),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : AppColors.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text('${h}h',
                        style: GoogleFonts.inter(
                          color:      AppColors.textPrimary,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          fontSize:   13,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final q = _questionCtrl.text.trim();
                  if (q.isEmpty) return;
                  widget.onPollCreated?.call(PollData(
                    question:      q,
                    optionA:       _option1Ctrl.text.trim().isEmpty
                        ? 'Option A' : _option1Ctrl.text.trim(),
                    optionB:       _option2Ctrl.text.trim().isEmpty
                        ? 'Option B' : _option2Ctrl.text.trim(),
                    durationHours: _duration,
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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

/// Champ de saisie utilisé dans le sondage.
class PollField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  const PollField({super.key, required this.controller, required this.hint, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(
          color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
          color:        AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.textMuted.withValues(alpha: 0.3)),
        ),
        child: TextField(
          controller: controller,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText:       hint,
            hintStyle:      GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    ],
  );
}