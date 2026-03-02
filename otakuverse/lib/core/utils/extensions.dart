// lib/core/utils/extensions.dart
import 'package:flutter/material.dart';
// Import nécessaire pour pow
import 'dart:math';

/// Extensions utiles pour Otakuverse

// ============================================
// STRING EXTENSIONS
// ============================================

extension StringExtension on String {
  /// Capitaliser la première lettre
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Capitaliser chaque mot
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
  
  /// Vérifier si c'est un email valide
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }
  
  /// Vérifier si c'est un username valide
  bool get isValidUsername {
    return RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(this);
  }
  
  /// Vérifier si c'est une URL valide
  bool get isValidUrl {
    return RegExp(r'https?://[^\s]+').hasMatch(this);
  }
  
  /// Extraire les hashtags
  List<String> get hashtags {
    final regex = RegExp(r'#(\w+)');
    return regex.allMatches(this).map((m) => m.group(1)!).toList();
  }
  
  /// Extraire les mentions
  List<String> get mentions {
    final regex = RegExp(r'@(\w+)');
    return regex.allMatches(this).map((m) => m.group(1)!).toList();
  }
  
  /// Extraire les URLs
  List<String> get urls {
    final regex = RegExp(r'https?://[^\s]+');
    return regex.allMatches(this).map((m) => m.group(0)!).toList();
  }
  
  /// Tronquer avec ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }
  
  /// Retirer les espaces multiples
  String removeExtraSpaces() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  
  /// Vérifier si contient uniquement des chiffres
  bool get isNumeric {
    return RegExp(r'^\d+$').hasMatch(this);
  }
  
  /// Convertir en slug (pour URLs)
  String toSlug() {
    return toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

// ============================================
// INT EXTENSIONS
// ============================================

extension IntExtension on int {
  /// Formater en K/M (1000 → 1K)
  String toCompactString() {
    if (this < 1000) {
      return toString();
    } else if (this < 1000000) {
      final value = this / 1000;
      return value % 1 == 0 
          ? '${value.toInt()}K'
          : '${value.toStringAsFixed(1)}K';
    } else {
      final value = this / 1000000;
      return value % 1 == 0
          ? '${value.toInt()}M'
          : '${value.toStringAsFixed(1)}M';
    }
  }
  
  /// Formater avec séparateurs de milliers
  String toFormattedString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
  
  /// Vérifier si c'est pair
  bool get isEven => this % 2 == 0;
  
  /// Vérifier si c'est impair
  bool get isOdd => this % 2 != 0;
  
  /// Convertir en durée lisible (secondes → "2h 30min")
  String toDurationString() {
    if (this < 60) {
      return '${this}s';
    } else if (this < 3600) {
      final minutes = this ~/ 60;
      final seconds = this % 60;
      return seconds > 0 ? '${minutes}min ${seconds}s' : '${minutes}min';
    } else {
      final hours = this ~/ 3600;
      final minutes = (this % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    }
  }
}

// ============================================
// DOUBLE EXTENSIONS
// ============================================

extension DoubleExtension on double {
  /// Arrondir à N décimales
  double roundToDecimals(int decimals) {
    final factor = pow(10, decimals).toDouble();
    return (this * factor).round() / factor;
  }
  
  /// Formater en pourcentage
  String toPercentString({int decimals = 0}) {
    return '${(this * 100).toStringAsFixed(decimals)}%';
  }
}

// ============================================
// DATETIME EXTENSIONS
// ============================================

extension DateTimeExtension on DateTime {
  /// Vérifier si c'est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Vérifier si c'est hier
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }
  
  /// Vérifier si c'est demain
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && 
           month == tomorrow.month && 
           day == tomorrow.day;
  }
  
  /// Obtenir le début de la journée (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }
  
  /// Obtenir la fin de la journée (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }
  
  /// Obtenir le début de la semaine (lundi)
  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }
  
  /// Obtenir la fin de la semaine (dimanche)
  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday)).endOfDay;
  }
  
  /// Calculer l'âge
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    
    return age;
  }
  
  /// Vérifier si c'est dans le passé
  bool get isPast => isBefore(DateTime.now());
  
  /// Vérifier si c'est dans le futur
  bool get isFuture => isAfter(DateTime.now());
}

