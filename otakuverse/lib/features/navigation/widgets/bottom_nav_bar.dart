import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/navigation/widgets/create_post_button.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _navItems = [
    _NavData(icon: HeroiconsOutline.home,            solidIcon: HeroiconsSolid.home,            label: 'Accueil',   index: 0),
    _NavData(icon: HeroiconsOutline.magnifyingGlass, solidIcon: HeroiconsSolid.magnifyingGlass, label: 'Recherche', index: 1),
    _NavData(icon: HeroiconsOutline.heart,           solidIcon: HeroiconsSolid.heart,           label: 'Activité',  index: 3),
    _NavData(icon: HeroiconsOutline.user,            solidIcon: HeroiconsSolid.user,            label: 'Profil',    index: 4),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              ..._navItems.sublist(0, 2).map((item) => Expanded(
                child: _NavItem(
                  data:         item,
                  currentIndex: currentIndex,
                  onTap:        onTap,
                ),
              )),
              const SizedBox(width: 56, child: CreatePostButton()),
              ..._navItems.sublist(2).map((item) => Expanded(
                child: _NavItem(
                  data:         item,
                  currentIndex: currentIndex,
                  onTap:        onTap,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DATA ────────────────────────────────────────────────────────────
class _NavData {
  final IconData icon;
  final IconData solidIcon;
  final String   label;
  final int      index;

  const _NavData({
    required this.icon,
    required this.solidIcon,
    required this.label,
    required this.index,
  });
}

// ─── NAV ITEM ────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final _NavData      data;
  final int           currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.data,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double>   _scaleAnim;

  bool get _isSelected => widget.currentIndex == widget.data.index;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 250),
      value:    _isSelected ? 1.0 : 0.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _isSelected
          ? _controller.forward()
          : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap(widget.data.index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─ Icône ──────────────────────────────────────────────
            Transform.scale(
              scale: _scaleAnim.value,
              child: Icon(
                _isSelected
                    ? widget.data.solidIcon
                    : widget.data.icon,
                color: _isSelected
                    ? AppColors.crimsonRed
                    : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 4),

            // ─ Label ──────────────────────────────────────────────
            Text(
              widget.data.label,
              style: TextStyle(
                fontSize:      10,
                fontWeight:    _isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color:         _isSelected
                    ? AppColors.crimsonRed
                    : Colors.grey[600],
                letterSpacing: 0.2,
              ),
            ),

            // ─ Indicateur ─────────────────────────────────────────
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve:    Curves.easeOutCubic,
              width:    _isSelected ? 16 : 0,
              height:   2.5,
              decoration: BoxDecoration(
                color:        _isSelected
                    ? AppColors.crimsonRed
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: _isSelected
                    ? [
                        BoxShadow(
                          color:      AppColors.crimsonRed
                              .withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}