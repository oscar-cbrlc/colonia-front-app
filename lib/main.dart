import 'package:colonia_front_app/env/env.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

import 'package:colonia_front_app/data/services/api/api_client.dart';
import 'package:colonia_front_app/data/services/api/auth_service.dart';
import 'package:colonia_front_app/data/services/location_service.dart';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/firebase_auth_repository.dart';
import 'package:colonia_front_app/data/repositories/session_repository.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:colonia_front_app/data/services/api/training_service.dart';
import 'package:colonia_front_app/data/repositories/training_repository.dart';
import 'package:colonia_front_app/data/services/api/territory_service.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/data/repositories/boost_repository.dart';

import 'package:colonia_front_app/data/services/api/team_service.dart';
import 'package:colonia_front_app/data/repositories/team_repository.dart';
import 'package:colonia_front_app/data/services/api/team_request_service.dart';
import 'package:colonia_front_app/data/repositories/team_request_repository.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';

import 'package:colonia_front_app/ui/team/view_models/team_viewmodel.dart';
import 'package:colonia_front_app/ui/map/view_models/map_viewmodel.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(Env.mapboxAccessToken);
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),

        ProxyProvider<ApiClient, AuthService>(
          update: (_, apiClient, __) => AuthService(apiClient),
        ),

        ProxyProvider<ApiClient, TrainingService>(
          update: (_, apiClient, __) => TrainingService(apiClient),
        ),

        ProxyProvider<ApiClient, TerritoryService>(
          update: (_, apiClient, __) => TerritoryService(apiClient),
        ),

        ProxyProvider<ApiClient, TeamService>(
          update: (_, apiClient, __) => TeamService(apiClient),
        ),

        ProxyProvider<ApiClient, TeamRequestService>(
          update: (_, apiClient, __) => TeamRequestService(apiClient),
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

        ChangeNotifierProxyProvider<TrainingService, TrainingRepository>(
          create: (context) => TrainingRepository(
            trainingService: context.read<TrainingService>(),
          ),
          update: (_, trainingService, previous) =>
          previous ?? TrainingRepository(trainingService: trainingService),
        ),

        ChangeNotifierProxyProvider<TerritoryService, TerritoryRepository>(
          create: (context) => TerritoryRepository(context.read<TerritoryService>()),
          update: (_, territoryService, previous) =>
              previous ?? TerritoryRepository(territoryService),
        ),

        ChangeNotifierProxyProvider<TeamService, TeamRepository>(
          create: (context) => TeamRepository(context.read<TeamService>()),
          update: (_, teamService, previous) =>
              previous ?? TeamRepository(teamService),
        ),

        ChangeNotifierProxyProvider<TeamRequestService, TeamRequestRepository>(
          create: (context) => TeamRequestRepository(context.read<TeamRequestService>()),
          update: (_, teamRequestService, previous) =>
              previous ?? TeamRequestRepository(teamRequestService),
        ),

        ChangeNotifierProvider<BoostRepository>(
          create: (_) => BoostRepository(),
        ),

        Provider<LocationService>(
          create: (_) => LocationService(),
        ),

        ChangeNotifierProxyProvider2<LocationService, TerritoryRepository, TrackingRepository>(
          create: (context) => TrackingRepository(
            context.read<LocationService>(),
            context.read<TerritoryRepository>(),
          ),
          update: (_, locationService, territoryRepository, previous) =>
              previous ?? TrackingRepository(locationService, territoryRepository),
        ),

        ChangeNotifierProxyProvider2<TrackingRepository, TerritoryRepository, SessionRepository>(
          create: (context) => SessionRepository(
            context.read<TrackingRepository>(),
            context.read<TerritoryRepository>(),
          ),
          update: (_, trackingRepository, territoryRepository, previous) => 
              previous ?? SessionRepository(trackingRepository, territoryRepository),
        ),

        ChangeNotifierProxyProvider2<TrackingRepository, TerritoryRepository, MapViewModel>(
          create: (context) => MapViewModel(
            context.read<TrackingRepository>(),
            context.read<TerritoryRepository>(),
          ),
          update: (_, trackingRepository, territoryRepository, previous) =>
              previous ?? MapViewModel(trackingRepository, territoryRepository),
        ),

        ChangeNotifierProxyProvider3<TeamRepository, AuthRepository, TeamRequestRepository, TeamViewModel>(
          create: (context) => TeamViewModel(
            context.read<TeamRepository>(),
            context.read<AuthRepository>(),
            context.read<TeamRequestRepository>(),
          ),
          update: (_, teamRepository, authRepository, teamRequestRepository, previous) =>
              previous ?? TeamViewModel(teamRepository, authRepository, teamRequestRepository),
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
        _navigatorKey.currentState?.pushReplacementNamed(AppRouter.map);
      } else {
        _navigatorKey.currentState?.pushReplacementNamed(AppRouter.welcome);
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
