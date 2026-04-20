import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─ Icône animée ──────────────────────────────────────
            Container(
              width:  80,
              height: 80,
              decoration: BoxDecoration(
                color:        AppColors.bgCard,
                shape:        BoxShape.circle,
                border: Border.all(
                  color: AppColors.textMuted
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                HeroiconsOutline.signalSlash,
                color: AppColors.textMuted,
                size:  36,
              ),
            ),
            const SizedBox(height: 24),

            // ─ Titre ─────────────────────────────────────────────
            Text(
              'Pas de connexion',
              style: GoogleFonts.poppins(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize:   18,
              ),
            ),
            const SizedBox(height: 8),

            // ─ Sous-titre ────────────────────────────────────────
            Text(
              'Vérifie ta connexion internet\net réessaie.',
              style: GoogleFonts.inter(
                color:    AppColors.textMuted,
                fontSize: 14,
                height:   1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ─ Bouton réessayer ──────────────────────────────────
            if (onRetry != null)
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        Color(0xFFFF4D6D),
                      ],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset:     const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Réessayer',
                    style: GoogleFonts.inter(
                      color:      Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize:   15,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
