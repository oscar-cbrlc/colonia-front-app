import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

import 'package:colonia_front_app/data/services/api/api_client.dart';
import 'package:colonia_front_app/data/services/auth_service.dart';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';

import 'package:colonia_front_app/ui/auth/widgets/welcome_screen.dart';
import 'package:colonia_front_app/ui/auth/view_models/welcome_viewmodel.dart';


void main(){
  runApp(
    MultiProvider(
        providers: [
          Provider<ApiClient>(
            create: (_) => ApiClient(),
          ),
          ProxyProvider<ApiClient, AuthService>(
            update: (_, apiClient, __) => AuthService(apiClient),
          ),
          ProxyProvider<AuthService, AuthRepository>(
            update: (context, authService, __) {
              final authRepository = AuthRepository(authService);
              final apiClient = Provider.of<ApiClient>(context, listen: false);
              apiClient.setAuthRepository(authRepository);

              return authRepository;
            },
          ),
        ],
      child: const ColoniaApp(),
    )
  );
}



class ColoniaApp extends StatefulWidget {
  const ColoniaApp({super.key});

  @override
  State<ColoniaApp> createState() => _ColoniaAppState();
}

class _ColoniaAppState extends State<ColoniaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);

      await authRepo.initializeSession();

      if (authRepo.hasActiveSession) {
        // TODO(Boot): route authenticated user to Map screen
        print("Session active Token: ${authRepo.cachedToken}");
      } else {
        print("No active session");
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

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate, // Core Material widget translations (date pickers, etc)
        GlobalWidgetsLocalizations.delegate, // Text direction support
        GlobalCupertinoLocalizations.delegate, // Cupertino widget translations
      ],

      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],

      home: ChangeNotifierProvider<WelcomeViewModel>(
        create: (_) => WelcomeViewModel(),
        child: Consumer<WelcomeViewModel>(
          builder: (context, viewModel, _) => WelcomeScreen(viewModel: viewModel),
        ),
      ),
    );
  }
}