import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';
import 'package:otakuverse/features/auth/screens/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/shared/config/api_config.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/auth/bindings/auth_binding.dart';
import 'package:otakuverse/features/auth/screens/login_screen.dart';
import 'package:otakuverse/features/auth/screens/signup_screen.dart';
import 'package:otakuverse/features/auth/screens/signup_success_screen.dart';
import 'package:otakuverse/features/feed/bindings/feed_binding.dart';
import 'package:otakuverse/features/navigation/navigation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', '');

  // ─── Orientation portrait uniquement ──────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ─── Style de la barre de statut ──────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ─── Initialisation Supabase ──────────────────────────────────────
  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );

  runApp(const OtakuverseApp());
}

class OtakuverseApp extends StatelessWidget {
  const OtakuverseApp({super.key});

  // ─── Écran de départ selon session active ─────────────────────────
  static String get _initialRoute {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null ? Routes.home : Routes.login;
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Otakuverse',
      debugShowCheckedModeBanner: false,

      // ─── Thème ──────────────────────────────────────────────────
      theme: _buildTheme(),

      // ─── Navigation ─────────────────────────────────────────────
      initialRoute: _initialRoute,
      getPages: _pages,

      // ─── Transitions globales ────────────────────────────────────
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  // ─── THÈME ────────────────────────────────────────────────────────
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.deepBlack,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.crimsonRed,
        secondary: AppColors.crimsonRed,
        surface:   AppColors.darkGray,
        error:     AppColors.errorRed,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepBlack,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.pureWhite),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkGray,
        contentTextStyle: const TextStyle(color: AppColors.pureWhite),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.crimsonRed,
        ),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimsonRed,
          foregroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(52),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A2A),
        thickness: 1,
      ),
    );
  }

  // ─── ROUTES ───────────────────────────────────────────────────────
  List<GetPage> get _pages => [
    GetPage(
      name: Routes.login,
      page: () => SignInScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.signup,
      page: () => SignUpScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OnboardingController());
      }),
    ),
    GetPage(
      name: Routes.signupSuccess,
      page: () => const SignupSuccessScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const NavigationPage(),
      bindings: [
        AuthBinding(),
        FeedBinding(),
      ],
    ),
  ];
}

// ─── ROUTES CONSTANTES ────────────────────────────────────────────────
abstract class Routes {
  static const login         = '/login';
  static const signup        = '/signup';
  static const onboarding = '/onboarding';
  static const signupSuccess = '/signup-success';
  static const home          = '/home';
}