import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/boost_repository.dart';
import 'package:colonia_front_app/data/repositories/firebase_auth_repository.dart';
import 'package:colonia_front_app/data/repositories/session_repository.dart';
import 'package:colonia_front_app/data/repositories/team_repository.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:colonia_front_app/data/repositories/training_repository.dart';
import 'package:colonia_front_app/domain/models/activity_result.dart';
import 'package:colonia_front_app/domain/models/user.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_summary_viewmodel.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_viewmodel.dart';
import 'package:colonia_front_app/ui/activity/widgets/activity_screen.dart';
import 'package:colonia_front_app/ui/activity/widgets/activity_summary_screen.dart';
import 'package:colonia_front_app/ui/auth/view_models/create_password_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/view_models/create_username_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/view_models/email_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/view_models/login_password_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/view_models/welcome_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/widgets/create_password_screen.dart';
import 'package:colonia_front_app/ui/auth/widgets/create_username_screen.dart';
import 'package:colonia_front_app/ui/auth/widgets/email_screen.dart';
import 'package:colonia_front_app/ui/auth/widgets/login_password_screen.dart';
import 'package:colonia_front_app/ui/auth/widgets/welcome_screen.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/navigation/main_navigation_screen.dart';
import 'package:colonia_front_app/ui/team/widgets/colony_details_screen.dart';
import 'package:colonia_front_app/ui/user_profile/view_models/user_profile_viewmodel.dart';
import 'package:colonia_front_app/ui/user_profile/widgets/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static const String welcome = "/";
  static const String emailInput = "/email_input";
  static const String passwordLogin = "/password_login";
  static const String createUsername = "/create_username";
  static const String createPassword = "/create_password";
  static const String map = "/map";
  static const String activity = "/activity";
  static const String summary = "/summary";
  static const String colonyDetails = "/colony_details";
  static const String profile = "/profile";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => WelcomeScreen(
            viewModel: WelcomeViewModel(
              context.read<FirebaseAuthRepository>(),
            ),
          ),
        );

      case emailInput:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => EmailScreen(
            viewModel: EmailViewModel(
              context.read<AuthRepository>(),
            ),
          ),
        );

      case passwordLogin:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? '';

        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final viewModel = LoginPasswordViewModel(
              context.read<AuthRepository>(),
            );
            if (email.isNotEmpty) viewModel.setEmail(email);
            return LoginPasswordScreen(viewModel: viewModel);
          },
        );

      case createPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? '';

        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final viewModel = CreatePasswordViewModel(
              context.read<AuthRepository>(),
            );
            if (email.isNotEmpty) viewModel.setEmail(email);
            return CreatePasswordScreen(viewModel: viewModel);
          },
        );

      case createUsername:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? '';
        final password = args?['password'] as String? ?? '';
        final isSocialAuth = args?['isSocialAuth'] as bool? ?? false;

        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final viewModel = CreateUsernameViewModel(
              context.read<AuthRepository>(),
            );
            if (email.isNotEmpty) viewModel.setEmail(email);
            if (password.isNotEmpty) viewModel.setPass(password);
            viewModel.setSocialAuth(isSocialAuth);
            return CreateUsernameScreen(viewModel: viewModel);
          },
        );

      case map:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const MainNavigationScreen(),
        );

      case summary:
        final args = settings.arguments as Map<String, dynamic>?;

        if (args?['viewModel'] is ActivitySummaryViewModel) {
          final viewModel = args!['viewModel'] as ActivitySummaryViewModel;
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ActivitySummaryScreen(viewModel: viewModel),
          );
        }

        final session = args?['session'] as TrackingSession?;
        final activityResult = args?['activityResult'] as ActivityResult?;
        final activity = args?['activity'] as String?;
        final trainingName = args?['trainingName'] as String?;

        if (session != null && activity != null && trainingName != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ChangeNotifierProvider<ActivitySummaryViewModel>(
              create: (context) => ActivitySummaryViewModel(
                session: session,
                activityResult: activityResult,
                activity: activity,
                trainingName: trainingName,
              ),
              child: Consumer<ActivitySummaryViewModel>(
                builder: (context, viewModel, _) => ActivitySummaryScreen(viewModel: viewModel),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
            backgroundColor: AppTheme.darkBackground,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: const Center(
              child: Text("Error: Missing Activity Summary data.", style: TextStyle(color: Colors.white70)),
            ),
          ),
        );

      case colonyDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final teamId = args?['teamId'] as int?;

        if (teamId == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const Scaffold(
              body: Center(child: Text("Error: Missing colony ID")),
            ),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ColonyDetailsScreen(teamId: teamId),
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
              context.read<TeamRepository>(),
            ),
            child: Consumer<ActivityViewModel>(
              builder: (context, viewModel, _) => ActivityScreen(viewModel: viewModel),
            ),
          ),
        );

      case profile:
        final args = settings.arguments as Map<String, dynamic>?;
        final userArg = args?['user'];
        final userId = args?['userId'] as int?;

        if (userArg is User) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ChangeNotifierProvider<UserProfileViewModel>(
              create: (context) => UserProfileViewModel(userArg),
              child: Consumer<UserProfileViewModel>(
                builder: (context, viewModel, _) => UserProfileScreen(viewModel: viewModel),
              ),
            ),
          );
        }

        Future<User>? userFuture;
        if (userArg is Future<User>) {
          userFuture = userArg;
        } else if (userId != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) {
              final authRepo = Provider.of<AuthRepository>(context, listen: false);
              return FutureBuilder<User>(
                future: authRepo.getUserById(id: userId),
                builder: (context, snapshot) {
                  return _buildProfileFutureContent(context, snapshot);
                },
              );
            },
          );
        }

        if (userFuture != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => FutureBuilder<User>(
              future: userFuture,
              builder: (context, snapshot) {
                return _buildProfileFutureContent(context, snapshot);
              },
            ),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
            backgroundColor: AppTheme.darkBackground,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const Center(
              child: Text("Error: User data missing", style: TextStyle(color: Colors.white70)),
            ),
          ),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Widget _buildProfileFutureContent(BuildContext context, AsyncSnapshot<User> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Text(
            "Error loading profile: ${snapshot.error ?? 'User not found'}",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return ChangeNotifierProvider<UserProfileViewModel>(
      create: (context) => UserProfileViewModel(snapshot.data!),
      child: Consumer<UserProfileViewModel>(
        builder: (context, viewModel, _) => UserProfileScreen(viewModel: viewModel),
      ),
    );
  }
}
