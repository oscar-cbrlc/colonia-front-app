import 'dart:ui';
import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/enums/har_activity.dart';
import 'package:colonia_front_app/domain/models/enums/training_type.dart';
import 'package:colonia_front_app/domain/models/session/session_enums.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_viewmodel.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/territory_summary_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
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
      _showActivitySelector();
    });
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
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, decorationStyle: null),
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
              alignment: Alignment.topRight,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 124, right: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.viewModel.centerOnUser();
                        },
                        icon: const Icon(Icons.location_searching),
                        color: Colors.redAccent,
                        iconSize: 32,
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.viewModel.toggleShowPoints();
                        },
                        icon: Icon(
                          widget.viewModel.showPoints
                              ? Icons.shield_sharp
                              : Icons.shield_outlined,
                        ),
                        color: widget.viewModel.showPoints
                            ? AppTheme.primaryColor
                            : Colors.white38,
                        iconSize: 30,
                      ),
                    ],
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
            if (widget.viewModel.equippedBoost != null && widget.viewModel.playingState != PlayingState.stopped)
              Align(
                alignment: Alignment.centerLeft,
                child: _EquippedBoostBadge(boost: widget.viewModel.equippedBoost!)
              ),
            
            if (widget.viewModel.playingState != PlayingState.stopped)
              Align(
                alignment: Alignment.bottomCenter,
                child: _ActivityProgressPanel(viewModel: widget.viewModel),
              ),

            if (widget.viewModel.playingState == PlayingState.stopped)
              Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.viewModel.readyToStart) ...[
                      _PreActivityOverview(viewModel: widget.viewModel),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.viewModel.onPushPlayButton,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.secondaryColor,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                locale.start.toUpperCase(), 
                                style: const TextStyle(
                                  color: AppTheme.darkBackground, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _showActivitySelector();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.darkBackground.withAlpha(230),
                          foregroundColor: AppTheme.primaryColor,
                          splashFactory: InkRipple.splashFactory,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              locale.setUpActivity.toUpperCase(),
                              style: const TextStyle(color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold
                              )
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
          ],
        );
      },
    );
  }

  void _showActivitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivitySelectorSheet(viewModel: widget.viewModel),
      useSafeArea: true,
      showDragHandle: true,
    );
  }
}

class _PreActivityOverview extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _PreActivityOverview({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final TrainingType training = viewModel.selectedTrainingType ?? viewModel.selectedPreTrainingType ?? TrainingType.free;
          final BoostInventory? boost = viewModel.selectedBoost;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.all(20),
            decoration: ShapeDecoration(
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              color: AppTheme.darkBackground.withAlpha(240),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_walk, color: AppTheme.walkColor, size: 20),
                        SizedBox(width: 2),
                        Icon(Icons.directions_bike, color: AppTheme.bikeColor, size: 20),
                        SizedBox(width: 2),
                        Icon(Icons.directions_run, color: AppTheme.runColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          locale.realTimeHar,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.none),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: ShapeDecoration(
                        shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        color: AppTheme.primaryColor.withAlpha(40),
                      ),
                      child: Text(
                        training.getLocale(locale).toUpperCase(),
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.none),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (training == TrainingType.distance || training == TrainingType.pace || training == TrainingType.timeTrial)
                      _OverviewStat(
                        label: locale.distance.toUpperCase(),
                        value: (viewModel.selectedDistance! / 1000).toStringAsFixed(1),
                        unit: "KM",
                      ),
                    if (training == TrainingType.time || training == TrainingType.timeTrial)
                      _OverviewStat(
                        label: locale.time.toUpperCase(),
                        value: _formatDurationShort(viewModel.selectedTime!),
                        unit: "",
                      ),
                    if (training == TrainingType.pace)
                      _OverviewStat(
                        label: locale.targetPace.toUpperCase(),
                        value: viewModel.formattedSelectedPace,
                        unit: "MIN/KM",
                      ),
                  ],
                ),
                if (boost != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  Row(
                    children: [
                      Icon(boost.icon, color: AppTheme.tertiaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              boost.getName(locale).toUpperCase(),
                              style: const TextStyle(color: AppTheme.tertiaryColor, fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.none),
                            ),
                            Text(
                              boost.getDescription(locale),
                              style: const TextStyle(color: Colors.white54, fontSize: 12, decoration: TextDecoration.none),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MultiplierMini(label: locale.impact.toUpperCase(), multiplier: viewModel.currentMultiplier, color: Colors.redAccent),
                  ],
                )
              ],
            ),
          );
        }
    );
  }

  String _formatDurationShort(Duration d) {
    if (d.inHours > 0) return "${d.inHours}H ${d.inMinutes.remainder(60)}M";
    return "${d.inMinutes}M ${d.inSeconds.remainder(60)}S";
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _OverviewStat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Oswald', decoration: TextDecoration.none)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
            ]
          ],
        )
      ],
    );
  }
}

