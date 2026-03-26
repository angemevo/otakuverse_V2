import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/services/connectivity_service.dart';
import 'package:otakuverse/core/services/push_notification_service.dart';
import 'package:otakuverse/core/services/realtime_service.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';
import 'package:otakuverse/features/auth/screens/onboarding_screen.dart';
import 'package:otakuverse/features/stories/controllers/story_controller.dart';
import 'package:otakuverse/firebase_options.dart'; // ✅ Généré par flutterfire
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
  // 1. Toujours en premier
  final widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  // 2. Splash
  FlutterNativeSplash.preserve(
      widgetsBinding: widgetsBinding);

  // 3. Orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 4. Status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:                    Colors.transparent,
      statusBarIconBrightness:           Brightness.light,
      systemNavigationBarColor:          Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 5. Firebase — avec options générées par flutterfire
  print('🔥 Initialisation Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🔥 Firebase initialisé ✅');
  } catch (e) {
    print('🔴 Erreur Firebase : $e');
  }

  // 6. Supabase
  await Supabase.initialize(
    url:     ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );

  // 7. Services globaux
  await Get.putAsync(() async => ConnectivityService());

  // 8. Push notifications — APRÈS Firebase et Supabase
  print('🔔 Initialisation Push Notifications...');
  try {
    await PushNotificationService.initialize();
    print('🔔 Push Notifications initialisé ✅');
  } catch (e) {
    print('🔴 Erreur Push : $e');
  }

  // 9. Spotify
  // await dotenv.load(fileName: '.env');

  // ✅ Enregistrer le RealtimeService
  Get.put(RealtimeService(), permanent: true);
  
  Get.put(StoryController(), permanent: true);
  
  // 10. Retirer le splash
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
      theme:                      _buildTheme(),
      initialRoute:               _initialRoute,
      getPages:                   _pages,

      onInit: () {
        ever(
          Get.find<ConnectivityService>().isConnected,
          (bool connected) {
            if (connected) {
              Get.snackbar(
                '✅ Connexion rétablie',
                'Tu es de nouveau en ligne',
                backgroundColor: AppColors.successGreen
                    .withValues(alpha: 0.9),
                colorText:     Colors.white,
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
        page: () => const Scaffold(
          body: Center(child: Text('Page introuvable')),
        ),
      ),

      defaultTransition:  Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3:            true,
      scaffoldBackgroundColor: AppColors.deepBlack,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.crimsonRed,
        secondary: AppColors.crimsonRed,
        surface:   AppColors.darkGray,
        error:     AppColors.errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor:        AppColors.deepBlack,
        foregroundColor:        AppColors.pureWhite,
        elevation:              0,
        centerTitle:            false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color:      AppColors.pureWhite,
          fontSize:   20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.pureWhite),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkGray,
        contentTextStyle: const TextStyle(
            color: AppColors.pureWhite),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: AppColors.crimsonRed),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimsonRed,
          foregroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color:     Color(0xFF2A2A2A),
        thickness: 1,
      ),
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
      bindings: [
        AuthBinding(),
        FeedBinding(),
      ],
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