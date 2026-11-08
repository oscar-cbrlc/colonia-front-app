import 'dart:ui';
import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/enums/activity_type.dart';
import 'package:colonia_front_app/domain/models/enums/har_activity.dart';
import 'package:colonia_front_app/domain/models/session/session_enums.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_viewmodel.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/map_control_group.dart';
import 'package:colonia_front_app/ui/core/ui/territory_summary_bottom_sheet.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:colonia_front_app/data/services/notification_service.dart';
import 'package:colonia_front_app/env/env.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.viewModel});
  final ActivityViewModel viewModel;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {

  @override
  void initState() {
    super.initState();
    mapbox.MapboxOptions.setAccessToken(Env.mapboxAccessToken);
    widget.viewModel.requestLocationPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.viewModel.trainingConfig == null) {
        widget.viewModel.setActivityConfig(
          activityType: ActivityType.onFoot,
          trainingType: TrainingType.free,
          distance: 0.0,
          time: Duration.zero,
          pace: 0.0,
          boost: null,
        );
      }
    });

    widget.viewModel.sessionRepository.onStartNotification = () {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      if (locale != null) {
        NotificationService().showNotification(
          id: 101,
          title: 'Colonia',
          body: locale.activityStarted,
        );
      }
    };

    widget.viewModel.trackingRepository.onSuspectedInvalidNotification = () {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      if (locale != null) {
        NotificationService().showNotification(
          id: 102,
          title: 'Colonia - Tracking',
          body: widget.viewModel.selectedActivityType == ActivityType.onFoot? locale.suspectedOnFootDescription(GameConfig.limitConsecutiveInvalidUnits) : locale.suspectedOnBikeDescription((GameConfig.limitConsecutiveInvalidUnits)),
        );
      }
    };

    widget.viewModel.trackingRepository.onAutoResumedNotification = () {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      if (locale != null) {
        NotificationService().showNotification(
          id: 103,
          title: 'Colonia - Tracking',
          body: locale.autoResumed,
        );
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Stack(
          children: [
            mapbox.MapWidget(
              key: const ValueKey("activity_screen_mapbox"),
              styleUri: mapbox.MapboxStyles.STANDARD,
              onMapCreated: widget.viewModel.onMapCreated,
              onStyleLoadedListener: (data) {
                widget.viewModel.onStyleLoaded();

                final tapInteraction = mapbox.TapInteraction.onMap((gestureContext) {
                  if (widget.viewModel.playingState != PlayingState.stopped) return;

                  final lat = gestureContext.point.coordinates.lat.toDouble();
                  final lon = gestureContext.point.coordinates.lng.toDouble();

                  final territory = widget.viewModel.getClaimedTerritoryAt(lat, lon);
                  if (territory != null) {
                    showTerritorySummaryBottomSheet(context, territory);
                  }
                });

                widget.viewModel.mapboxMap?.addInteraction(
                  tapInteraction,
                  interactionID: 'hexagon-click',
                );
              },
              onCameraChangeListener: (data) => widget.viewModel.onCameraChanged(data),
              viewport: widget.viewModel.viewport ??
                  (widget.viewModel.userPosition != null
                      ? mapbox.CameraViewportState(
                    center: widget.viewModel.userPosition!,
                    zoom: 17.0,
                  )
                      : null),
            ),

            if (widget.viewModel.isSaving)
              Container(
                color: Colors.black.withAlpha(220),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.secondaryColor),
                      SizedBox(height: 16),
                      Text(
                        locale.savingActivity,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                ),
              ),

            if (widget.viewModel.playingState == PlayingState.stopped)
              Align(
                alignment: Alignment.topLeft,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.primaryColor,
                        size: 32.0,
                      ),
                    ),
                  ),
                ),
              ),

            Align(
              alignment: Alignment.centerRight,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 320, right: 16),
                  child: MapControlGroup(
                    listenable: widget.viewModel,
                    currentBearing: widget.viewModel.currentBearing,
                    showPoints: widget.viewModel.showPoints,
                    onCenterOnUser: widget.viewModel.centerOnUser,
                    onToggleShowPoints: widget.viewModel.toggleShowPoints,
                    onResetNorth: widget.viewModel.resetNorth,
                  ),
                ),
              ),
            ),

            if (widget.viewModel.playingState != PlayingState.stopped)
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NextImpactPanel(viewModel: widget.viewModel),
                    const SizedBox(height: 8),
                    _HarActivityVisualizerWidget(
                      sensorActivity: widget.viewModel.currentHarActivity,
                    ),
                  ],
                ),
              ),
            if (widget.viewModel.playingState != PlayingState.stopped)
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.viewModel.selectedTrainingType != TrainingType.free &&
                        widget.viewModel.selectedTrainingType != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: _TrainingObjectiveWidget(viewModel: widget.viewModel),
                      ),
                    _ActivityProgressPanel(viewModel: widget.viewModel),
                  ],
                ),
              ),

            if (widget.viewModel.playingState == PlayingState.stopped)
              Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.viewModel.readyToStart && !widget.viewModel.isSaving) ...[
                      _PreActivityOverviewCard(viewModel: widget.viewModel),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.viewModel.onPushPlayButton,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: AppTheme.darkBackground,
                              shape: const BeveledRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                locale.start.toUpperCase(), 
                                style: const TextStyle(
                                  color: AppTheme.darkBackground, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
          ],
        );
      },
    );
  }
}

