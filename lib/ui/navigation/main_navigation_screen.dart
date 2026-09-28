import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/user_profile/view_models/user_profile_viewmodel.dart';
import 'package:colonia_front_app/ui/user_profile/widgets/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/ui/team/widgets/team_screen.dart';
import 'package:colonia_front_app/ui/team/view_models/team_viewmodel.dart';
import 'package:colonia_front_app/ui/map/widgets/map_screen.dart';
import 'package:colonia_front_app/ui/map/view_models/map_viewmodel.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

import 'package:flutter/services.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Consumer<TeamViewModel>(
              builder: (context, viewModel, _) => TeamScreen(viewModel: viewModel),
            ),
            Consumer<MapViewModel>(
              builder: (context, viewModel, _) => MapScreen(viewModel: viewModel),
            ),
            Consumer<UserProfileViewModel>(
              builder: (context, viewModel, _) => UserProfileScreen(viewModel: viewModel),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          clipBehavior: Clip.antiAlias,
          height: 60,
          decoration: ShapeDecoration(
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            color: AppTheme.darkBackground.withAlpha(200),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              indicatorWeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              //indicatorPadding: const EdgeInsets.only(right: 0),
              labelColor: AppTheme.darkBackground,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              labelPadding: EdgeInsets.zero,
              unselectedLabelColor: Colors.white70,
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.pressed)) {
                    return AppTheme.primaryColor.withAlpha(25);
                  }
                  return null;
                },
              ),
              tabs: [
                Tab(icon: const Icon(Icons.group), text: locale.team),
                Tab(icon: const Icon(Icons.map), text: locale.map),
                Tab(icon: const Icon(Icons.person), text: locale.profile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}