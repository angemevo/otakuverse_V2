import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/services/connectivity_service.dart';
import 'package:otakuverse/core/widgets/no_internet_widget.dart';

/// ✅ Wrapper réutilisable sur n'importe quel écran
/// Usage : ConnectivityWrapper(onRetry: () => ..., child: MonEcran())
class ConnectivityWrapper extends StatelessWidget {
  final Widget      child;
  final VoidCallback? onRetry;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();

    return Obx(() {
      if (!connectivity.isConnected.value) {
        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: NoInternetWidget(onRetry: onRetry),
        );
      }
      return child;
    });
  }
}
