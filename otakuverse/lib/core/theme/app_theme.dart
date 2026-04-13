import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class AppTheme {

  static ThemeData get dark {
    return ThemeData(
      useMaterial3:     true,
      brightness:       Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      primaryColor:     AppColors.primary,
      colorScheme:      _colorScheme,
      textTheme:        _textTheme,
      appBarTheme:      _appBarTheme,
      bottomNavigationBarTheme: _bottomNavTheme,
      elevatedButtonTheme:      _elevatedButtonTheme,
      outlinedButtonTheme:      _outlinedButtonTheme,
      textButtonTheme:          _textButtonTheme,
      inputDecorationTheme:     _inputTheme,
      cardTheme:                _cardTheme,
      chipTheme:                _chipTheme,
      dividerTheme:             _dividerTheme,
      iconTheme:                _iconTheme,
      dialogTheme:              _dialogTheme,
      snackBarTheme:            _snackBarTheme,
      bottomSheetTheme:         _bottomSheetTheme,
      tabBarTheme:              _tabBarTheme,
      progressIndicatorTheme:   _progressTheme,
      switchTheme:              _switchTheme,
      pageTransitionsTheme:     _pageTransitions,
    );
  }

  // ─── COLOR SCHEME ─────────────────────────────────────────────────
  static const ColorScheme _colorScheme = ColorScheme.dark(
    brightness:      Brightness.dark,
    primary:         AppColors.primary,
    onPrimary:       AppColors.white,
    secondary:       AppColors.accent,
    onSecondary:     AppColors.white,
    tertiary:        AppColors.sakura,
    surface:         AppColors.bgCard,
    onSurface:       AppColors.textPrimary,
    error:           AppColors.error,
    onError:         AppColors.white,
    outline:         AppColors.border,
    outlineVariant:  AppColors.borderLight,
  );

  // ─── TEXT THEME ───────────────────────────────────────────────────
  static TextTheme get _textTheme => TextTheme(
    displayLarge:  AppTextStyles.display1,
    displayMedium: AppTextStyles.display2,
    displaySmall:  AppTextStyles.display3,
    headlineLarge: AppTextStyles.h1,
    headlineMedium: AppTextStyles.h2,
    headlineSmall: AppTextStyles.h3,
    titleLarge:    AppTextStyles.h4,
    titleMedium:   AppTextStyles.bodySemiBold,
    titleSmall:    AppTextStyles.labelLarge,
    bodyLarge:     AppTextStyles.bodyLarge,
    bodyMedium:    AppTextStyles.body,
    bodySmall:     AppTextStyles.bodySmall,
    labelLarge:    AppTextStyles.button,
    labelMedium:   AppTextStyles.label,
    labelSmall:    AppTextStyles.caption,
  );

  // ─── APP BAR ──────────────────────────────────────────────────────
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor:  AppColors.bgPrimary,
    foregroundColor:  AppColors.textPrimary,
    elevation:        0,
    scrolledUnderElevation: 0,
    centerTitle:      false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor:           Colors.transparent,
      statusBarIconBrightness:  Brightness.light,
      statusBarBrightness:      Brightness.dark,
    ),
    iconTheme: IconThemeData(
      color: AppColors.textPrimary,
      size:  24,
    ),
  );

  // ─── BOTTOM NAV ───────────────────────────────────────────────────
  static final BottomNavigationBarThemeData _bottomNavTheme =
      BottomNavigationBarThemeData(
    backgroundColor:      AppColors.bgCard,
    selectedItemColor:    AppColors.primary,
    unselectedItemColor:  AppColors.textMuted,
    selectedLabelStyle:   AppTextStyles.navLabel.copyWith(
        color: AppColors.primary),
    unselectedLabelStyle: AppTextStyles.navLabel.copyWith(
        color: AppColors.textMuted),
    type:                 BottomNavigationBarType.fixed,
    elevation:            0,
    showSelectedLabels:   true,
    showUnselectedLabels: true,
  );

  // ─── ELEVATED BUTTON ─────────────────────────────────────────────
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor:  AppColors.primary,
      foregroundColor:  AppColors.white,
      disabledBackgroundColor:
          AppColors.primary.withValues(alpha: 0.4),
      elevation:        0,
      shadowColor:      Colors.transparent,
      padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      textStyle: AppTextStyles.button,
    ),
  );

  // ─── OUTLINED BUTTON ─────────────────────────────────────────────
  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(
          color: AppColors.primary, width: 1.5),
      padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      textStyle: AppTextStyles.button,
    ),
  );

  // ─── TEXT BUTTON ──────────────────────────────────────────────────
  static final TextButtonThemeData _textButtonTheme =
      TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      textStyle: AppTextStyles.button,
    ),
  );

  // ─── INPUT ────────────────────────────────────────────────────────
  static final InputDecorationTheme _inputTheme =
      InputDecorationTheme(
    filled:    true,
    fillColor: AppColors.bgCard,
    hintStyle: AppTextStyles.inputHint,
    labelStyle: AppTextStyles.inputLabel,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:   BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:   BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
          color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
          color: AppColors.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
          color: AppColors.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
    prefixIconColor: AppColors.textMuted,
    suffixIconColor: AppColors.textMuted,
  );

  // ─── CARD ─────────────────────────────────────────────────────────
  static final CardThemeData _cardTheme = CardThemeData(
    color:       AppColors.bgCard,
    elevation:   0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(
          color: AppColors.border, width: 0.5),
    ),
    margin: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 6),
  );

  // ─── CHIP ─────────────────────────────────────────────────────────
  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor:  AppColors.bgElevated,
    selectedColor:    AppColors.primary,
    disabledColor:    AppColors.bgCard,
    labelStyle:       AppTextStyles.label.copyWith(
        color: AppColors.textSecondary),
    secondaryLabelStyle: AppTextStyles.label.copyWith(
        color: AppColors.white),
    side: const BorderSide(
        color: AppColors.border, width: 0.5),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(
        horizontal: 10, vertical: 4),
  );

  // ─── DIVIDER ─────────────────────────────────────────────────────
  static const DividerThemeData _dividerTheme = DividerThemeData(
    color:   AppColors.border,
    thickness: 0.5,
    space:   1,
  );

  // ─── ICON ─────────────────────────────────────────────────────────
  static const IconThemeData _iconTheme = IconThemeData(
    color: AppColors.textSecondary,
    size:  24,
  );

  // ─── DIALOG ───────────────────────────────────────────────────────
  static final DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.bgSheet,
    elevation:       0,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
    titleTextStyle:   AppTextStyles.h3,
    contentTextStyle: AppTextStyles.body,
  );

  // ─── SNACKBAR ─────────────────────────────────────────────────────
  static final SnackBarThemeData _snackBarTheme =
      SnackBarThemeData(
    backgroundColor: AppColors.bgElevated,
    contentTextStyle: AppTextStyles.body.copyWith(
        color: AppColors.textPrimary),
    behavior:     SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
    elevation: 4,
  );

  // ─── BOTTOM SHEET ────────────────────────────────────────────────
  static final BottomSheetThemeData _bottomSheetTheme =
      BottomSheetThemeData(
    backgroundColor:    AppColors.bgSheet,
    modalBackgroundColor: AppColors.bgSheet,
    elevation:          0,
    modalElevation:     0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
          top: Radius.circular(24)),
    ),
    dragHandleColor: AppColors.borderLight,
    dragHandleSize:  const Size(40, 4),
  );

  // ─── TAB BAR ─────────────────────────────────────────────────────
  static final TabBarThemeData _tabBarTheme = TabBarThemeData(
    labelColor:         AppColors.primary,
    unselectedLabelColor: AppColors.textMuted,
    labelStyle:         AppTextStyles.labelLarge.copyWith(
        color: AppColors.primary),
    unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textMuted),
    indicatorColor:     AppColors.primary,
    indicatorSize:      TabBarIndicatorSize.label,
    dividerColor:       Colors.transparent,
  );

  // ─── PROGRESS ────────────────────────────────────────────────────
  static const ProgressIndicatorThemeData _progressTheme =
      ProgressIndicatorThemeData(
    color:            AppColors.primary,
    linearTrackColor: AppColors.border,
    circularTrackColor: AppColors.border,
  );

  // ─── SWITCH ──────────────────────────────────────────────────────
  static final SwitchThemeData _switchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.textMuted;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary.withValues(alpha: 0.3);
      }
      return AppColors.bgElevated;
    }),
  );

  // ─── PAGE TRANSITIONS ────────────────────────────────────────────
  static const PageTransitionsTheme _pageTransitions =
      PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
    },
  );
}