class _MultiplierMini extends StatelessWidget {
  final String label;
  final double multiplier;
  final Color color;
  const _MultiplierMini({required this.label, required this.multiplier, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
        Text("x${multiplier.toStringAsFixed(2)}", style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Oswald', decoration: TextDecoration.none)),
      ],
    );
  }
}

class _DistanceProgressPanel extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _DistanceProgressPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                color: AppTheme.primaryColor.withAlpha(30),
              ),
              child: _SegmentedProgressBar(
                progress: progress,
                color: AppTheme.primaryColor,
                isReversed: false,
              ),
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
                  Text(
                    "${((targetDistanceMeters - viewModel.totalMetersTracked).clamp(0, double.infinity) / 1000).toStringAsFixed(2)} KM ${locale.remaining.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      decoration: TextDecoration.none
                    ),
                  ),
              ],
            )
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                color: AppTheme.secondaryColor.withAlpha(30),
              ),
              child: _SegmentedProgressBar(
                progress: progress,
                color: AppTheme.secondaryColor,
                isReversed: true,
              ),
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
                        fontSize: 12,
                        decoration: TextDecoration.none
                    ),
                  ),
              ],
            )
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
      return "${twoDigits(d.inHours)}:$minutes:$secs ${locale.remaining.toUpperCase()} ";
    }
    return "$minutes:$secs ${locale.remaining.toUpperCase()}";
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                color: activityColor.withAlpha(30),
              ),
              child: _PaceBarEquilibrium(
                pace: currentPace,
                targetPace: targetPace,
                inPaceColor: AppTheme.successColor,
                outPaceColor: AppTheme.errorColor,
              ),
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
                Text(
                  "${locale.targetPace.toUpperCase()}: ${viewModel.formattedSelectedPace}",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    decoration: TextDecoration.none
                  ),
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

