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
    final String activity = widget.viewModel.activity;
    final String training = widget.viewModel.trainingName;
    final IconData activityIcon = activity == "walk"
        ? Icons.directions_walk
        : activity == "run"
        ? Icons.directions_run
        : Icons.directions_bike;
    final Color activityColor = activity == "walk"
        ? AppTheme.walkColor
        : activity == "run"
        ? AppTheme.runColor
        : AppTheme.bikeColor;
    final IconData trainingIcon = training == "distance"
        ? Icons.straighten
        : training == "time"
        ? Icons.timer
        : training == "pace"
        ? Icons.linear_scale
        : training == "timeTrial"
        ? Icons.av_timer_sharp
        : Icons.timer_off;
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
                widget.viewModel.trainingName.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryColor.withAlpha(200),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                activityIcon, color: activityColor.withAlpha(200), size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                widget.viewModel.activity.toUpperCase(),
                style: TextStyle(
                  color: activityColor.withAlpha(200),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: Colors.black.withAlpha(100),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
        ),
      ),
      child: ClipRRect(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryStat(
                  label: locale.distance.toUpperCase(),
                  value: widget.viewModel.distanceKm.toStringAsFixed(2),
                  unit: locale.km.toUpperCase(),
                ),
                _SummaryStat(
                  label: locale.time.toUpperCase(),
                  value: widget.viewModel.formattedTime,
                  unit: "",
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white10),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryStat(
                  label: locale.avgPace,
                  value: widget.viewModel.formattedPace,
                  unit: "MIN/KM",
                ),
                _SummaryStat(
                  label: locale.impacted,
                  value: widget.viewModel.session.territories.length.toString(),
                  unit: locale.hexagons,
                  color: AppTheme.secondaryColor,
                ),
              ],
            ),
            if (widget.viewModel.activityResult != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white10),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryStat(
                    label: locale.captured,
                    value: widget.viewModel.capturedCount.toString(),
                    unit: "",
                    color: AppTheme.primaryColor,
                  ),
                  _SummaryStat(
                    label: locale.attacked,
                    value: widget.viewModel.attackedCount.toString(),
                    unit: "",
                    color: Colors.redAccent,
                  ),
                  _SummaryStat(
                    label: locale.defended,
                    value: widget.viewModel.defendedCount.toString(),
                    unit: "",
                    color: AppTheme.tertiaryColor,
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
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oswald',
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