void _showActivitySelectorSheet(BuildContext context, ActivityViewModel viewModel) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ActivitySelectorSheet(viewModel: viewModel),
  );
}

class _PreActivityOverviewCard extends StatefulWidget {
  final ActivityViewModel viewModel;
  final bool initiallyExpanded;

  const _PreActivityOverviewCard({
    required this.viewModel,
    this.initiallyExpanded = true,
  });

  @override
  State<_PreActivityOverviewCard> createState() => _PreActivityOverviewCardState();
}

class _PreActivityOverviewCardState extends State<_PreActivityOverviewCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final ActivityType activityType = widget.viewModel.selectedActivityType ?? ActivityType.onFoot;
        final TrainingType training = widget.viewModel.selectedTrainingType ?? widget.viewModel.selectedPreTrainingType ?? TrainingType.free;
        final BoostInventory? boost = widget.viewModel.equippedBoost;

        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubicEmphasized,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: ShapeDecoration(
                color: AppTheme.darkBackground,
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locale.excursionDetailsTitle.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Oswald',
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubicEmphasized,
                  child: _isExpanded
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: ShapeDecoration(
                                color: Colors.white.withAlpha(15),
                                shape: BeveledRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Colors.white.withAlpha(100),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        activityType == ActivityType.onBike
                                            ? Icons.pedal_bike_sharp
                                            : Icons.hiking_sharp,
                                        color: AppTheme.primaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        locale.activity.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        (activityType == ActivityType.onBike
                                                ? locale.onBike
                                                : locale.onFoot)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Oswald',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white12, height: 16),

                                  Row(
                                    children: [
                                      Icon(widget.viewModel.selectedTrainingType?.getIcon(),
                                          color: AppTheme.primaryColor, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        locale.training.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        training.getLocale(locale).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Oswald',
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (training != TrainingType.free) ...[
                                    const Divider(color: Colors.white12, height: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.flag_outlined,
                                            color: AppTheme.primaryColor, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          locale.setObjective.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _formatObjectiveSummary(widget.viewModel, training, locale),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Oswald',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const Divider(color: Colors.white12, height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        boost != null ? boost.icon : Icons.electric_bolt_sharp,
                                        color: AppTheme.primaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        locale.boosts.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        boost != null
                                            ? boost.getNameWithEffect(locale).toUpperCase()
                                            : locale.noBoost.toUpperCase(),
                                        style: TextStyle(
                                          color: boost != null ? AppTheme.tertiaryColor : Colors.white54,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Oswald',
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Divider(color: Colors.white12, height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.data_thresholding_sharp,
                                          color: AppTheme.primaryColor, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        locale.trainingImpactMod.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "x${widget.viewModel.currentMultiplier.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: AppTheme.secondaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Oswald',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: AppTheme.darkBackground,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: const BeveledRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      _showActivitySelectorSheet(context, widget.viewModel);
                                    },
                                    icon: const Icon(Icons.tune, size: 18),
                                    label: Text(
                                      locale.editSelection.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Oswald',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: AppTheme.secondaryColor,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  String _formatObjectiveSummary(ActivityViewModel viewModel, TrainingType training, AppLocalizations locale) {
    if (training == TrainingType.distance) {
      final d = viewModel.selectedDistance ?? 0.0;
      return "${(d / 1000).toStringAsFixed(1)} KM";
    } else if (training == TrainingType.time) {
      final t = viewModel.selectedTime ?? Duration.zero;
      if (t.inHours > 0) return "${t.inHours}H ${t.inMinutes.remainder(60)}MIN";
      return "${t.inMinutes}MIN ${t.inSeconds.remainder(60)}S";
    } else if (training == TrainingType.pace) {
      final d = viewModel.selectedDistance ?? 0.0;
      return "${(d / 1000).toStringAsFixed(1)} KM @ ${viewModel.formattedSelectedPace} MIN/KM";
    } else if (training == TrainingType.timeTrial) {
      final d = viewModel.selectedDistance ?? 0.0;
      final t = viewModel.selectedTime ?? Duration.zero;
      return "${(d / 1000).toStringAsFixed(1)} KM IN ${t.inMinutes} MIN";
    }
    return "";
  }
}

class _DistanceProgressPanel extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _DistanceProgressPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final double targetDistanceMeters = viewModel.selectedDistanceMeters;
        final double progress = targetDistanceMeters > 0
            ? (viewModel.totalMetersTracked / targetDistanceMeters)
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SegmentedProgressBar(
              progress: progress,
              color: AppTheme.primaryColor,
              isReversed: false,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: TextDecoration.none
                  ),
                ),
                if (targetDistanceMeters > 0)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ((targetDistanceMeters - viewModel.totalMetersTracked).clamp(0, double.infinity) / 1000).toStringAsFixed(2),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          decoration: TextDecoration.none
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "KM",
                        style: TextStyle(
                          color: AppTheme.primaryColor.withAlpha(180),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          decoration: TextDecoration.none
                        ),
                      )
                    ]
                  ),

              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  final double progress;
  final int segments;
  final bool isReversed;
  final Color color;
  final Color backgroundColor;

  const _SegmentedProgressBar({
    required this.progress,
    this.segments = 15,
    this.isReversed = false,
    required this.color,
    this.backgroundColor = Colors.white10,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveProgress = isReversed 
        ? (1.0 - progress).clamp(0.0, 1.0) 
        : progress.clamp(0.0, 1.0);
    
    return Row(
      children: List.generate(segments, (index) {
        final double threshold = (index + 1) / segments;
        final bool isFilled = effectiveProgress >= threshold;
        
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(horizontal: index == 0 || index == segments - 1 ? 0 : 2),
            height: 10,
            decoration: ShapeDecoration(
              color: isFilled ? color : backgroundColor,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              )
            ),
          ),
        );
      }),
    );
  }
}