class _EquippedBoostBadge extends StatelessWidget {
  final BoostInventory boost;
  const _EquippedBoostBadge({required this.boost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
          side: BorderSide(color: Colors.white, width: 1.0),
        ),
        color: AppTheme.tertiaryColor.withAlpha(60),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(boost.icon, color: AppTheme.tertiaryColor, size: 28),
          const SizedBox(width: 4),
          Text(
            boost.getEffectFormatted(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityProgressPanel extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _ActivityProgressPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final HarActivity activity = viewModel.currentHarActivity;
        final TrainingType training = viewModel.selectedTrainingType ?? viewModel.selectedPreTrainingType ?? TrainingType.free;

        final IconData activityIcon = switch (activity) {
          HarActivity.walk => Icons.directions_walk,
          HarActivity.run => Icons.directions_run,
          HarActivity.bike => Icons.directions_bike,
          HarActivity.vehicle => Icons.directions_car,
          HarActivity.standing => Icons.emoji_people_sharp,
          HarActivity.unknown => Icons.sensors,
        };
        final Color activityColor = switch (activity) {
          HarActivity.walk => AppTheme.walkColor,
          HarActivity.run => AppTheme.runColor,
          HarActivity.bike => AppTheme.bikeColor,
          HarActivity.standing => Colors.orangeAccent,
          HarActivity.vehicle => Colors.orangeAccent,
          HarActivity.unknown => AppTheme.primaryColor,
        };
        final IconData trainingIcon = switch (training) {
          TrainingType.distance => Icons.straighten,
          TrainingType.time => Icons.timer,
          TrainingType.pace => Icons.linear_scale,
          TrainingType.timeTrial => Icons.av_timer_sharp,
          TrainingType.free => Icons.timer_off,
        };

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: ShapeDecoration(
            shape: BeveledRectangleBorder(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              side: BorderSide(
                color: activityColor,
                width: 1.5,
              )
            ),
            color: AppTheme.darkBackground.withAlpha(200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(activityIcon, color: activityColor, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        activity.getLocale(locale).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: ShapeDecoration(
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          color: AppTheme.secondaryColor.withAlpha(180),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(trainingIcon, color: Colors.white.withAlpha(200), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              training.getLocale(locale).toUpperCase(),
                              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatDisplay(
                    label: locale.distance.toUpperCase(),
                    value: (viewModel.totalMetersTracked / 1000).toStringAsFixed(2),
                    unit: "KM",
                  ),
                  _StatDisplay(
                    label: locale.time.toUpperCase(),
                    value: _formatDuration(Duration(seconds: viewModel.totalSecondsElapsed)),
                    unit: "",
                  ),
                  _StatDisplay(
                    label: locale.pace.toUpperCase(),
                    value: viewModel.formattedCurrentPace,
                    unit: "MIN/KM",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MultiplierMini(label: locale.impact.toUpperCase(), multiplier: viewModel.currentMultiplier, color: Colors.redAccent),
                ],
              ),
              if (training == TrainingType.distance || training == TrainingType.pace || training == TrainingType.timeTrial) ...[
                const SizedBox(height: 12),
                _DistanceProgressPanel(viewModel: viewModel),
              ],
              if (training == TrainingType.time || training == TrainingType.timeTrial) ...[
                const SizedBox(height: 12),
                _TimeProgressPanel(viewModel: viewModel),
              ],
              if (training == TrainingType.pace) ...[
                const SizedBox(height: 12),
                _PaceEquilibriumPanel(viewModel: viewModel),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
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
              ),
            ],
          ),
        );
      },
    );
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
}

class _StatDisplay extends StatelessWidget {
  final String? label;
  final String value;
  final String unit;

  const _StatDisplay({this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (label != null && label!.isNotEmpty)
          Text(
            label!,
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, decoration: TextDecoration.none),
          ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Oswald', decoration: TextDecoration.none),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActivitySelectorSheet extends StatefulWidget {
  final ActivityViewModel viewModel;
  const _ActivitySelectorSheet({required this.viewModel});

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
    final d = widget.viewModel.selectedDistance ?? 0.0;
    _km = (d / 1000).floor();
    _m = (d % 1000).toInt();

    final t = widget.viewModel.selectedTime ?? Duration.zero;
    _h = t.inHours;
    _min = t.inMinutes.remainder(60);
    _sec = t.inSeconds.remainder(60);

    final p = widget.viewModel.selectedPace ?? 5.5;
    _paceMin = p.toInt();
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

    final training = widget.viewModel.selectedPreTrainingType ?? TrainingType.free;
    final activity = widget.viewModel.selectedPreActivity ?? HarActivity.walk;

    if (training == TrainingType.distance || training == TrainingType.pace || training == TrainingType.timeTrial) {
      distance = (_km * 1000.0) + _m;
    }
    if (training == TrainingType.time || training == TrainingType.timeTrial) {
      time = Duration(hours: _h, minutes: _min, seconds: _sec);
    }

    final double pace = _paceMin + (_paceSec / 60.0);
    
    widget.viewModel.setActivityConfig(
        activity: activity,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubicEmphasized,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + bottomInset,
      ),
      decoration: ShapeDecoration(
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        color: AppTheme.darkBackground.withAlpha(240),
      ),
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
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  locale.training.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                    decoration: TextDecoration.none
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    _ChoiceChip(
                      label: locale.free,
                      icon: Icons.timer_off,
                      isSelected: widget.viewModel.selectedPreTrainingType == TrainingType.free,
                      onSelected: () => widget.viewModel.selectedPreTrainingType = TrainingType.free,
                      color: AppTheme.primaryColor,
                    ),
                    _ChoiceChip(
                      label: locale.distance,
                      icon: Icons.straighten,
                      isSelected: widget.viewModel.selectedPreTrainingType == TrainingType.distance,
                      onSelected: () => widget.viewModel.selectedPreTrainingType = TrainingType.distance,
                      color: AppTheme.primaryColor,
                    ),
                    _ChoiceChip(
                      label: locale.time,
                      icon: Icons.timer,
                      isSelected: widget.viewModel.selectedPreTrainingType == TrainingType.time,
                      onSelected: () => widget.viewModel.selectedPreTrainingType = TrainingType.time,
                      color: AppTheme.primaryColor,
                    ),
                    _ChoiceChip(
                      label: locale.pace,
                      icon: Icons.linear_scale,
                      isSelected: widget.viewModel.selectedPreTrainingType == TrainingType.pace,
                      onSelected: () => widget.viewModel.selectedPreTrainingType = TrainingType.pace,
                      color: AppTheme.primaryColor,
                    ),
                    _ChoiceChip(
                      label: locale.timeTrial,
                      icon: Icons.av_timer_sharp,
                      isSelected: widget.viewModel.selectedPreTrainingType == TrainingType.timeTrial,
                      onSelected: () => widget.viewModel.selectedPreTrainingType = TrainingType.timeTrial,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (widget.viewModel.selectedPreTrainingType != TrainingType.free && widget.viewModel.selectedPreTrainingType != null) ...[
                  Text(
                    locale.setObjective.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                      decoration: TextDecoration.none
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildObjectiveInputs(context),
                  const SizedBox(height: 24),
                ],

                if (widget.viewModel.availableBoosts.isNotEmpty) ...[
                  Text(
                    locale.boosts.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                      decoration: TextDecoration.none
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: widget.viewModel.availableBoosts.length,
                    itemBuilder: (context, index) {
                      final boost = widget.viewModel.availableBoosts[index];
                      final isSelected = widget.viewModel.selectedBoost == boost;
                      final int count = boost.quantity;
                      
                      return GestureDetector(
                        onTap: () {
                          if (count <= 0) return;
                          if (isSelected) {
                            widget.viewModel.selectedBoost = null;
                          } else {
                            widget.viewModel.selectedBoost = boost;
                          }
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: ShapeDecoration(
                                color: isSelected 
                                    ? AppTheme.tertiaryColor 
                                    : count > 0 
                                        ? Colors.white.withAlpha(20) 
                                        : Colors.white.withAlpha(5),
                                shape: BeveledRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? Colors.white : AppTheme.tertiaryColor.withAlpha(100),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(boost.icon, color: Colors.white),
                                  const SizedBox(height: 4),
                                  Text(
                                    boost.getName(locale).toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                right: 1.5,
                                top: 1.5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: ShapeDecoration(
                                      color: isSelected? AppTheme.secondaryColor.withAlpha(180): AppTheme.secondaryColor.withAlpha(30),
                                      shape:  BeveledRectangleBorder(
                                        borderRadius: BorderRadius.only(topRight: Radius.circular(11)),
                                        side: BorderSide(color: isSelected? AppTheme.secondaryColor.withAlpha(100) : Colors.transparent, width: 0.5)
                                      )
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 22,
                                    minHeight: 22,
                                  ),
                                  child: Text(
                                    "$count",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.viewModel.selectedBoost != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(0),
                      border: Border.all(color: AppTheme.tertiaryColor.withAlpha(210)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.viewModel.selectedBoost!.getName(locale).toUpperCase(),
                          style: const TextStyle(color: AppTheme.tertiaryColor, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.none),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          widget.viewModel.selectedBoost!.getDescription(locale),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.none),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  locale.impact.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                    decoration: TextDecoration.none
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MultiplierItem(
                        label: locale.impact.toUpperCase(),
                        multiplier: widget.viewModel.currentMultiplier,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showPointsCalculationDialog(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.help_outline_sharp,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            locale.howArePointsCalculated,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isValid ? _onConfirm : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.white10,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        locale.confirm.toUpperCase(), 
                        style: TextStyle(color: _isValid ? Colors.black87 : Colors.white24) 
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildObjectiveInputs(BuildContext context) {
    final training = widget.viewModel.selectedPreTrainingType;
    final locale = AppLocalizations.of(context)!;
    
    Widget subtitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );

    if (training == TrainingType.distance) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          subtitle(locale.distance),
          Row(
            children: [
              Expanded(
                  child: _NumberPickerField(
                      label: locale.km.toUpperCase(),
                      value: _km,
                      min: 0,
                      max: 99,
                      onChanged: (v) => setState(() => _km = v))
              ),
              const SizedBox(width: 16),
              Expanded(child: _NumberPickerField(
                  label: locale.meters.toUpperCase(),
                  value: _m,
                  min: 0,
                  max: 999,
                  step: 50,
                  onChanged: (v) => setState(() => _m = v))),
            ],
          ),
        ],
      );
    } else if (training == TrainingType.time) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          subtitle(locale.time),
          Row(
            children: [
              Expanded(child: _NumberPickerField(
                  label: locale.hours.toUpperCase(),
                  value: _h,
                  min: 0,
                  max: 23,
                  onChanged: (v) => setState(() => _h = v))),
              const SizedBox(width: 8),
              Expanded(child: _NumberPickerField(
                  label: locale.min.toUpperCase(),
                  value: _min,
                  min: 0,
                  max: 59,
                  onChanged: (v) => setState(() => _min = v))),
              const SizedBox(width: 8),
              Expanded(child: _NumberPickerField(
                  label: locale.sec.toUpperCase(),
                  value: _sec,
                  min: 0,
                  max: 59,
                  step: 10,
                  onChanged: (v) => setState(() => _sec = v))),
            ],
          ),
        ],
      );
    } else if (training == TrainingType.pace) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          subtitle(locale.distance),
          Row(
            children: [
              Expanded(child: _NumberPickerField(
                  label: locale.km.toUpperCase(),
                  value: _km,
                  min: 0,
                  max: 99,
                  onChanged: (v) => setState(() => _km = v))),
              const SizedBox(width: 16),
              Expanded(child: _NumberPickerField(
                  label: locale.meters.toUpperCase(),
                  value: _m,
                  min: 0,
                  max: 999,
                  step: 50,
                  onChanged: (v) => setState(() => _m = v))),
            ],
          ),
          const SizedBox(height: 16),
          subtitle(locale.targetPace),
          Row(
            children: [
              Expanded(child: _NumberPickerField(
                  label: locale.min.toUpperCase(),
                  value: _paceMin,
                  min: 2,
                  max: 20,
                  onChanged: (v) => setState(() => _paceMin = v))),
              const SizedBox(width: 12),
              Expanded(child: _NumberPickerField(
                  label: locale.sec.toUpperCase(),
                  value: _paceSec,
                  min: 0,
                  max: 59,
                  step: 5,
                  onChanged: (v) => setState(() => _paceSec = v))),
            ],
          ),
        ],
      );
    } else if (training == TrainingType.timeTrial) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          subtitle(locale.distance),
          Row(
            children: [
              Expanded(child: _NumberPickerField(
                  label: locale.km.toUpperCase(),
                  value: _km,
                  min: 0,
                  max: 99,
                  onChanged: (v) => setState(() => _km = v))),
              const SizedBox(width: 16),
              Expanded(child: _NumberPickerField(
                  label: locale.meters.toUpperCase(),
                  value: _m,
                  min: 0,
                  max: 999,
                  step: 50,
                  onChanged: (v) => setState(() => _m = v))),
            ],
          ),
          const SizedBox(height: 16),
          subtitle(locale.time),
          Row(
            children: [
              Expanded(child: _NumberPickerField(
                  label: locale.hours.toUpperCase(),
                  value: _h,
                  min: 0,
                  max: 23,
                  onChanged: (v) => setState(() => _h = v))),
              const SizedBox(width: 12),
              Expanded(child: _NumberPickerField(
                  label: locale.min.toUpperCase(),
                  value: _min,
                  min: 0,
                  max: 59,
                  onChanged: (v) => setState(() => _min = v))),
              const SizedBox(width: 12),
              Expanded(child: _NumberPickerField(
                  label: locale.sec.toUpperCase(),
                  value: _sec,
                  min: 0,
                  max: 59,
                  step: 10,
                  onChanged: (v) => setState(() => _sec = v))),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _NumberPickerField extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _NumberPickerField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label, 
            style: const TextStyle(
              color: Colors.white54, 
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              decoration: TextDecoration.none
            )
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              _PickerButton(
                icon: Icons.remove,
                onPressed: value > min ? () => onChanged(value - step < min ? min : value - step) : null,
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'Oswald', 
                      decoration: TextDecoration.none
                    ),
                  ),
                ),
              ),
              _PickerButton(
                icon: Icons.add,
                onPressed: value < max ? () => onChanged(value + step > max ? max : value + step) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _PickerButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: double.infinity,
        alignment: Alignment.center,
        child: Icon(
          icon, 
          size: 16, 
          color: onPressed != null ? AppTheme.primaryColor : Colors.white10
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

  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: isSelected ? color : color.withAlpha(20),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.white : color.withAlpha(100),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.darkBackground : Colors.white,
              size: 20,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppTheme.darkBackground : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiplierItem extends StatelessWidget {
  final String label;
  final double multiplier;
  final Color color;

  const _MultiplierItem({required this.label, required this.multiplier, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
        ),
        const SizedBox(height: 4),
        Text(
          "x${multiplier.toStringAsFixed(2)}",
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Oswald', decoration: TextDecoration.none),
        ),
      ],
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
            width: 72,
            height: 72,
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

  String _getLabel() {
    switch (sensorActivity) {
      case HarActivity.walk:
        return 'WALKING';
      case HarActivity.run:
        return 'RUNNING';
      case HarActivity.bike:
        return 'CYCLING';
      case HarActivity.vehicle:
        return 'IN VEHICLE';
      case HarActivity.standing:
        return 'STANDING';
      case HarActivity.unknown:
        return 'ANALYZING...';
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
    final color = _getColor();
    final points = _getUnitPoints();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.85),
        shape: BeveledRectangleBorder(
          side: BorderSide(color: color.withValues(alpha: 0.8), width: 1.5),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
      ),

    );
  }
}

void _showPointsCalculationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _PointsCalculationDialog(),
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
              color: AppTheme.primaryColor.withAlpha(100),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.graphic_eq,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.pointsCalculationTitle.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
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
                      Text(
                        locale.harUnits.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                          decoration: TextDecoration.none,
                        ),
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

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: Text(
                    locale.ok.toUpperCase(),
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text(
              "/ 5s unit",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
