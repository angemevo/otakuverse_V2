import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ Vérifier au démarrage
    _checkConnectivity();
    // ✅ Écouter les changements en temps réel
    Connectivity().onConnectivityChanged.listen(
      _updateStatus,
    );
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    isConnected.value = results.any(
      (r) => r != ConnectivityResult.none,
    );
  }

  // ✅ Utilisable partout dans l'app
  static bool get connected =>
      Get.find<ConnectivityService>().isConnected.value;
}
