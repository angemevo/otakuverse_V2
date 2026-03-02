// lib/core/utils/date_formatter.dart
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Utilitaires pour formater les dates et heures
class DateFormatter {
  // Configuration de la locale française pour timeago
  static void setupFrenchLocale() {
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }
  
  // ============================================
  // TIMEAGO (il y a X minutes/heures/jours)
  // ============================================
  
  /// Afficher "il y a X minutes"
  static String timeAgo(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'fr');
  }
  
  /// Timeago avec limite (après 7 jours, afficher la date)
  static String timeAgoWithLimit(DateTime dateTime, {int dayLimit = 7}) {
    final difference = DateTime.now().difference(dateTime).inDays;
    
    if (difference > dayLimit) {
      return formatDate(dateTime);
    }
    
    return timeAgo(dateTime);
  }
  
  // ============================================
  // FORMAT SIMPLE
  // ============================================
  
  /// Format: 27 janv. 2026
  static String formatDate(DateTime dateTime) {
    return DateFormat('d MMM yyyy', 'fr_FR').format(dateTime);
  }
  
  /// Format: 14:30
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  /// Format: 27/01/2026 14:30
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  
  /// Format: Mardi 27 janvier 2026
  static String formatFullDate(DateTime dateTime) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(dateTime);
  }
  
  /// Format: Mardi 27 janvier
  static String formatDateWithoutYear(DateTime dateTime) {
    return DateFormat('EEEE d MMMM', 'fr_FR').format(dateTime);
  }
  
  /// Format: 27 jan
  static String formatShortDate(DateTime dateTime) {
    return DateFormat('d MMM', 'fr_FR').format(dateTime);
  }
  
  // ============================================
  // FORMAT CHAT/MESSAGES
  // ============================================
  
  /// Format pour messages (intelligent selon l'ancienneté)
  static String formatMessageDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24 && dateTime.day == now.day) {
      return formatTime(dateTime);
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'fr_FR').format(dateTime);
    } else if (dateTime.year == now.year) {
      return formatShortDate(dateTime);
    } else {
      return formatDate(dateTime);
    }
  }
  
  // ============================================
  // FORMAT POST/SHORT
  // ============================================
  
  /// Format pour posts (timeago jusqu'à 24h, puis date)
  static String formatPostDate(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inHours < 24) {
      return timeAgo(dateTime);
    } else if (difference.inDays < 7) {
      return '${difference.inDays} j';
    } else {
      return formatShortDate(dateTime);
    }
  }
  
  // ============================================
  // FORMAT ÉVÉNEMENT
  // ============================================
  
  /// Format pour événement
  /// Ex: "Aujourd'hui à 14:30", "Demain à 14:30", "27 janv. à 14:30"
  static String formatEventDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (eventDate == today) {
      return 'Aujourd\'hui à ${formatTime(dateTime)}';
    } else if (eventDate == tomorrow) {
      return 'Demain à ${formatTime(dateTime)}';
    } else if (eventDate.difference(today).inDays < 7) {
      return '${DateFormat('EEEE', 'fr_FR').format(dateTime)} à ${formatTime(dateTime)}';
    } else {
      return '${formatShortDate(dateTime)} à ${formatTime(dateTime)}';
    }
  }
  
  /// Format plage d'événement
  /// Ex: "27 janv. 14:00 - 18:00"
  static String formatEventRange(DateTime start, DateTime end) {
    if (start.day == end.day && start.month == end.month && start.year == end.year) {
      return '${formatShortDate(start)} ${formatTime(start)} - ${formatTime(end)}';
    } else {
      return '${formatDateTime(start)} - ${formatDateTime(end)}';
    }
  }
  
  // ============================================
  // DURÉE
  // ============================================
  
  /// Formater une durée en secondes → "2h 30min"
  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return remainingSeconds > 0 
          ? '${minutes}min ${remainingSeconds}s'
          : '${minutes}min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 
          ? '${hours}h ${minutes}min'
          : '${hours}h';
    }
  }
  
  /// Formater durée courte → "2:30" (pour vidéos)
  static String formatVideoDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // ============================================
  // RELATIF (dans X jours)
  // ============================================
  
  /// Afficher "dans X jours"
  static String formatUpcoming(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inMinutes < 0) {
      return 'Passé';
    } else if (difference.inMinutes < 60) {
      return 'Dans ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Dans ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Demain';
    } else if (difference.inDays < 7) {
      return 'Dans ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Dans $weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      return formatDate(dateTime);
    }
  }
  
  // ============================================
  // HELPERS
  // ============================================
  
  /// Vérifier si c'est aujourd'hui
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }
  
  /// Vérifier si c'est hier
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
           dateTime.month == yesterday.month &&
           dateTime.day == yesterday.day;
  }
  
  /// Vérifier si c'est cette semaine
  static bool isThisWeek(DateTime dateTime) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return dateTime.isAfter(startOfWeek) && dateTime.isBefore(endOfWeek);
  }
  
  /// Obtenir le début de la journée
  static DateTime getStartOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
  
  /// Obtenir la fin de la journée
  static DateTime getEndOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59);
  }
  
  /// Calculer l'âge depuis une date de naissance
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
}
