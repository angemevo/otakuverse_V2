/// Point d'entrée principal des tests d'intégration.
/// Lance tous les parcours en séquence sur le device connecté.
///
/// Usage :
///   flutter test integration_test/app_test.dart -d R5CNC05Y05J
///
/// Ou test individuel :
///   flutter test integration_test/tests/auth_test.dart -d <device_id>

// ─── Import de tous les groupes de tests ─────────────────────────────
import 'package:integration_test/integration_test.dart';
import 'package:otakuverse/main.dart' as auth;
import 'package:otakuverse/main.dart' as feed;
import 'package:otakuverse/main.dart' as story;
import 'package:otakuverse/main.dart' as message;
import 'package:otakuverse/main.dart' as profile_search;




void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ✅ Ordre d'exécution logique (du plus fondamental au plus avancé)
  auth.main();
  feed.main();
  story.main();
  message.main();
  profile_search.main();
}