import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/colors.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Page pas encore developpé veuillez attendre la prochaine mise à jour',
          style: TextStyle(
            color: AppColors.lightGray
          ),
        )
      ),
    );
  }
}