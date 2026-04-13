import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/theme/app_theme.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/services/connectivity_service.dart';
import 'package:otakuverse/core/services/push_notification_service.dart';
import 'package:otakuverse/core/services/realtime_service.dart';
import 'package:otakuverse/features/auth/bindings/auth_binding.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';
import 'package:otakuverse/features/auth/screens/onboarding/onboarding_screen.dart';
import 'package:otakuverse/features/auth/screens/signin_screen.dart';
import 'package:otakuverse/features/auth/screens/signup_screen.dart';
import 'package:otakuverse/features/auth/screens/signup_success_screen.dart';
import 'package:otakuverse/features/feed/bindings/feed_binding.dart';
import 'package:otakuverse/features/navigation/navigation_page.dart';
import 'package:otakuverse/features/stories/controllers/story_controller.dart';
import 'package:otakuverse/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/shared/config/api_config.dart';

void main() async {
  final widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(
      widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:           Colors.transparent,
      statusBarIconBrightness:  Brightness.light,
      // ✅ Aligned avec bgPrimary
      systemNavigationBarColor: Color(0xFF0D0D14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ─ Firebase ────────────────────────────────────────────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase initialisé ✅');
  } catch (e) {
    debugPrint('❌ Firebase : $e');
  }

  // ─ Supabase ────────────────────────────────────────────────────
  await Supabase.initialize(
    url:     ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );

  // ─ Services globaux ────────────────────────────────────────────
  await Get.putAsync(() async => ConnectivityService());

  try {
    await PushNotificationService.initialize();
    debugPrint('🔔 Push Notifications initialisé ✅');
  } catch (e) {
    debugPrint('❌ Push : $e');
  }

  Get.put(RealtimeService(),   permanent: true);
  Get.put(StoryController(),   permanent: true);

  FlutterNativeSplash.remove();
  runApp(const OtakuverseApp());
}

class OtakuverseApp extends StatelessWidget {
  const OtakuverseApp({super.key});

  static String get _initialRoute {
    final session =
        Supabase.instance.client.auth.currentSession;
    return session != null ? Routes.home : Routes.login;
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title:                      'Otakuverse',
      debugShowCheckedModeBanner: false,
      theme:     AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: _initialRoute,
      getPages:     _pages,

      // ✅ Connexion rétablie — couleurs migrées
      onInit: () {
        ever(
          Get.find<ConnectivityService>().isConnected,
          (bool connected) {
            if (connected) {
              Get.snackbar(
                '✅ Connexion rétablie',
                'Tu es de nouveau en ligne',
                backgroundColor: AppColors.success
                    .withValues(alpha: 0.9),
                colorText:     AppColors.white,
                duration:      const Duration(seconds: 3),
                snackPosition: SnackPosition.BOTTOM,
                margin:        const EdgeInsets.all(12),
                borderRadius:  12,
              );
            }
          },
        );
      },

      unknownRoute: GetPage(
        name: '/notfound',
        page: () => Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: Center(
            child: Text('Page introuvable',
                style: TextStyle(
                    color: AppColors.textMuted)),
          ),
        ),
      ),

      defaultTransition:  Transition.fadeIn,
      transitionDuration: const Duration(
          milliseconds: 250),
    );
  }

  List<GetPage> get _pages => [
    GetPage(
      name:    Routes.login,
      page:    () => SignInScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name:    Routes.signup,
      page:    () => SignUpScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name:    Routes.onboarding,
      page:    () => const OnboardingScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OnboardingController());
      }),
    ),
    GetPage(
      name:    Routes.signupSuccess,
      page:    () => const SignupSuccessScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name:     Routes.home,
      page:     () => const NavigationPage(),
      bindings: [AuthBinding(), FeedBinding()],
    ),
  ];
}

abstract class Routes {
  static const login         = '/login';
  static const signup        = '/signup';
  static const onboarding    = '/onboarding';
  static const signupSuccess = '/signup-success';
  static const home          = '/home';
}