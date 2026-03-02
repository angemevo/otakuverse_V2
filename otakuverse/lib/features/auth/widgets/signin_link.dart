import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/text_styles.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/features/auth/screens/login_screen.dart';

Widget buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Helpers.navigateTo(SignInScreen());
          },
          child: Text(
            'Se connecter',
            style: AppTextStyles.link
          ),
        ),
      ],
    );
  }