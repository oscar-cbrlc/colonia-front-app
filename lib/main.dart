// lib/main.dart (Updated with named routing)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Localization & Themes
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

// Services, Repositories, & Navigation
import 'package:colonia_front_app/data/services/api/api_client.dart';
import 'package:colonia_front_app/data/services/auth_service.dart';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/firebase_auth_repository.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),

        ProxyProvider<ApiClient, AuthService>(
          update: (_, apiClient, __) => AuthService(apiClient),
        ),

        ChangeNotifierProxyProvider<AuthService, AuthRepository>(
          create: (context) => AuthRepository(context.read<AuthService>()),
          update: (context, authService, previous) {
            final authRepository = previous ?? AuthRepository(authService);

            final apiClient = Provider.of<ApiClient>(context, listen: false);
            apiClient.setAuthRepository(authRepository);

            return authRepository;
          },
        ),

        ChangeNotifierProxyProvider2<AuthService, AuthRepository, FirebaseAuthRepository>(
          create: (context) => FirebaseAuthRepository(
            context.read<AuthService>(),
            context.read<AuthRepository>(),
          ),
          update: (_, authService, authRepository, previous) =>
              previous ?? FirebaseAuthRepository(authService, authRepository),
        ),
      ],
      child: const ColoniaApp(),
    ),
  );
}

class ColoniaApp extends StatefulWidget {
  const ColoniaApp({super.key});

  @override
  State<ColoniaApp> createState() => _ColoniaAppState();
}

class _ColoniaAppState extends State<ColoniaApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);

      await authRepo.initializeSession();

      if (authRepo.hasActiveSession) {
        //_navigatorKey.currentState?.pushReplacementNamed(AppRouter.map);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colonia',
      theme: AppTheme.theme,
      darkTheme: AppTheme.theme,
      themeMode: ThemeMode.system,

      navigatorKey: _navigatorKey,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],

      initialRoute: AppRouter.welcome,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
