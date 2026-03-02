import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
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