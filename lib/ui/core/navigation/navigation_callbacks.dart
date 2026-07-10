import 'package:flutter/material.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';

void navigateToEmailScreen(BuildContext context) {
  Navigator.of(context).pushNamed(AppRouter.email);
}

void handleEmailNavigation({
  required BuildContext context,
  required String email,
  required bool emailExists,
}) {
  if (emailExists) {
    Navigator.of(context).pushNamed(
      AppRouter.loginPassword,
      arguments: {'email': email},
    );
  } else {
    Navigator.of(context).pushNamed(
      AppRouter.createPassword,
      arguments: {'email': email},
    );
  }
}

void navigateToCreateUsernameScreen({
  required BuildContext context,
  required String email,
  required String password,
}) {
  Navigator.of(context).pushNamed(
    AppRouter.createUsername,
    arguments: {
      'email': email,
      'password': password,
    },
  );
}
