import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class ShareButton extends StatelessWidget {
  final bool         isPublishing;
  final VoidCallback onTap;

  const ShareButton({
    super.key,
    required this.isPublishing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      padding: EdgeInsets.only(
        left:   16,
        right:  16,
        top:    12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SizedBox(
        width:  double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isPublishing ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor:         AppColors.primary,
            disabledBackgroundColor: AppColors.primary
                .withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: isPublishing
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Partager',
                  style: GoogleFonts.inter(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize:   16,
                  )),
        ),
      ),
    );
  }
}