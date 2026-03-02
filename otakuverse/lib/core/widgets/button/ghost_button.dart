import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';

class GhostButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;

  const GhostButton({super.key, required this.text, this.onPressed});

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Calcul de l'opacité selon l'état du bouton
    double opacity = 1.0;
    if (widget.onPressed == null) {
      opacity = 0.4;
    } else if (_isPressed) {
      opacity = 0.7;
    } 

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        duration: const Duration(microseconds: 100),
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: AppColors.deepBlack,
              fontFamily: GoogleFonts.inter().fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500
            ),
          ),
        ),
      ),
    );
  }
}

