import 'package:colonia_front_app/domain/models/enums/activity_type.dart';
import 'package:colonia_front_app/domain/models/enums/training_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_summary_viewmodel.dart';
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    if (widget.viewModel.showStats) ...[
                      const SizedBox(height: 8),
                      _buildMissionStatus(context),
                      const Spacer(),
                      _buildSummaryCard(context),
                      const SizedBox(height: 32),
                    ] else ...[
                      const Spacer(),
                    ],
                    _buildActionButtons(context),
                    const SizedBox(height: 20),
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

    final IconData trainingIcon = switch (trainingType) {
      TrainingType.distance => Icons.straighten,
      TrainingType.time => Icons.timer,
      TrainingType.pace => Icons.linear_scale,
      TrainingType.timeTrial => Icons.av_timer_sharp,
      TrainingType.free => Icons.timer_off,
    };

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trainingIcon, color: AppTheme.primaryColor.withAlpha(200), size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                trainingType.getLocale(locale).toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryColor.withAlpha(200),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                activityIcon, color: AppTheme.primaryColor.withAlpha(200), size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                activityType.getLocale(locale).toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryColor.withAlpha(200),
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
                  color: widget.viewModel.session.isSuccess ? AppTheme.secondaryColor : Colors.white54,
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
          color: statusColor.withAlpha(30),
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

  Widget _buildSummaryCard(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final vm = widget.viewModel;
    final session = vm.session;

    final bool hasWalk = session.secondsWalk > 0 || session.distanceWalk > 0;
    final bool hasRun = session.secondsRun > 0 || session.distanceRun > 0;
    final bool hasBike = session.secondsBike > 0 || session.distanceBike > 0;
    final bool hasInactive = session.secondsInactive > 0 || session.distanceInactive > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: Colors.black.withAlpha(160),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: ClipRRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.validSummary.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: locale.distance.toUpperCase(),
                    value: vm.formattedValidDistance,
                    unit: locale.km.toUpperCase(),
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: locale.time.toUpperCase(),
                    value: vm.formattedValidTime,
                    unit: "",
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: locale.avgPace,
                    value: vm.formattedPace,
                    unit: "MIN/KM",
                  ),
                ),
              ],
            ),

            if (hasWalk || hasRun || hasBike) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.white10, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (hasWalk)
                    Expanded(
                      child: _SummaryStat(
                        label: locale.walk.toUpperCase(),
                        value: vm.formattedWalkDistance,
                        unit: "${locale.km.toUpperCase()} (${vm.formattedWalkTime})",
                        color: AppTheme.walkColor,
                      ),
                    ),
                  if (hasRun)
                    Expanded(
                      child: _SummaryStat(
                        label: locale.run.toUpperCase(),
                        value: vm.formattedRunDistance,
                        unit: "${locale.km.toUpperCase()} (${vm.formattedRunTime})",
                        color: AppTheme.runColor,
                      ),
                    ),
                  if (hasBike)
                    Expanded(
                      child: _SummaryStat(
                        label: locale.bike.toUpperCase(),
                        value: vm.formattedBikeDistance,
                        unit: "${locale.km.toUpperCase()} (${vm.formattedBikeTime})",
                        color: AppTheme.bikeColor,
                      ),
                    ),
                ],
              ),
            ],

            if (hasInactive) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.white10, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: locale.unknownTime.toUpperCase(),
                      value: vm.formattedInactiveTime,
                      unit: "(${vm.formattedInactiveDistance} km)",
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Colors.white10, height: 1),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: locale.impacted.toUpperCase(),
                    value: vm.session.territories.length.toString(),
                    unit: locale.hexagons.toUpperCase(),
                    color: AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: locale.totalDuration.toUpperCase(),
                    value: vm.formattedTotalSessionTime,
                    unit: "",
                  ),
                ),
              ],
            ),

            if (vm.activityResult != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.white10, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: locale.captured.toUpperCase(),
                      value: vm.capturedCount.toString(),
                      unit: "",
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: locale.attacked.toUpperCase(),
                      value: vm.attackedCount.toString(),
                      unit: "",
                      color: Colors.redAccent,
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: locale.defended.toUpperCase(),
                      value: vm.defendedCount.toString(),
                      unit: "",
                      color: AppTheme.tertiaryColor,
                    ),
                  ),
                ],
              ),
            ],
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

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oswald',
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
