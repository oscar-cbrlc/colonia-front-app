import 'package:colonia_front_app/domain/models/enums/activity_type.dart';
import 'package:colonia_front_app/domain/models/enums/training_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_summary_viewmodel.dart';
import 'package:colonia_front_app/ui/activity/widgets/summary_results_widget.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/territory_summary_bottom_sheet.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class ActivitySummaryScreen extends StatefulWidget {
  final ActivitySummaryViewModel viewModel;
  const ActivitySummaryScreen({super.key, required this.viewModel});

  @override
  State<ActivitySummaryScreen> createState() => _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    debugPrint("ActivitySummaryScreen: initState executed!");
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.viewModel.session.isSuccess) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.vibrate();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("ActivitySummaryScreen: build executed!");
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: mapbox.MapWidget(
                  key: const ValueKey("summary_screen_mapbox"),
                  styleUri: mapbox.MapboxStyles.STANDARD,
                  onMapCreated: widget.viewModel.onMapCreated,
                  onStyleLoadedListener: (data) {
                    widget.viewModel.onStyleLoaded();

                    final tapInteraction = mapbox.TapInteraction.onMap((gestureContext) {
                      final lat = gestureContext.point.coordinates.lat.toDouble();
                      final lon = gestureContext.point.coordinates.lng.toDouble();

                      final territory = widget.viewModel.getAffectedTerritoryAt(lat, lon);
                      if (territory != null) {
                        showTerritorySummaryBottomSheet(context, territory);
                      }
                    });

                    widget.viewModel.mapboxMap?.addInteraction(
                      tapInteraction,
                      interactionID: 'hexagon-click',
                    );
                  },
                  viewport: widget.viewModel.viewport,
                  gestureRecognizers: const {},
                )
              ),

              if (!widget.viewModel.isMapReady)
                Positioned.fill(
                  child: Container(
                    color: AppTheme.darkBackground,
                    child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  ),
                ),

              /*Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.darkBackground.withOpacity(0.3),
                        Colors.transparent,
                        AppTheme.darkBackground.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),*/

              /*if (widget.viewModel.isMapReady)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _pathAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _RoutePainter(
                            route: widget.viewModel.session.route,
                            progress: _pathAnimation.value,
                            color: AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),*/

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeader(context),
                    if (widget.viewModel.showStats) ...[
                      const SizedBox(height: 4),
                      //_buildMissionStatus(context),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: SummaryExpandableCard(viewModel: widget.viewModel),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      const Spacer(),
                    ],
                    _buildActionButtons(context),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final ActivityType activityType = widget.viewModel.activityType;
    final TrainingType trainingType = widget.viewModel.trainingType;

    final IconData activityIcon = switch (activityType) {
      ActivityType.onFoot => Icons.hiking_sharp,
      ActivityType.onBike => Icons.pedal_bike_sharp,
    };

    final IconData trainingIcon = trainingType.getIcon();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trainingIcon, color: AppTheme.secondaryColor.withAlpha(200), size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                trainingType.getLocale(locale).toUpperCase(),
                style: TextStyle(
                  color: AppTheme.secondaryColor.withAlpha(200),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                activityIcon, color: AppTheme.secondaryColor.withAlpha(200), size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                activityType.getLocale(locale).toUpperCase(),
                style: TextStyle(
                  color: AppTheme.secondaryColor.withAlpha(200),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                locale.results.toUpperCase(),
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  fontFamily: 'Oswald',
                  shadows: widget.viewModel.session.isSuccess ? [
                    Shadow(
                      color: AppTheme.secondaryColor.withAlpha(100),
                      blurRadius: 10,
                    )
                  ] : null,
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.viewModel.toggleShowStats();
                },
                icon: Icon(
                  widget.viewModel.showStats
                      ? Icons.bar_chart
                      : Icons.bar_chart_outlined,
                ),
                color: widget.viewModel.showStats
                    ? AppTheme.primaryColor
                    : Colors.white38,
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStatus(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final bool success = widget.viewModel.session.isSuccess;
    final Color statusColor = success ? AppTheme.successColor : AppTheme.errorColor;
    final String statusText = success ? locale.missionComplete : locale.objectiveNotMet;
    final IconData statusIcon = success ? Icons.check_circle_outline : Icons.error_outline;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: statusColor.withAlpha(60),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: statusColor.withAlpha(150), width: 1.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
                fontFamily: 'Oswald',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.black,
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          child: Text(
            locale.backToMap,
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }
}
