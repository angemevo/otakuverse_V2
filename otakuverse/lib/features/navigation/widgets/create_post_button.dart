import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/feed/screens/create_post_screen.dart';
import 'dart:math' as math;

class CreatePostButton extends StatefulWidget {
  const CreatePostButton({super.key});

  @override
  State<CreatePostButton> createState() => _CreatePostButtonState();
}

class _CreatePostButtonState extends State<CreatePostButton>
    with TickerProviderStateMixin {
  late final AnimationController _expandController;
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final Animation<double>   _pulseAnimation;

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  static const _items = [
    _BubbleItem(icon: Icons.image_outlined,       label: 'Photo', color: Color(0xFF7C6FFF), index: 0),
    _BubbleItem(icon: Icons.videocam_outlined,     label: 'Vidéo', color: Color(0xFFE91E8C), index: 1),
    _BubbleItem(icon: Icons.auto_awesome_outlined, label: 'Story', color: Color(0xFFFF6B35), index: 2),
  ];

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 450),
    );

    _rotationController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 350),
    );

    // ✅ _pulseController et _pulseAnimation initialisés ici
    _pulseController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _expandController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── TOGGLE ──────────────────────────────────────────────────────
  void _toggle() {
    HapticFeedback.lightImpact();
    _isOpen ? _close() : _open();
  }

  void _open() {
    setState(() => _isOpen = true);
    _expandController.forward();
    _rotationController.forward();
    _pulseController.stop();
    _showOverlay();
  }

  void _close() {
    setState(() => _isOpen = false);
    _expandController.reverse();
    _rotationController.reverse();
    _pulseController.repeat(reverse: true);
    _removeOverlay();
  }

  // ─── OVERLAY ─────────────────────────────────────────────────────
  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final position  = renderBox.localToGlobal(Offset.zero);
    final size      = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => _OverlayContent(
        position:   position,
        buttonSize: size,
        items:      _items,
        controller: _expandController,
        onClose:    _close,
        onItemTap:  _handleItemTap,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────
  void _handleItemTap(int index) {
    _close();
    HapticFeedback.mediumImpact();
    switch (index) {
      case 0:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:        (_, __, ___) => const CreatePostScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 1:
      case 2:
        Get.snackbar(
          'Bientôt disponible',
          '🚧 Cette fonctionnalité arrive prochainement',
          backgroundColor: AppColors.darkGray,
          colorText:       AppColors.pureWhite,
          snackPosition:   SnackPosition.BOTTOM,
          margin:          const EdgeInsets.all(16),
          borderRadius:    12,
          icon: const Icon(Icons.construction, color: AppColors.crimsonRed),
        );
        break;
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:    _toggle,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width:  56,
        height: 60,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _rotationController,
              _pulseAnimation,
            ]),
            builder: (_, child) => Transform.scale(
              scale: _isOpen ? 1.0 : _pulseAnimation.value,
              child: Transform.rotate(
                angle: _rotationController.value * math.pi * 0.625,
                child: child,
              ),
            ),
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C6FFF), Color(0xFFE91E8C)],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color:        const Color(0xFF7C6FFF).withValues(alpha: 0.45),
                    blurRadius:   16,
                    spreadRadius: 0,
                    offset:       const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size:  26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── OVERLAY CONTENT ─────────────────────────────────────────────────
class _OverlayContent extends StatelessWidget {
  final Offset             position;
  final Size               buttonSize;
  final List<_BubbleItem>  items;
  final AnimationController controller;
  final VoidCallback       onClose;
  final void Function(int) onItemTap;

  const _OverlayContent({
    required this.position,
    required this.buttonSize,
    required this.items,
    required this.controller,
    required this.onClose,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final centerX = position.dx + buttonSize.width  / 2;
    final centerY = position.dy + buttonSize.height / 2;

    const angles = [-math.pi * 0.85, -math.pi / 2, -math.pi * 0.15];
    const radius = 90.0;

    return Stack(
      children: [
        // ─ Fond animé ───────────────────────────────────────────────
        Positioned.fill(
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, __) => GestureDetector(
              onTap: onClose,
              child: Container(
                color: Colors.black.withValues(
                    alpha: 0.45 * controller.value),
              ),
            ),
          ),
        ),

        // ─ Bulles ────────────────────────────────────────────────────
        ...items.asMap().entries.map((entry) {
          final i     = entry.key;
          final item  = entry.value;
          final angle = angles[i];

          return AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final curve = CurvedAnimation(
                parent: controller,
                curve:  Interval(
                  i * 0.08,
                  0.55 + i * 0.1,
                  curve: Curves.elasticOut,
                ),
              );

              final opacity = CurvedAnimation(
                parent: controller,
                curve:  Interval(
                  i * 0.08,
                  0.4 + i * 0.08,
                  curve: Curves.easeOut,
                ),
              );

              final bx = centerX +
                  math.cos(angle) * radius * curve.value - 28;
              final by = centerY +
                  math.sin(angle) * radius * curve.value - 28;

              return Positioned(
                left: bx,
                top:  by,
                child: FadeTransition(
                  opacity: opacity,
                  child: _BubbleWidget(
                    item:  item,
                    onTap: () => onItemTap(item.index),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// ─── MODÈLE BULLE ────────────────────────────────────────────────────
class _BubbleItem {
  final IconData icon;
  final String   label;
  final Color    color;
  final int      index;

  const _BubbleItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.index,
  });
}

// ─── WIDGET BULLE ────────────────────────────────────────────────────
class _BubbleWidget extends StatefulWidget {
  final _BubbleItem  item;
  final VoidCallback onTap;

  const _BubbleWidget({required this.item, required this.onTap});

  @override
  State<_BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<_BubbleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double>   _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _pressController.forward(),
      onTapUp:     (_) { _pressController.reverse(); widget.onTap(); },
      onTapCancel: ()  => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (_, child) =>
            Transform.scale(scale: _pressScale.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─ Icône ──────────────────────────────────────────────
            Container(
              width: 46, height: 46, // ✅ Réduit de 52 → 46
              decoration: BoxDecoration(
                color: widget.item.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:        widget.item.color.withValues(alpha: 0.55),
                    blurRadius:   14,
                    spreadRadius: 0,
                    offset:       const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.item.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 4), // ✅ Réduit de 5 → 4

            // ─ Label ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2), // ✅ Réduit
              decoration: BoxDecoration(
                color:        Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Text(
                widget.item.label,
                style: const TextStyle(
                  color:         Colors.white,
                  fontSize:      9, // ✅ Réduit de 10 → 9
                  fontWeight:    FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}