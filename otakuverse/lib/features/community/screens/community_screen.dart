import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: Text('Communautés',
            style: GoogleFonts.poppins(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(HeroiconsOutline.userGroup,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Bientôt disponible',
                style: GoogleFonts.poppins(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   16)),
            const SizedBox(height: 6),
            Text('Les communautés arrivent prochainement',
                style: GoogleFonts.inter(
                    color:    AppColors.textMuted,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
