import 'package:colonia_front_app/data/repositories/session_repository.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/data/repositories/training_repository.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_viewmodel.dart';
import 'package:colonia_front_app/ui/activity/widgets/activity_screen.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_summary_viewmodel.dart';
import 'package:colonia_front_app/ui/activity/widgets/activity_summary_screen.dart';
import 'package:colonia_front_app/ui/team/widgets/colony_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Repositories
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/boost_repository.dart';
import 'package:colonia_front_app/data/repositories/firebase_auth_repository.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';

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
import 'package:colonia_front_app/ui/navigation/main_navigation_screen.dart';

class AppRouter {
  static const String welcome = '/';
  static const String email = '/email';
  static const String loginPassword = '/login_password';
  static const String createPassword = '/create_password';
  static const String createUsername = '/create_username';
  static const String navigation = '/navigation';
  static const String map = '/map';
  static const String activity = "/activity";
  static const String summary = "/summary";
  static const String colonyDetails = "/colony_details";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      case summary:
        final args = settings.arguments as Map<String, dynamic>?;
        final session = args?['session'] as TrackingSession;
        final activity = args?['activity'] as String? ?? 'walk';
        final trainingName = args?['trainingName'] as String? ?? 'free';

        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ChangeNotifierProvider<ActivitySummaryViewModel>(
            create: (context) => ActivitySummaryViewModel(
              session: session,
              activity: activity,
              trainingName: trainingName,
            ),
            child: ActivitySummaryScreen(viewModel: Provider.of<ActivitySummaryViewModel>(context, listen: false)),
          ),
        );
      case welcome:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ChangeNotifierProvider<WelcomeViewModel>(
            create: (context) => WelcomeViewModel(context.read<FirebaseAuthRepository>()),
            child: Consumer<WelcomeViewModel>(
              builder: (context, viewModel, _) => WelcomeScreen(viewModel: viewModel),
            ),
          ),
        );

      case email:
        return MaterialPageRoute(
          settings: settings,
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
          settings: settings,
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
          settings: settings,
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
        final isSocialAuth = args?['isSocialAuth'] as bool? ?? false;

        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ChangeNotifierProvider<CreateUsernameViewModel>(
            create: (context) => CreateUsernameViewModel(context.read<AuthRepository>())
              ..setEmail(userEmail)
              ..setPass(userPassword)
              ..setSocialAuth(isSocialAuth),
            child: Consumer<CreateUsernameViewModel>(
              builder: (context, viewModel, _) => CreateUsernameScreen(viewModel: viewModel),
            ),
          ),
        );


      case colonyDetails:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
             final args = settings.arguments as Map<String, dynamic>?;
             final teamId = args?['teamId'] as int;
             return ColonyDetailsScreen(teamId: teamId);
          }
        );

      case map:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const MainNavigationScreen(),
        );

      case activity:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ChangeNotifierProvider<ActivityViewModel>(
            create: (context) => ActivityViewModel(
              context.read<SessionRepository>(),
              context.read<TrackingRepository>(),
              context.read<TrainingRepository>(),
              context.read<BoostRepository>(),
              context.read<TerritoryRepository>(),
            ),
            child: Consumer<ActivityViewModel>(
              builder: (context, viewModel, _) => ActivityScreen(viewModel: viewModel),
            ),
          )
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Not defined: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
