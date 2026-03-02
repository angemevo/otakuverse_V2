import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:otakuverse/features/feed/screens/create_post_screen.dart';

class CreatePostButton extends StatefulWidget {
  const CreatePostButton({super.key});

  @override
  State<CreatePostButton> createState() => _CreatePostButtonState();
}

class _CreatePostButtonState extends State<CreatePostButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  final List<_BubbleItem> _items = [
    _BubbleItem(icon: Icons.image_outlined, label: 'Photo', color: const Color(0xFF6C63FF)),
    _BubbleItem(icon: Icons.video_camera_back_outlined, label: 'Vidéo', color: const Color(0xFFE91E8C)),
    _BubbleItem(icon: Icons.auto_stories_outlined, label: 'Story', color: const Color(0xFFFF9800)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    setState(() => _isOpen = true);
    _controller.forward();
    _rotationController.forward();
    _showOverlay();
  }

  void _close() {
    setState(() => _isOpen = false);
    _controller.reverse();
    _rotationController.reverse();
    _removeOverlay();
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Fond transparent pour fermer au tap
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Bulles
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            // Positions en arc au-dessus du bouton
            final angles = [-math.pi / 2, -math.pi * 0.75, -math.pi * 0.25];
            final angle = angles[index];
            const radius = 80.0;

            final centerX = position.dx + size.width / 2;
            final centerY = position.dy + size.height / 2;

            final targetX = centerX + math.cos(angle) * radius - 24;
            final targetY = centerY + math.sin(angle) * radius - 24;

            return AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final curve = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(
                    index * 0.1,
                    0.6 + index * 0.1,
                    curve: Curves.elasticOut,
                  ),
                );

                final currentX = centerX + math.cos(angle) * radius * curve.value - 24;
                final currentY = centerY + math.sin(angle) * radius * curve.value - 24;

                return Positioned(
                  left: currentX,
                  top: currentY,
                  child: Opacity(
                    opacity: _controller.value.clamp(0.0, 1.0),
                    child: _BubbleWidget(
                      item: item,
                      onTap: () {
                        _close();
                        if (index == 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _rotationController,
            builder: (_, child) => Transform.rotate(
              angle: _rotationController.value * math.pi * 0.75,
              child: child,
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFE91E8C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Créer',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// BULLE
// ============================================

class _BubbleItem {
  final IconData icon;
  final String label;
  final Color color;
  const _BubbleItem({required this.icon, required this.label, required this.color});
}

class _BubbleWidget extends StatelessWidget {
  final _BubbleItem item;
  final VoidCallback onTap;

  const _BubbleWidget({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.label,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}