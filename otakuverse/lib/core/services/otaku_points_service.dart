import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/core/utils/session_guard.dart';

/// Service OtakuRank — gestion des points côté Flutter.
///
/// Les triggers Supabase gèrent automatiquement :
///   post_created (+10), like_received (+2), comment_created (+3),
///   comment_received (+1), followed_someone (+1), gained_follower (+5),
///   story_created (+5)
///
/// Ce service gère les actions sans trigger :
///   daily_login (+5), watchlist_added (+3), review_written (+15),
///   quiz_completed (+20)
class OtakuPointsService {
  final _supabase = Supabase.instance.client;

  // ─── Table des points ────────────────────────────────────────────
  static const _points = {
    'post_created':      10,
    'like_received':      2,
    'comment_created':    3,
    'comment_received':   1,
    'followed_someone':   1,
    'gained_follower':    5,
    'story_created':      5,
    'quiz_completed':    20,
    'review_written':    15,
    'watchlist_added':    3,
    'daily_login':        5,
  };

  // ─── Attribution via RPC Supabase ────────────────────────────────

  Future<bool> award(String action, {Map<String, dynamic>? meta}) async {
    try {
      final uid = SessionGuard.uid;
      if (uid == null) return false;

      final pts = _points[action];
      if (pts == null) {
        debugPrint('⚠️ OtakuPoints: action inconnue "$action"');
        return false;
      }

      await _supabase.rpc('award_otaku_points', params: {
        'p_user_id': uid,
        'p_action':  action,
        'p_points':  pts,
        if (meta != null) 'p_meta': meta,
      });

      debugPrint('✅ OtakuPoints: +$pts pts ($action)');
      return true;
    } catch (e) {
      debugPrint('❌ OtakuPoints.award error: $e');
      return false;
    }
  }

  // ─── Connexion quotidienne (1 seule fois par jour) ────────────────

  Future<void> onDailyLogin() async {
    try {
      final uid = SessionGuard.uid;
      if (uid == null) return;

      final prefs = await SharedPreferences.getInstance();
      final key   = 'daily_login_$uid';
      final today = _todayKey();

      // ✅ Déjà récompensé aujourd'hui → ignorer
      if (prefs.getString(key) == today) {
        debugPrint('⏭️ OtakuPoints: daily login déjà attribué aujourd\'hui');
        return;
      }

      final ok = await award('daily_login');
      if (ok) {
        await prefs.setString(key, today);
        debugPrint('✅ OtakuPoints: daily login +5 pts');
      }
    } catch (e) {
      debugPrint('❌ OtakuPoints.onDailyLogin error: $e');
    }
  }

  // ─── Actions manuelles ───────────────────────────────────────────

  Future<void> onQuizCompleted(String quizId) =>
      award('quiz_completed', meta: {'quiz_id': quizId});

  Future<void> onReviewWritten(String animeId) =>
      award('review_written', meta: {'anime_id': animeId});

  Future<void> onWatchlistAdded(String animeId) =>
      award('watchlist_added', meta: {'anime_id': animeId});

  // ─── Lecture du rang ─────────────────────────────────────────────

  Future<OtakuRankSnapshot?> getCurrentRank() async {
    try {
      final uid = SessionGuard.uid;
      if (uid == null) return null;

      final data = await _supabase
          .from('profiles')
          .select('otaku_rank, otaku_level, otaku_points')
          .eq('user_id', uid)
          .maybeSingle();

      return data == null ? null : OtakuRankSnapshot.fromJson(data);
    } catch (e) {
      debugPrint('❌ OtakuPoints.getCurrentRank error: $e');
      return null;
    }
  }

  // ─── Historique ──────────────────────────────────────────────────

  Future<List<OtakuPointEntry>> getHistory({int limit = 30}) async {
    try {
      final uid = SessionGuard.uid;
      if (uid == null) return [];

      final data = await _supabase
          .from('otaku_points_log')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List)
          .map((e) => OtakuPointEntry.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('❌ OtakuPoints.getHistory error: $e');
      return [];
    }
  }

  // ─── Utilitaires ─────────────────────────────────────────────────

  /// Clé du jour au format 'YYYY-MM-DD'
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }
}

// ─── Modèles ─────────────────────────────────────────────────────────

class OtakuRankSnapshot {
  final String rank;
  final int    level;
  final int    points;

  const OtakuRankSnapshot({
    required this.rank,
    required this.level,
    required this.points,
  });

  factory OtakuRankSnapshot.fromJson(Map<String, dynamic> j) =>
      OtakuRankSnapshot(
        rank:   j['otaku_rank']   as String? ?? 'Novice',
        level: (j['otaku_level']  as num?)?.toInt() ?? 1,
        points:(j['otaku_points'] as num?)?.toInt() ?? 0,
      );

  // ─── Seuils des rangs ──────────────────────────────────────────

  static const _thresholds = [
    (0,     'Novice'),
    (100,   'Otaku'),
    (500,   'Senpai'),
    (1500,  'Sensei'),
    (4000,  'Mangaka'),
    (10000, 'Kami'),
  ];

  String get nextRank {
    for (int i = 0; i < _thresholds.length - 1; i++) {
      if (points < _thresholds[i + 1].$1) return _thresholds[i + 1].$2;
    }
    return 'Kami';
  }

  int get pointsForNextRank {
    for (final t in _thresholds) {
      if (points < t.$1) return t.$1;
    }
    return points;
  }

  /// Progression vers le rang suivant (0.0 → 1.0)
  double get rankProgress {
    for (int i = 0; i < _thresholds.length - 1; i++) {
      final from = _thresholds[i].$1;
      final to   = _thresholds[i + 1].$1;
      if (points < to) {
        return ((points - from) / (to - from)).clamp(0.0, 1.0);
      }
    }
    return 1.0; // Kami
  }

  bool get isMaxRank => rank == 'Kami';
}

class OtakuPointEntry {
  final String   action;
  final int      points;
  final DateTime createdAt;

  const OtakuPointEntry({
    required this.action,
    required this.points,
    required this.createdAt,
  });

  factory OtakuPointEntry.fromJson(Map<String, dynamic> j) =>
      OtakuPointEntry(
        action:    j['action']     as String,
        points:    j['points']     as int,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  static const _labels = {
    'post_created':     'Post publié',
    'like_received':    'Like reçu',
    'comment_created':  'Commentaire écrit',
    'comment_received': 'Commentaire reçu',
    'followed_someone': 'Abonnement',
    'gained_follower':  'Nouvel abonné',
    'story_created':    'Story publiée',
    'quiz_completed':   'Quiz complété',
    'review_written':   'Avis écrit',
    'watchlist_added':  'Ajout watchlist',
    'daily_login':      'Connexion du jour',
  };

  String get label => _labels[action] ?? action;
}
