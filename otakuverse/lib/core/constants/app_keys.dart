import 'package:flutter/widgets.dart';

/// Clés de widgets pour les tests d'intégration.
/// Définies ici (lib/core/constants/) pour éviter d'importer
/// integration_test/ dans le code de production.
abstract class AppKeys {
  // ─── Auth ──────────────────────────────────────────────────────
  static const emailField    = Key('auth_email_field');
  static const passwordField = Key('auth_password_field');
  static const loginButton   = Key('auth_login_button');
  static const signupButton  = Key('auth_signup_button');
  static const logoutButton  = Key('auth_logout_button');

  // ─── Navigation ────────────────────────────────────────────────
  static const bottomNavFeed      = Key('nav_feed');
  static const bottomNavCommunity = Key('nav_community');
  static const bottomNavCreate    = Key('nav_create');
  static const bottomNavEvents    = Key('nav_events');
  static const bottomNavProfile   = Key('nav_profile');

  // ─── Feed ──────────────────────────────────────────────────────
  static const feedList       = Key('feed_list');
  static const likeButton     = Key('post_like_button');
  static const commentButton  = Key('post_comment_button');
  static const bookmarkButton = Key('post_bookmark_button');
  static const commentInput   = Key('comment_input');
  static const commentSend    = Key('comment_send_button');

  // ─── Create post ───────────────────────────────────────────────
  static const captionInput    = Key('create_post_caption');
  static const sharePostButton = Key('create_post_share');

  // ─── Stories ───────────────────────────────────────────────────
  static const storiesRow     = Key('stories_row');
  static const addStoryButton = Key('add_story_button');

  // ─── Profil ────────────────────────────────────────────────────
  static const editProfileButton = Key('edit_profile_button');
  static const displayNameInput  = Key('edit_display_name');
  static const saveProfileButton = Key('edit_profile_save');

  // ─── Recherche ─────────────────────────────────────────────────
  static const searchField  = Key('search_field');
  static const followButton = Key('follow_button');

  // ─── Messagerie ────────────────────────────────────────────────
  static const newConvButton = Key('new_conversation_button');
  static const chatInput     = Key('chat_input');
  static const chatSend      = Key('chat_send_button');
}
