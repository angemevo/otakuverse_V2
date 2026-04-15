import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/widgets/app_bottom_nav.dart';
import 'package:otakuverse/core/widgets/app_bar_widget.dart';
import 'package:otakuverse/features/feed/screens/home/home_screen.dart';
import 'package:otakuverse/features/feed/screens/media/media_picker_screen.dart';
import 'package:otakuverse/features/message/screens/messages_screen.dart';
import 'package:otakuverse/features/profile/screens/profile_screen.dart';
import 'package:otakuverse/features/search/screens/search_screen.dart';
import 'package:otakuverse/features/stories/screens/create_story/create_story_screen.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() =>
      _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _currentIndex = 0;

  // ✅ Pages — Community et Events = placeholders Sprint 4 & 5
  static final _pages = [
    const HomeScreen(),
    const _ComingSoon(label: 'Community',    icon: Icons.groups_2_rounded),
    const SizedBox.shrink(), // Create — géré par bottom nav
    const _ComingSoon(label: 'Events',       icon: Icons.event_rounded),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,

      // ✅ App bar avec Discover + Notifications
      appBar: _currentIndex == 4
          ? null  // Profil gère son propre app bar
          : OtakuverseAppBar(
              onSearch:   () => Get.to(() => const SearchScreen()),
              onMessages: () => Get.to(() => const MessagesScreen()),
            ),

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // ✅ Bouton créer → sheet de choix
            _showCreateSheet();
            return;
          }
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  // ─── SHEET CRÉER ─────────────────────────────────────────────────
  void _showCreateSheet() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppColors.bgSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Que veux-tu créer ?',
                  style: AppTextStyles.h3),
              const SizedBox(height: 20),
              Row(
                children: [
                  _CreateOption(
                    icon:  Icons.image_outlined,
                    label: 'Post',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const MediaPickerScreen()));
                    },
                  ),
                  _CreateOption(
                    icon:  Icons.auto_stories_outlined,
                    label: 'Story',
                    color: AppColors.sakura,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const CreateStoryScreen()));
                    },
                  ),
                  _CreateOption(
                    icon:  Icons.rate_review_outlined,
                    label: 'Avis',
                    color: AppColors.gold,
                    onTap: () {
                      Navigator.pop(context);
                      Get.snackbar(
                        'Bientôt disponible 🎯',
                        'Les avis arrivent prochainement',
                        backgroundColor: AppColors.bgCard,
                        colorText:       AppColors.textPrimary,
                        snackPosition:   SnackPosition.BOTTOM,
                        margin:          const EdgeInsets.all(16),
                        borderRadius:    12,
                      );
                    },
                  ),
                  _CreateOption(
                    icon:  Icons.videocam_outlined,
                    label: 'Clip',
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.pop(context);
                      Get.snackbar(
                        'Bientôt disponible 🎬',
                        'Les Clips arrivent prochainement',
                        backgroundColor: AppColors.bgCard,
                        colorText:       AppColors.textPrimary,
                        snackPosition:   SnackPosition.BOTTOM,
                        margin:          const EdgeInsets.all(16),
                        borderRadius:    12,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CREATE OPTION ───────────────────────────────────────────────────
class _CreateOption extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    ),
  );
}

// ─── PLACEHOLDER ─────────────────────────────────────────────────────
class _ComingSoon extends StatelessWidget {
  final String   label;
  final IconData icon;
  const _ComingSoon({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 56),
        const SizedBox(height: 16),
        Text(label, style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          'Disponible au Sprint ${label == "Community" ? 4 : 5}',
          style: AppTextStyles.bodySmall,
        ),
      ],
    ),
  );
}