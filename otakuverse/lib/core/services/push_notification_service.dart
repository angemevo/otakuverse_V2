import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Handler background — DOIT être top-level (hors de toute classe)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Notification background : ${message.messageId}');
}

class PushNotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _supabase  = Supabase.instance.client;

  // ─── INITIALISATION ──────────────────────────────────────────────
  static Future<void> initialize() async {
    // ✅ Handler background
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // ✅ Demander la permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert:         true,
      badge:         true,
      sound:         true,
      announcement:  false,
      carPlay:       false,
      criticalAlert: false,
      provisional:   false,
    );

    print('🔔 Permission : ${settings.authorizationStatus}');

    if (settings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      await _setupToken();
      _setupForegroundHandler();
      _setupOpenedAppHandler();
    }
  }

  // ─── TOKEN FCM ───────────────────────────────────────────────────
  static Future<void> _setupToken() async {
    // ✅ Récupérer le token FCM
    final token = await _messaging.getToken();

    print('🔑 TOKEN FCM : $token');
    
    if (token != null) {
      await _saveTokenToSupabase(token);
    }

    // ✅ Écouter les renouvellements de token
    _messaging.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  // ─── SAUVEGARDER TOKEN EN DB ─────────────────────────────────────
  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId =
          _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('fcm_tokens').upsert({
        'user_id':    userId,
        'token':      token,
        'platform':   GetPlatform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      print('✅ Token FCM sauvegardé');
    } catch (e) {
      print('🔴 Erreur save token : $e');
    }
  }

  // ─── NOTIFICATION EN PREMIER PLAN ────────────────────────────────
  static void _setupForegroundHandler() {
    // ✅ Afficher les notifications quand l'app est ouverte
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Notification foreground : ${message.messageId}');

      final notification = message.notification;
      if (notification == null) return;

      // ✅ Snackbar GetX en foreground
      Get.snackbar(
        notification.title ?? 'Otakuverse',
        notification.body  ?? '',
        backgroundColor: AppColors.bgCard
            .withValues(alpha: 0.95),
        colorText:     Colors.white,
        duration:      const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin:        const EdgeInsets.all(12),
        borderRadius:  12,
        icon: const Icon(
          Icons.notifications,
          color: AppColors.primary,
        ),
        onTap: (_) => _handleNotificationTap(message.data),
      );
    });
  }

  // ─── APP OUVERTE DEPUIS NOTIFICATION ─────────────────────────────
  static void _setupOpenedAppHandler() {
    // ✅ App en background → ouverte via notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📩 App ouverte via notification');
      _handleNotificationTap(message.data);
    });

    // ✅ App terminée → ouverte via notification
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });
  }

  // ─── NAVIGATION SELON TYPE ────────────────────────────────────────
  static void _handleNotificationTap(
      Map<String, dynamic> data) {
    final type   = data['type']    as String?;
    final postId = data['post_id'] as String?;
    final userId = data['user_id'] as String?;

    switch (type) {
      case 'like':
      case 'comment':
      case 'reply':
        if (postId != null) {
          // ✅ Naviguer vers le post
          Get.toNamed('/home',
              arguments: {'openPost': postId});
        }
        break;
      case 'follow':
        if (userId != null) {
          // ✅ Naviguer vers le profil
          Get.toNamed('/home',
              arguments: {'openProfile': userId});
        }
        break;
    }
  }

  // ─── SUPPRIMER TOKEN (déconnexion) ───────────────────────────────
  static Future<void> deleteToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _messaging.deleteToken();
      await _supabase
          .from('fcm_tokens')
          .delete()
          .eq('user_id', userId);

      print('✅ Token FCM supprimé');
    } catch (e) {
      print('🔴 Erreur delete token : $e');
    }
  }
}