import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Repositories
import 'package:colonia_front_app/data/repositories/auth_repository.dart';

// ViewModels
import 'package:colonia_front_app/ui/auth/view_models/welcome_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/view_models/email_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/view_models/login_password_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/view_models/create_password_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/view_models/create_username_viewmodel.dart';

// Screens
import 'package:colonia_front_app/ui/auth/widgets/welcome_screen.dart';
import 'package:colonia_front_app/ui/auth/widgets/email_screen.dart';
import 'package:colonia_front_app/ui/auth/widgets/login_password_screen.dart';
import 'package:colonia_front_app/ui/auth/widgets/create_password_screen.dart';
import 'package:colonia_front_app/ui/auth/widgets/create_username_screen.dart';

class AppRouter {
  static const String welcome = '/';
  static const String email = '/email';
  static const String loginPassword = '/login_password';
  static const String createPassword = '/create_password';
  static const String createUsername = '/create_username';
  //static const String map = '/map';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider<WelcomeViewModel>(
            create: (_) => WelcomeViewModel(),
            child: Consumer<WelcomeViewModel>(
              builder: (context, viewModel, _) => WelcomeScreen(viewModel: viewModel),
            ),
          ),
        );

      case email:
        return MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider<EmailViewModel>(
            create: (context) => EmailViewModel(context.read<AuthRepository>()),
            child: Consumer<EmailViewModel>(
              builder: (context, viewModel, _) => EmailScreen(viewModel: viewModel),
            ),
          ),
        );

      case loginPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        final userEmail = args?['email'] as String? ?? '';

        return MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider<LoginPasswordViewModel>(
            create: (context) => LoginPasswordViewModel(context.read<AuthRepository>())
                ..setEmail(userEmail),
            child: Consumer<LoginPasswordViewModel>(
              builder: (context, viewModel, _) => LoginPasswordScreen(viewModel: viewModel),
            ),
          ),
        );

      case createPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        final userEmail = args?['email'] as String? ?? '';

        return MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider<CreatePasswordViewModel>(
            create: (context) => CreatePasswordViewModel(context.read<AuthRepository>())
                ..setEmail(userEmail),
            child: Consumer<CreatePasswordViewModel>(
              builder: (context, viewModel, _) => CreatePasswordScreen(viewModel: viewModel),
            ),
          ),
        );

      case createUsername:
        final args = settings.arguments as Map<String, dynamic>?;
        final userEmail = args?['email'] as String? ?? '';
        final userPassword = args?['password'] as String? ?? '';

        return MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider<CreateUsernameViewModel>(
            create: (context) => CreateUsernameViewModel(context.read<AuthRepository>())
                ..setEmail(userEmail)
                ..setPass(userPassword),
            child: Consumer<CreateUsernameViewModel>(
              builder: (context, viewModel, _) => CreateUsernameScreen(viewModel: viewModel),
            ),
          ),
        );


      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Not defined: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
