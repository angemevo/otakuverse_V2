import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class AppBottomNav extends StatelessWidget {
  final int               currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_outlined,     activeIcon: Icons.home_rounded,     label: 'AniFeed'),
    _NavItem(icon: Icons.groups_2_outlined, activeIcon: Icons.groups_2_rounded, label: 'Community'),
    _NavItem(icon: Icons.add,               activeIcon: Icons.add,              label: 'Créer'),
    _NavItem(icon: Icons.event_outlined,    activeIcon: Icons.event_rounded,    label: 'Events'),
    _NavItem(icon: Icons.person_outline,    activeIcon: Icons.person_rounded,   label: 'Profil'),
  ];

  // ✅ Keys correspondant à l'index de chaque onglet
  static const _keys = [
    AppKeys.bottomNavFeed,
    AppKeys.bottomNavCommunity,
    AppKeys.bottomNavCreate,
    AppKeys.bottomNavEvents,
    AppKeys.bottomNavProfile,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(
              _items.length,
              // ✅ Key ajoutée sur chaque Expanded
              (i) => Expanded(
                key: _keys[i],
                child: i == 2
                    ? _CreateButton(onTap: () {
                        HapticFeedback.lightImpact();
                        onTap(i);
                      })
                    : _NavTab(
                        item:     _items[i],
                        isActive: currentIndex == i,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap(i);
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Onglet normal ───────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  final _NavItem     item;
  final bool         isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve:    Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:  isActive ? 32 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color:        AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size:  22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTextStyles.navLabel.copyWith(
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bouton Créer ────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42, height: 42,
            decoration: const BoxDecoration(
              gradient:  AppColors.primaryGradient,
              shape:     BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:      Color(0x556C5CE7),
                  blurRadius: 12,
                  offset:     Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded,
                color: AppColors.white, size: 24),
          ),
          const SizedBox(height: 2),
          Text(
            'Créer',
            style: AppTextStyles.navLabel.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Modèle item ─────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