class _TimeProgressPanel extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _TimeProgressPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final double targetSeconds = viewModel.selectedTime?.inSeconds.toDouble() ?? 0.0;
        final double progress = targetSeconds > 0
            ? (viewModel.totalSecondsElapsed / targetSeconds)
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SegmentedProgressBar(
              progress: progress,
              color: AppTheme.secondaryColor,
              isReversed: true,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${((1.0 - progress) * 100).clamp(0, 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: TextDecoration.none
                  ),
                ),
                if (targetSeconds > 0)
                  Text(
                    _formatRemainingTime(targetSeconds - viewModel.totalSecondsElapsed.toDouble(), locale),
                    style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: TextDecoration.none
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String _formatRemainingTime(double seconds, AppLocalizations locale) {
    if (seconds <= 0) return locale.timeUp.toUpperCase();
    final Duration d = Duration(seconds: seconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String secs = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$minutes:$secs";
    }
    return "$minutes:$secs";
  }
}

class _PaceBarEquilibrium extends StatelessWidget {
  final double pace;
  final double targetPace;
  final int segments;
  final Color outPaceColor;
  final Color inPaceColor;
  final Color backgroundColor;
  const _PaceBarEquilibrium({
    required this.pace,
    required this.targetPace,
    this.segments = 15,
    required this.outPaceColor,
    required this.inPaceColor,
    this.backgroundColor = Colors.white10,
  });

  @override
  Widget build(BuildContext context) {
    if (targetPace <= 0) return const SizedBox.shrink();

    final double diff = (pace - targetPace);

    final double normalizedPosition = (0.5 + (diff / (targetPace * GameConfig.validPaceRange)));
    final double currentPos = normalizedPosition.clamp(0.0, 1.0);
    final int activeIndex = (currentPos * segments).floor().clamp(0, segments - 1);

    return Row(
      children: List.generate(segments, (index) {
        final bool isFilled = index == activeIndex;
        final bool isInRange = diff.abs() <= (targetPace * GameConfig.validPaceRange);

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(horizontal: index == 0 || index == segments - 1 ? 0 : 2),
            height: 10,
            decoration: ShapeDecoration(
                color: isFilled ? (isInRange ? inPaceColor : outPaceColor) : backgroundColor,
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                )
            ),
          ),
        );
      }),
    );
  }
}

class _PaceEquilibriumPanel extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _PaceEquilibriumPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final double targetPace = viewModel.selectedPace?.toDouble() ?? 0.0;
        final double currentPace = viewModel.currentPace;
        final HarActivity activity = viewModel.currentHarActivity;
        final Color activityColor = activity == HarActivity.walk
            ? AppTheme.walkColor
            : activity == HarActivity.run
                ? AppTheme.runColor
                : activity == HarActivity.bike
                    ? AppTheme.bikeColor
                    : AppTheme.primaryColor;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PaceBarEquilibrium(
              pace: currentPace,
              targetPace: targetPace,
              inPaceColor: AppTheme.successColor,
              outPaceColor: AppTheme.errorColor,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.behind.toUpperCase(),
                  style: TextStyle(
                    color: currentPace > targetPace ? activityColor : Colors.white24,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    decoration: TextDecoration.none
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      viewModel.formattedSelectedPace,
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          decoration: TextDecoration.none
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "MIN/KM",
                      style: TextStyle(
                          color: AppTheme.primaryColor.withAlpha(180),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          decoration: TextDecoration.none
                      ),
                    )
                  ]
                ),
                Text(
                  locale.ahead.toUpperCase(),
                  style: TextStyle(
                    color: currentPace < targetPace && currentPace > 0 ? activityColor : Colors.white24,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    decoration: TextDecoration.none
                  ),
                ),
              ],
            )
          ],
        );
      }
      );
  }
}

class _NextImpactPanel extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _NextImpactPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: ShapeDecoration(
              shape: BeveledRectangleBorder(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withAlpha(150),
                    width: 1,
                  ),
              ),
              color: AppTheme.darkBackground.withAlpha(200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),

                Text(
                  locale.nextImpact.toUpperCase(),
                  style: TextStyle(color: AppTheme.primaryColor.withAlpha(240), fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatDisplay(
                      value: viewModel.distanceTilNextNode.toString(),
                      unit: "M",
                    )
                  ]
                ),
              ]
            )
          );
        }
    );
  }
}