// ============================================
// LIST EXTENSIONS
// ============================================

extension ListExtension<T> on List<T> {
  /// Obtenir un élément ou null si hors limites
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  /// Diviser en chunks
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
  
  /// Mélanger aléatoirement
  List<T> shuffled() {
    final list = List<T>.from(this);
    list.shuffle();
    return list;
  }
  
  /// Retirer les doublons
  List<T> distinct() {
    return toSet().toList();
  }
}

// ============================================
// BUILDCONTEXT EXTENSIONS
// ============================================

extension BuildContextExtension on BuildContext {
  /// Obtenir la hauteur de l'écran
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Obtenir la largeur de l'écran
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Obtenir le padding du safe area
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
  
  /// Vérifier si c'est un mobile
  bool get isMobile => screenWidth < 600;
  
  /// Vérifier si c'est une tablette
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  
  /// Vérifier si c'est un desktop
  bool get isDesktop => screenWidth >= 900;
  
  /// Obtenir le thème
  ThemeData get theme => Theme.of(this);
  
  /// Obtenir les couleurs du thème
  ColorScheme get colors => theme.colorScheme;
  
  /// Vérifier si c'est le mode sombre
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Obtenir le TextTheme
  TextTheme get textTheme => theme.textTheme;
  
  /// Cacher le clavier
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
  
  /// Afficher le clavier sur un focus node
  void showKeyboard(FocusNode focusNode) {
    FocusScope.of(this).requestFocus(focusNode);
  }
}

// ============================================
// WIDGET EXTENSIONS
// ============================================

extension WidgetExtension on Widget {
  /// Ajouter du padding
  Widget paddingAll(double value) {
    return Padding(
      padding: EdgeInsets.all(value),
      child: this,
    );
  }
  
  /// Ajouter du padding symétrique
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: this,
    );
  }
  
  /// Ajouter du padding uniquement à gauche/droite/haut/bas
  Widget paddingOnly({
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
      ),
      child: this,
    );
  }
  
  /// Rendre cliquable avec tap callback
  Widget onTap(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: this,
    );
  }
  
  /// Centrer le widget
  Widget get centered {
    return Center(child: this);
  }
  
  /// Aligner à gauche
  Widget get alignLeft {
    return Align(alignment: Alignment.centerLeft, child: this);
  }
  
  /// Aligner à droite
  Widget get alignRight {
    return Align(alignment: Alignment.centerRight, child: this);
  }
  
  /// Expanded
  Widget get expanded {
    return Expanded(child: this);
  }
  
  /// Flexible
  Widget flexible({int flex = 1}) {
    return Flexible(flex: flex, child: this);
  }
  
  /// Ajouter une marge
  Widget marginAll(double value) {
    return Container(
      margin: EdgeInsets.all(value),
      child: this,
    );
  }
  
  /// Visibility conditionnelle
  Widget visible(bool visible) {
    return Visibility(
      visible: visible,
      child: this,
    );
  }
  
  /// Opacité
  Widget opacity(double opacity) {
    return Opacity(
      opacity: opacity,
      child: this,
    );
  }
}

// ============================================
// COLOR EXTENSIONS
// ============================================

extension ColorExtension on Color {
  /// Obtenir la couleur avec opacité
  Color withOpacityValue(double opacity) {
    return withOpacity(opacity);
  }
  
  /// Obtenir la version plus claire
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    
    return hslLight.toColor();
  }
  
  /// Obtenir la version plus foncée
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    
    return hslDark.toColor();
  }
  
  /// Convertir en hex string
  String toHex() {
    return '#${value.toRadixString(16).substring(2).toUpperCase()}';
  }
}


