import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/feed/screens/media_picker_screen.dart';

class CreatePostButton extends StatefulWidget {
  const CreatePostButton({super.key});

  @override
  State<CreatePostButton> createState() => _CreatePostButtonState();
}

class _CreatePostButtonState extends State<CreatePostButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double>   _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    _pulseController.stop();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MediaPickerScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end:   Offset.zero,
          ).animate(CurvedAnimation(
              parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((_) => _pulseController.repeat(reverse: true));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:    _onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56, height: 60,
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            ),
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE01A3C), Color(0xFFFF4F6E)],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color:        AppColors.crimsonRed
                        .withValues(alpha: 0.5),
                    blurRadius:   20,
                    spreadRadius: 0,
                    offset:       const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size:  28),
            ),
          ),
        ),
      ),
    );
  }
}