class _TrainingObjectiveWidget extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _TrainingObjectiveWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final training = viewModel.selectedTrainingType ?? viewModel.selectedPreTrainingType ?? TrainingType.free;
        if (training == TrainingType.free) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: AppTheme.darkBackground.withAlpha(230),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppTheme.primaryColor.withAlpha(180),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(training.getIcon(), color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${locale.setObjective.toUpperCase()} — ${training.getLocale(locale).toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.8,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (training == TrainingType.distance || training == TrainingType.pace || training == TrainingType.timeTrial) ...[
                _DistanceProgressPanel(viewModel: viewModel),
              ],
              if (training == TrainingType.time || training == TrainingType.timeTrial) ...[
                if (training != TrainingType.timeTrial) const SizedBox(height: 6),
                _TimeProgressPanel(viewModel: viewModel),
              ],
              if (training == TrainingType.pace) ...[
                const SizedBox(height: 6),
                _PaceEquilibriumPanel(viewModel: viewModel),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ActivityProgressPanel extends StatefulWidget {
  final ActivityViewModel viewModel;
  const _ActivityProgressPanel({super.key, required this.viewModel});

  @override
  State<_ActivityProgressPanel> createState() => _ActivityProgressPanelState();
}

class _ActivityProgressPanelState extends State<_ActivityProgressPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final viewModel = widget.viewModel;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final ActivityType activityType = viewModel.selectedActivityType!;
        final TrainingType training = viewModel.selectedTrainingType ?? viewModel.selectedPreTrainingType ?? TrainingType.free;

        final IconData activityIcon = switch (activityType) {
          ActivityType.onFoot => Icons.hiking_sharp,
          ActivityType.onBike => Icons.pedal_bike_sharp,
        };
        final Color activityTypeColor = switch (activityType) {
          ActivityType.onFoot => AppTheme.runColor,
          ActivityType.onBike => AppTheme.bikeColor,
        };
        final IconData trainingIcon = training.getIcon();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: ShapeDecoration(
            shape: BeveledRectangleBorder(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              side: BorderSide(
                color: activityTypeColor,
                width: 1.5,
              ),
            ),
            color: AppTheme.darkBackground.withAlpha(240),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(activityIcon, color: activityTypeColor, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              activityType.getLocale(locale).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'Oswald',
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: ShapeDecoration(
                                shape: BeveledRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(
                                    color: AppTheme.secondaryColor.withAlpha(180),
                                    width: 1.0,
                                  ),
                                ),
                                color: AppTheme.secondaryColor.withAlpha(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(trainingIcon, color: Colors.white.withAlpha(200), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    training.getLocale(locale).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Oswald',
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                              color: AppTheme.secondaryColor,
                              size: 28,
                            ),
                          ],
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubicEmphasized,
                      child: _isExpanded
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _StatDisplay(
                                        label: locale.distance.toUpperCase(),
                                        value: (viewModel.totalMetersTracked / 1000).toStringAsFixed(2),
                                        unit: "KM",
                                      ),
                                    ),
                                    Expanded(
                                      child: _StatDisplay(
                                        label: locale.time.toUpperCase(),
                                        value: _formatDuration(Duration(seconds: viewModel.totalSecondsElapsed)),
                                        unit: "",
                                      ),
                                    ),
                                    Expanded(
                                      child: _StatDisplay(
                                        label: locale.pace.toUpperCase(),
                                        value: viewModel.formattedCurrentPace,
                                        unit: "MIN/KM",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (viewModel.equippedBoost != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: ShapeDecoration(
                                      color: AppTheme.tertiaryColor.withAlpha(20),
                                      shape: BeveledRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: AppTheme.tertiaryColor.withAlpha(180),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(viewModel.equippedBoost!.icon, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                viewModel.equippedBoost!.getName(locale).toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.white.withAlpha(210),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  fontFamily: 'Oswald',
                                                  decoration: TextDecoration.none,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          viewModel.equippedBoost!.getEffectFormatted(),
                                          style: const TextStyle(
                                            color: AppTheme.secondaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            fontFamily: 'Oswald',
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (viewModel.pausedBySuspectedInvalid) ...[
                                  const SizedBox(height: 12),
                                  _SuspectedInvalidActivityBanner(viewModel: viewModel),
                                ],
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12, height: 16),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapActionButton(
                      icon: viewModel.playingState == PlayingState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: AppTheme.darkBackground.withAlpha(220),
                      iconColor: AppTheme.primaryColor,
                      borderColor: AppTheme.primaryColor,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        viewModel.onPushPlayButton();
                      },
                      shape: const StarBorder(
                        side: BorderSide(color: AppTheme.primaryColor, width: 2),
                        points: 6,
                        innerRadiusRatio: 0.86,
                        rotation: 30,
                        pointRounding: 0.15,
                      ),
                    ),
                    if (viewModel.playingState == PlayingState.paused) ...[
                      const SizedBox(width: 24),
                      _MapActionButton(
                        icon: Icons.stop,
                        color: Colors.redAccent.withAlpha(220),
                        iconColor: Colors.white,
                        borderColor: Colors.redAccent,
                        onTap: () async {
                          HapticFeedback.heavyImpact();
                          final nav = Navigator.of(context);
                          final scaf = ScaffoldMessenger.of(context);

                          final result = await viewModel.onPushStopButton();
                          debugPrint("ActivityScreen.onTap: result=$result");

                          if (result != null) {
                            if (result['activityResult'] == null) {
                              final bool isOffline = result['isOffline'] == true;
                              final String message = isOffline
                                  ? locale.activitySavedLocally
                                  : locale.errorSavingActivity;

                              scaf.showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: isOffline ? Colors.orangeAccent : Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }

                            nav.pushReplacementNamed(
                              AppRouter.summary,
                              arguments: result,
                            );
                          } else {
                            scaf.showSnackBar(
                              SnackBar(
                                content: Text(locale.errorSavingActivity),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        },
                        shape: const StarBorder(
                          side: BorderSide(color: Colors.white, width: 2),
                          points: 6,
                          innerRadiusRatio: 0.86,
                          rotation: 30,
                          pointRounding: 0.15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
  if (d.inHours > 0) {
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  } else {
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class _SuspectedInvalidActivityBanner extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _SuspectedInvalidActivityBanner({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: AppTheme.darkBackground.withAlpha(240),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: Colors.orangeAccent,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_sharp,
                color: Colors.orangeAccent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locale.suspectedInvalidTitle.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            viewModel.selectedActivityType == ActivityType.onFoot? locale.suspectedOnFootDescription(GameConfig.limitConsecutiveInvalidUnits) : locale.suspectedOnBikeDescription(GameConfig.limitConsecutiveInvalidUnits),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.3,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}



class _StatDisplay extends StatelessWidget {
  final String? label;
  final String value;
  final String unit;

  const _StatDisplay({this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label!,
              style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, decoration: TextDecoration.none),
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
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Oswald', decoration: TextDecoration.none),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivitySelectorSheet extends StatefulWidget {
  final ActivityViewModel viewModel;

  const _ActivitySelectorSheet({
    required this.viewModel,
  });

  @override
  State<_ActivitySelectorSheet> createState() => _ActivitySelectorSheetState();
}

class _ActivitySelectorSheetState extends State<_ActivitySelectorSheet> {
  int _km = 0;
  int _m = 0;
  int _h = 0;
  int _min = 0;
  int _sec = 0;
  int _paceMin = 0;
  int _paceSec = 0;

  @override
  void initState() {
    super.initState();
    final d = (widget.viewModel.selectedDistance != null && widget.viewModel.selectedDistance! > 0) ?
                widget.viewModel.selectedDistance :
                GameConfig.defaultObjectiveDistance;
    _km = (d! / 1000).floor();
    _m = (d % 1000).toInt();

    final t = (widget.viewModel.selectedTime != null && widget.viewModel.selectedTime!.inSeconds > 0) ?
                widget.viewModel.selectedTime :
                GameConfig.defaultObjectiveTime;
    _h = t!.inHours;
    _min = t.inMinutes.remainder(60);
    _sec = t.inSeconds.remainder(60);

    final p = (widget.viewModel.selectedPace != null && widget.viewModel.selectedPace! > 0) ?
                widget.viewModel.selectedPace :
                GameConfig.defaultObjectivePace;
    _paceMin = p!.toInt();
    _paceSec = ((p - _paceMin) * 60).round();
  }

  bool get _isValid {
    final training = widget.viewModel.selectedPreTrainingType ?? TrainingType.free;
    if (training == TrainingType.free) return true;
    if (training == TrainingType.distance) return (_km * 1000 + _m) > 0;
    if (training == TrainingType.time) return (_h * 3600 + _min * 60 + _sec) > 0;
    if (training == TrainingType.pace) return (_km * 1000 + _m) > 0 && (_paceMin * 60 + _paceSec) > 0;
    if (training == TrainingType.timeTrial) return (_km * 1000 + _m) > 0 && (_h * 3600 + _min * 60 + _sec) > 0;
    return false;
  }

  void _onConfirm() {
    if (!_isValid) return;

    double distance = 0.0;
    Duration time = Duration.zero;

    final activityType = widget.viewModel.selectedActivityType ?? ActivityType.onFoot;
    final training = widget.viewModel.selectedPreTrainingType ?? TrainingType.free;

    if (training == TrainingType.distance || training == TrainingType.pace || training == TrainingType.timeTrial) {
      distance = (_km * 1000.0) + _m;
    }
    if (training == TrainingType.time || training == TrainingType.timeTrial) {
      time = Duration(hours: _h, minutes: _min, seconds: _sec);
    }

    final double pace = _paceMin + (_paceSec / 60.0);

    widget.viewModel.setActivityConfig(
        activityType: activityType,
        trainingType: training,
        distance: distance,
        time: time,
        pace: pace,
        boost: widget.viewModel.selectedBoost
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final locale = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + bottomInset,
        ),
        decoration: const ShapeDecoration(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          color: AppTheme.darkBackground,
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale.setUpActivity.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.help_center_outlined, color: AppTheme.primaryColor),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showPointsCalculationDialog(context);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    locale.activity.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.8,
                    children: [
                      _ChoiceChip(
                        label: locale.onFoot,
                        icon: Icons.hiking_sharp,
                        isSelected: widget.viewModel.selectedActivityType == ActivityType.onFoot,
                        onSelected: () => widget.viewModel.selectedActivityType = ActivityType.onFoot,
                        color: Colors.red,
                      ),
                      _ChoiceChip(
                        label: locale.onBike,
                        icon: Icons.pedal_bike_sharp,
                        isSelected: widget.viewModel.selectedActivityType == ActivityType.onBike,
                        onSelected: () => widget.viewModel.selectedActivityType = ActivityType.onBike,
                        color: AppTheme.tertiaryColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    locale.training.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.8,
                    children: List.generate(widget.viewModel.trainings.length, (index) {
                      final training = widget.viewModel.trainings[index];
                      final isSelected = widget.viewModel.selectedPreTrainingType == training.type;
                      return _ChoiceChip(
                        label: training.type.getLocale(locale).toUpperCase(),
                        icon: training.type.getIcon(),
                        isSelected: isSelected,
                        onSelected: () => widget.viewModel.selectedPreTrainingType = training.type,
                        color: AppTheme.primaryColor,
                        multiplier: training.impactPoints.toString(),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  _TopToBottomObjectiveExpandable(
                    show: widget.viewModel.selectedPreTrainingType != TrainingType.free &&
                        widget.viewModel.selectedPreTrainingType != null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locale.setObjective.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontFamily: 'Oswald',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(0.0, -0.15),
                              end: Offset.zero,
                            ).animate(animation);

                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              ),
                            );
                          },
                          child: SizedBox(
                            key: ValueKey(widget.viewModel.selectedPreTrainingType),
                            width: double.infinity,
                            child: _buildObjectiveWheelInputs(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  if (widget.viewModel.availableBoosts.isNotEmpty) ...[
                    Text(
                      locale.boostsInInventory.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.8,
                      children: List.generate(widget.viewModel.onlyExistingInventory.length, (index) {
                        final boostInventory = widget.viewModel.onlyExistingInventory[index];
                        final isSelected = widget.viewModel.selectedBoost == boostInventory;
                        return _BoostSelectChip(
                          boostInventory: boostInventory,
                          isSelected: isSelected,
                          onTap: () {
                            if (isSelected) {
                              widget.viewModel.selectedBoost = null;
                            } else {
                              widget.viewModel.selectedBoost = boostInventory;
                            }
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],

                  _TopToBottomObjectiveExpandable(
                    show: widget.viewModel.selectedBoost != null,
                    child: widget.viewModel.selectedBoost != null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  final offsetAnimation = Tween<Offset>(
                                    begin: const Offset(0.0, -0.15),
                                    end: Offset.zero,
                                  ).animate(animation);

                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: offsetAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  key: ValueKey(widget.viewModel.selectedBoost!.id),
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: ShapeDecoration(
                                    color: AppTheme.secondaryColor.withAlpha(20),
                                    shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(color: AppTheme.secondaryColor.withAlpha(180), width: 1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.viewModel.selectedBoost!.getNameWithEffect(locale).toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.viewModel.selectedBoost!.getDescription(locale),
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.darkBackground,
                        disabledBackgroundColor: AppTheme.primaryColor.withAlpha(80),
                        shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      onPressed: _isValid ? () {
                        HapticFeedback.mediumImpact();
                        _onConfirm();
                      } : null,
                      child: Text(
                        locale.confirm.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  }

  Widget _buildObjectiveWheelInputs(BuildContext context) {
    final training = widget.viewModel.selectedPreTrainingType;
    final locale = AppLocalizations.of(context)!;

    if (training == TrainingType.distance) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.distance.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              fontFamily: 'Oswald',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildWheelPickerTile(
                  color: Colors.white,
                  pickers: [
                    _WheelPickerField(
                      value: _km,
                      min: 0,
                      max: 999,
                      onChanged: (v) => setState(() => _km = v),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('KM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Oswald')),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWheelPickerTile(
                  color: Colors.white,
                  pickers: [
                    _WheelPickerField(
                      value: _m,
                      min: 0,
                      max: 950,
                      step: 50,
                      onChanged: (v) => setState(() => _m = v),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Oswald')),
                    ),
                  ],
                ),
              ),
            ]
          ),
        ],
      );
    } else if (training == TrainingType.time) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.time.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              fontFamily: 'Oswald',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildWheelPickerTile(
                  color: Colors.white,
                  pickers: [
                    _WheelPickerField(
                      value: _h,
                      min: 0,
                      max: 23,
                      onChanged: (v) => setState(() => _h = v),
                    ),
                    const Text(
                      ':',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Oswald',
                      ),
                    ),
                    _WheelPickerField(
                      value: _min,
                      min: 0,
                      max: 59,
                      onChanged: (v) => setState(() => _min = v),
                    ),
                    const Text(
                      ':',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Oswald',
                      ),
                    ),
                    _WheelPickerField(
                      value: _sec,
                      min: 0,
                      max: 59,
                      step: 5,
                      onChanged: (v) => setState(() => _sec = v),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      );
    } else if (training == TrainingType.pace) {
      return
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.distance.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: 'Oswald',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildWheelPickerTile(
                      color: Colors.white,
                      pickers: [
                        _WheelPickerField(
                          value: _km,
                          min: 0,
                          max: 999,
                          onChanged: (v) => setState(() => _km = v),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('KM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Oswald')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildWheelPickerTile(
                      color: Colors.white,
                      pickers: [
                        _WheelPickerField(
                          value: _m,
                          min: 0,
                          max: 950,
                          step: 50,
                          onChanged: (v) => setState(() => _m = v),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Oswald')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                locale.pace.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: 'Oswald',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildWheelPickerTile(
                      color: Colors.white,
                      pickers: [
                        _WheelPickerField(
                          value: _paceMin,
                          min: 1,
                          max: 20,
                          onChanged: (v) => setState(() => _paceMin = v),
                        ),
                        const Text(
                          ':',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'Oswald',
                          ),
                        ),
                        _WheelPickerField(
                          value: _paceSec,
                          min: 0,
                          max: 59,
                          step: 5,
                          onChanged: (v) => setState(() => _paceSec = v),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('MIN/KM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Oswald')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

            ],
      );
    } else if (training == TrainingType.timeTrial) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.distance.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              fontFamily: 'Oswald',
            ),
          ),
          const SizedBox(height: 6),
          Row(
              children: [
                Expanded(
                  child: _buildWheelPickerTile(
                    color: Colors.white,
                    pickers: [
                      _WheelPickerField(
                        value: _km,
                        min: 0,
                        max: 999,
                        onChanged: (v) => setState(() => _km = v),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text('KM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Oswald')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWheelPickerTile(
                    color: Colors.white,
                    pickers: [
                      _WheelPickerField(
                        value: _m,
                        min: 0,
                        max: 950,
                        step: 50,
                        onChanged: (v) => setState(() => _m = v),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Oswald')),
                      ),
                    ],
                  ),
                ),
              ]
          ),
          const SizedBox(height: 6),
          Text(
            locale.time.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              fontFamily: 'Oswald',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildWheelPickerTile(
                  color: Colors.white,
                  pickers: [
                    _WheelPickerField(
                      value: _h,
                      min: 0,
                      max: 23,
                      onChanged: (v) => setState(() => _h = v),
                    ),
                    const Text(
                      ':',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Oswald',
                      ),
                    ),
                    _WheelPickerField(
                      value: _min,
                      min: 0,
                      max: 59,
                      onChanged: (v) => setState(() => _min = v),
                    ),
                    const Text(
                      ':',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Oswald',
                      ),
                    ),
                    _WheelPickerField(
                      value: _sec,
                      min: 0,
                      max: 59,
                      step: 5,
                      onChanged: (v) => setState(() => _sec = v),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildWheelPickerTile({
    String? label,
    required Color color,
    required List<Widget> pickers,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ShapeDecoration(
        color: Colors.white.withAlpha(15),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withAlpha(180), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)...[
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: pickers,
          ),
        ],
      ),
    );
  }
}

class _TopToBottomObjectiveExpandable extends StatefulWidget {
  final bool show;
  final Widget child;

  const _TopToBottomObjectiveExpandable({
    required this.show,
    required this.child,
  });

  @override
  State<_TopToBottomObjectiveExpandable> createState() => _TopToBottomObjectiveExpandableState();
}

class _TopToBottomObjectiveExpandableState extends State<_TopToBottomObjectiveExpandable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.show ? 1.0 : 0.0,
    );
    _anim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void didUpdateWidget(_TopToBottomObjectiveExpandable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _anim,
      axis: Axis.vertical,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        child: widget.child,
      ),
    );
  }
}

class _WheelPickerField extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final double? width;
  final ValueChanged<int> onChanged;

  const _WheelPickerField({
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    this.width = 44,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final count = ((max - min) ~/ step) + 1;
    final initialIndex = ((value.clamp(min, max) - min) ~/ step).clamp(0, count - 1);

    return SizedBox(
      height: 60,
      width: width,
      child: ListWheelScrollView.useDelegate(
        offAxisFraction: 0.0,
        dragStartBehavior: DragStartBehavior.down,
        itemExtent: 26,
        perspective: 0.004,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(initialItem: initialIndex),
        onSelectedItemChanged: (index) {
          HapticFeedback.vibrate();
          final val = min + (index * step);
          onChanged(val.clamp(min, max));
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, index) {
            final itemValue = min + (index * step);
            final isSelected = itemValue == value;
            return Center(
              child: Text(
                itemValue.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSelected ? 24 : 16,
                  fontFamily: 'Oswald',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color color;
  final String multiplier;

  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
    required this.color,
    this.multiplier = '',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: ShapeDecoration(
          color: isSelected
              ? color.withAlpha(50)
              : color.withAlpha(20),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? Colors.white
                  : color.withAlpha(120),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (multiplier.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                "x$multiplier",
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oswald',
                ),
              ),
            ],
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle_sharp,
                color: AppTheme.secondaryColor,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoostSelectChip extends StatelessWidget {
  final BoostInventory boostInventory;
  final bool isSelected;
  final VoidCallback onTap;

  const _BoostSelectChip({
    required this.boostInventory,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final int amount = boostInventory.quantity;
    final mainColor = AppTheme.tertiaryColor;

    final iconData = boostInventory.icon;
    final expandedBoostName = boostInventory.getName(locale).toUpperCase();
    final effectText = boostInventory.getEffectFormatted();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (amount <= 0) return;
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubicEmphasized,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: ShapeDecoration(
          color: isSelected
              ? mainColor.withAlpha(50)
              : (amount > 0 ? mainColor.withAlpha(25) : Colors.white.withAlpha(5)),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? Colors.white70
                  : (amount > 0 ? mainColor.withAlpha(140) : Colors.white12),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              iconData,
              color: isSelected ? Colors.white : (amount > 0 ? Colors.white70 : Colors.white24),
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expandedBoostName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected ? Colors.white : (amount > 0 ? Colors.white : Colors.white38),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  if (effectText.isNotEmpty)
                    Text(
                      effectText,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: isSelected ? AppTheme.secondaryColor : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: ShapeDecoration(
                color: isSelected
                    ? AppTheme.secondaryColor.withAlpha(220)
                    : (amount > 0 ? AppTheme.secondaryColor.withAlpha(180) : Colors.white12),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                "x$amount",
                style: TextStyle(
                  color: amount > 0 ? AppTheme.darkBackground : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle_sharp,
                color: AppTheme.secondaryColor,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;
  final ShapeBorder shape;

  const _MapActionButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black45,
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: InkWell(
          splashColor: color.withAlpha(200),
          customBorder: shape,
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 38.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HarActivityVisualizerWidget extends StatelessWidget {
  final HarActivity sensorActivity;

  const _HarActivityVisualizerWidget({required this.sensorActivity});

  IconData _getIcon() {
    switch (sensorActivity) {
      case HarActivity.walk:
        return Icons.directions_walk;
      case HarActivity.run:
        return Icons.directions_run;
      case HarActivity.bike:
        return Icons.directions_bike;
      case HarActivity.vehicle:
        return Icons.directions_car;
      case HarActivity.standing:
        return Icons.emoji_people_sharp;
      case HarActivity.unknown:
        return Icons.sensors;
    }
  }

  Color _getColor() {
    switch (sensorActivity) {
      case HarActivity.walk:
        return AppTheme.walkColor;
      case HarActivity.run:
        return AppTheme.runColor;
      case HarActivity.bike:
        return AppTheme.bikeColor;
      case HarActivity.standing:
      case HarActivity.vehicle:
        return Colors.orangeAccent;
      case HarActivity.unknown:
        return Colors.white38;
    }
  }

  int _getUnitPoints() {
    switch (sensorActivity) {
      case HarActivity.walk:
        return GameConfig.walkUnitPoints;
      case HarActivity.run:
        return GameConfig.runUnitPoints;
      case HarActivity.bike:
        return GameConfig.bikeUnitPoints;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = _getColor();
    final points = _getUnitPoints();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.85),
        shape: BeveledRectangleBorder(
          side: BorderSide(color: color.withValues(alpha: 0.8), width: 1.2),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sensorActivity.getLocale(locale).toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: ShapeDecoration(
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              color: points > 0 ? color.withValues(alpha: 0.2) : Colors.white10,
            ),
            child: Text(
              points > 0 ? '+$points PTS/5s' : '0 PTS',
              style: TextStyle(
                color: points > 0 ? color : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: sensorActivity == HarActivity.unknown ? Colors.amber : Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
}

void _showPointsCalculationDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withAlpha(180),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _PointsCalculationDialog();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final heightFactor = Tween<double>(begin: 0.001, end: 1.0).animate(curvedAnimation);

      return AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, innerChild) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1.0, heightFactor.value, 1.0),
            child: FadeTransition(
              opacity: animation,
              child: innerChild,
            ),
          );
        },
        child: child,
      );
    },
  );
}

class _PointsCalculationDialog extends StatelessWidget {
  const _PointsCalculationDialog();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(18),
        decoration: ShapeDecoration(
          color: AppTheme.darkBackground.withAlpha(245),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.tertiaryColor,
              width: 1.5,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.graphic_eq,
                    color: AppTheme.tertiaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.pointsCalculationTitle.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.0,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_walk_sharp, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            locale.harUnits.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: ShapeDecoration(
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          color: AppTheme.secondaryColor.withAlpha(180),
                        ),
                        child: Text(
                          locale.unitEquals(GameConfig.unitSeconds),
                          style: TextStyle(
                            color: AppTheme.darkBackground,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale.pointsCalculationDescription,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActivityPointCard(
                          label: locale.walk.toUpperCase(),
                          points: GameConfig.walkUnitPoints,
                          icon: Icons.directions_walk,
                          color: AppTheme.walkColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActivityPointCard(
                          label: locale.bike.toUpperCase(),
                          points: GameConfig.bikeUnitPoints,
                          icon: Icons.directions_bike,
                          color: AppTheme.bikeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActivityPointCard(
                          label: locale.run.toUpperCase(),
                          points: GameConfig.runUnitPoints,
                          icon: Icons.directions_run,
                          color: AppTheme.runColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),


              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'x ${locale.speedModifier.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  Text(
                    "/ 5s ${locale.unit.toLowerCase()}",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ]
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on_sharp, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          locale.whatAreImpactsTitle.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale.whatAreImpactsDescription(GameConfig.unitSeconds, GameConfig.baseMetersBetweenNodes),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.linear_scale, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          locale.trainingMultiplierTitle.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale.trainingMultiplierDescription,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppTheme.tertiaryColor,
                  ),
                  child: Text(
                    locale.ok.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityPointCard extends StatelessWidget {
  final String label;
  final int points;
  final IconData icon;
  final Color color;

  const _ActivityPointCard({
    required this.label,
    required this.points,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withAlpha(120), width: 1),
        ),
        color: color.withAlpha(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "+$points PTS",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
