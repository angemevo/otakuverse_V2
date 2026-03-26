import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/notification/screens/notification_screen.dart';
import 'package:otakuverse/features/community/screens/community_screen.dart';
import 'package:otakuverse/features/feed/screens/home_screen.dart';
import 'package:otakuverse/features/navigation/widgets/bottom_nav_bar.dart';
import 'package:otakuverse/features/profile/screens/profile_screen.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _currentIndex = 0;

  // ✅ Un NavigatorKey par tab
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Tab 0 — Accueil
    GlobalKey<NavigatorState>(), // Tab 1 — Recherche
    GlobalKey<NavigatorState>(), // Tab 2 — Activité
    GlobalKey<NavigatorState>(), // Tab 3 — Profil
  ];

  // ✅ Mapping index BottomNav → index tab
  // BottomNav : 0=Accueil, 1=Recherche, 2=Créer(ignoré), 3=Activité, 4=Profil
  int _navIndexToTabIndex(int navIndex) {
    switch (navIndex) {
      case 0: return 0;
      case 1: return 1;
      case 3: return 2;
      case 4: return 3;
      default: return 0;
    }
  }

  int get _currentTabIndex => _navIndexToTabIndex(_currentIndex);

  // ✅ Bouton retour Android
  Future<bool> _onWillPop() async {
    final nav = _navigatorKeys[_currentTabIndex].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    return true;
  }

  void _onNavTap(int navIndex) {
    if (navIndex == 2) return; // CreatePostButton

    final tabIndex = _navIndexToTabIndex(navIndex);

    // ✅ Double tap → retour à la racine du tab
    if (navIndex == _currentIndex) {
      _navigatorKeys[tabIndex]
          .currentState
          ?.popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _currentIndex = navIndex);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Stack(
          children: [
            _buildTab(0, const HomeScreen()),
            _buildTab(1, const CommunityScreen()),
            _buildTab(2, const NotificationScreen()),
            _buildTab(3, const ProfileScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap:        _onNavTap,
        ),
      ),
    );
  }

  Widget _buildTab(int tabIndex, Widget screen) {
    return Offstage(
      offstage: _currentTabIndex != tabIndex,
      child: Navigator(
        key: _navigatorKeys[tabIndex],
        // ✅ Pas de conflit avec GetMaterialApp router
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder:  (_) => screen,
        ),
      ),
    );
  }
}