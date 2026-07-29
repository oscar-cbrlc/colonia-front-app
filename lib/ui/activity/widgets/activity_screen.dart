import 'dart:ui';
import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/domain/models/session/session_enums.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_viewmodel.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
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
  Widget get _activityGroup => Visibility(
      visible: widget.viewModel.playingState != PlayingState.playing,
      child: Align(
        alignment: Alignment.bottomRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 48.0, right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(17, -41),
                  child: _FloatingHexMenu(
                    mainIcon: Icons.shield_rounded,
                    mainIconPressed: Icons.close,
                    mainColor: AppTheme.tertiaryColor.withAlpha(90),
                    mainIconColor: AppTheme.primaryColor,
                    mainBorderColor: AppTheme.tertiaryColor,
                    menuColor: AppTheme.tertiaryColor.withAlpha(10),
                    menuIconColor: AppTheme.tertiaryColor,
                    menuBorderColor: AppTheme.primaryColor,
                    menuItems: [
                      _MenuAction(
                        icon: Icons.shield_rounded,
                        onTap: () {
                          HapticFeedback.lightImpact();

                        },
                      ),
                      _MenuAction(
                        icon: Icons.edit,
                        onTap: () {
                          HapticFeedback.lightImpact();

                        },
                      ),
                      _MenuAction(
                        icon: Icons.shield_sharp,
                        onTap: () {
                          HapticFeedback.lightImpact();

                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FloatingHexMenu(
                      mainIcon: Icons.timeline_sharp,
                      mainIconPressed: Icons.close,
                      mainColor: AppTheme.tertiaryColor.withAlpha(90),
                      mainIconColor: AppTheme.primaryColor,
                      mainBorderColor: AppTheme.tertiaryColor,
                      menuColor: AppTheme.tertiaryColor.withAlpha(10),
                      menuIconColor: AppTheme.tertiaryColor,
                      menuBorderColor: AppTheme.primaryColor,
                      menuItems: [
                        _MenuAction(
                          icon: Icons.timeline_sharp,
                          onTap: () {
                            HapticFeedback.lightImpact();

                          },
                        ),
                        _MenuAction(
                          icon: Icons.timer,
                          onTap: () {
                            HapticFeedback.lightImpact();

                          },
                        ),
                        _MenuAction(
                          icon: Icons.linear_scale_rounded,
                          onTap: () {
                            HapticFeedback.lightImpact();

                          },
                        ),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: _FloatingHexMenu (
                        mainIcon: Icons.directions_walk,
                        mainIconPressed: Icons.close,
                        mainColor: AppTheme.tertiaryColor.withAlpha(90),
                        mainIconColor: AppTheme.primaryColor,
                        mainBorderColor: AppTheme.tertiaryColor,
                        menuColor: AppTheme.tertiaryColor.withAlpha(10),
                        menuIconColor: AppTheme.tertiaryColor,
                        menuBorderColor: AppTheme.primaryColor,
                        menuItems: [
                          _MenuAction(
                            icon: Icons.directions_walk,
                            onTap: () {
                              HapticFeedback.lightImpact();

                            },
                          ),
                          _MenuAction(
                            icon: Icons.directions_run,
                            onTap: () {
                              HapticFeedback.lightImpact();

                            },
                          ),
                          _MenuAction(
                            icon: Icons.directions_bike,
                            onTap: () {
                              HapticFeedback.lightImpact();

                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
  );


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
              key: const ValueKey("mapWidget"),
              styleUri: mapbox.MapboxStyles.STANDARD,
              onMapCreated: widget.viewModel.onMapCreated,
              onStyleLoadedListener: (data) => widget.viewModel.onStyleLoaded(),
              onCameraChangeListener: (data) => widget.viewModel.onCameraChanged(data),
              viewport: widget.viewModel.viewport ?? mapbox.CameraViewportState(
                center: mapbox.Point(coordinates: mapbox.Position(0, 0)),
                zoom: 12.0,
              ),
            ),

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

            //_activityGroup,

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
                    if (widget.viewModel.readyToStart)
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
                            child: Text(locale.start.toUpperCase(), style: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showActivitySelector,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.darkBackground.withAlpha(230),
                        ),
                        child: Text(locale.setUpActivity.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
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


  void handlePushPlayButton() {
    widget.viewModel.onPushPlayButton();
  }


  void _showActivitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivitySelectorSheet(viewModel: widget.viewModel),
    );
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
        final double targetDistance = viewModel.selectedDistance ?? 0.0;
        final double progress = targetDistance > 0
            ? (viewModel.totalMetersTracked / targetDistance)
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
                if (targetDistance > 0)
                  Text(
                    "${((targetDistance - viewModel.totalMetersTracked).clamp(0, double.infinity) / 1000).toStringAsFixed(2)} KM REMAINING",
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
                    _formatRemainingTime(targetSeconds - viewModel.totalSecondsElapsed.toDouble()),
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

  String _formatRemainingTime(double seconds) {
    if (seconds <= 0) return "TIME UP";
    final Duration d = Duration(seconds: seconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String secs = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$minutes:$secs REMAINING";
    }
    return "$minutes:$secs REMAINING";
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
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final double targetPace = viewModel.selectedPace?.toDouble() ?? 0.0;
        final double currentPace = viewModel.currentPace;
        final String activity = viewModel.selectedActivity ?? "walk";
        final Color activityColor = activity == "walk"
            ? AppTheme.walkColor
            : activity == "run"
                ? AppTheme.runColor
                : AppTheme.bikeColor;

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
                  "BEHIND",
                  style: TextStyle(
                    color: currentPace > targetPace ? activityColor : Colors.white24,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    decoration: TextDecoration.none
                  ),
                ),
                Text(
                  "TARGET PACE: ${targetPace.toStringAsFixed(1)}",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    decoration: TextDecoration.none
                  ),
                ),
                Text(
                  "AHEAD",
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

class _ActivityProgressPanel extends StatelessWidget {
  final ActivityViewModel viewModel;
  const _ActivityProgressPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final String activity = viewModel.selectedActivity ?? "walk";
        final String training = viewModel.selectedPreTrainingName ?? "free";
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

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: ShapeDecoration(
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              side: BorderSide(
                color: activityColor,
                width: 1.5,
              )
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
                      Icon(activityIcon, color: activityColor, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        (viewModel.selectedActivity ?? "").toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, decoration: TextDecoration.none),
                      ),
                    ],
                  ),
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
                          Icon(trainingIcon, color: AppTheme.lightBackground, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            (viewModel.selectedTrainingName ?? locale.free).toUpperCase(),
                            style: TextStyle(color: AppTheme.lightBackground.withAlpha(240), fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                          ),
                        ],
                    ),
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
                value: viewModel.currentPace.toStringAsFixed(1),
                unit: "MIN/KM",
              ),
            ],
          ),
              if (training == 'distance' || training == 'pace' || training == 'timeTrial') ...[
                const SizedBox(height: 12),
                _DistanceProgressPanel(viewModel: viewModel),
              ],
              if (training == 'time' || training == 'timeTrial') ...[
                const SizedBox(height: 12),
                _TimeProgressPanel(viewModel: viewModel),
              ],
              if (training == 'pace' || training == 'timeTrial') ...[
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
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            viewModel.onPushStopButton();
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
  final String label;
  final String value;
  final String unit;

  const _StatDisplay({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1, decoration: TextDecoration.none),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Oswald', decoration: TextDecoration.none),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
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
  late final TextEditingController _kmController = TextEditingController(text: (widget.viewModel.selectedDistance != null ? (widget.viewModel.selectedDistance! ~/ 1000).toString() : "0"));
  late final TextEditingController _mController = TextEditingController(text: (widget.viewModel.selectedDistance != null ? (widget.viewModel.selectedDistance! % 1000).toInt().toString() : "0"));
  late final TextEditingController _hController = TextEditingController(text: (widget.viewModel.selectedTime?.inHours.toString() ?? "0"));
  late final TextEditingController _minController = TextEditingController(text: (widget.viewModel.selectedTime?.inMinutes.remainder(60).toString() ?? "0"));
  late final TextEditingController _secController = TextEditingController(text: (widget.viewModel.selectedTime?.inSeconds.remainder(60).toString() ?? "0"));
  late final TextEditingController _paceController = TextEditingController(text: widget.viewModel.selectedPace?.toString() ?? "0.0");


  @override
  void dispose() {
    _kmController.dispose();
    _mController.dispose();
    _hController.dispose();
    _minController.dispose();
    _secController.dispose();
    _paceController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final double km = double.tryParse(_kmController.text) ?? 0;
    final double m = double.tryParse(_mController.text) ?? 0;
    final int h = int.tryParse(_hController.text) ?? 0;
    final int min = int.tryParse(_minController.text) ?? 0;
    final int sec = int.tryParse(_secController.text) ?? 0;
    final double pace = double.tryParse(_paceController.text) ?? 0.0;

    double distance = 0.0;
    Duration time = Duration();

    final training = widget.viewModel.selectedPreTrainingName ?? "free";
    final activity = widget.viewModel.selectedPreActivity ?? "walk";

    if (training == "distance" || training == "pace" || training == "timeTrial") {
      distance = (km * 1000) + m;
    }
    if (training == "time" || training == "timeTrial") {
      time = Duration(hours: h, minutes: min, seconds: sec);
    }
    widget.viewModel.setActivityConfig(
        activity: activity,
        training: training,
        distance: distance,
        time: time,
        pace: pace
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final locale = AppLocalizations.of(context)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
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
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: ListenableBuilder(
            listenable: Listenable.merge([widget.viewModel, _kmController, _mController, _hController, _minController, _secController]),
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
                      locale.activity.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
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
                          label: locale.walk,
                          icon: Icons.directions_walk,
                          isSelected: widget.viewModel.selectedPreActivity == "walk",
                          onSelected: () => widget.viewModel.selectedPreActivity = "walk",
                          color: AppTheme.walkColor,
                        ),
                        _ChoiceChip(
                          label: locale.run,
                          icon: Icons.directions_run,
                          isSelected: widget.viewModel.selectedPreActivity == "run",
                          onSelected: () => widget.viewModel.selectedPreActivity = "run",
                          color: AppTheme.runColor,
                        ),
                        _ChoiceChip(
                          label: locale.bike,
                          icon: Icons.directions_bike,
                          isSelected: widget.viewModel.selectedPreActivity == "bike",
                          onSelected: () => widget.viewModel.selectedPreActivity = "bike",
                          color: AppTheme.bikeColor,
                        ),
                      ]
                    ),
                    const SizedBox(height: 24),
                    Text(
                      locale.training.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
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
                          isSelected: widget.viewModel.selectedPreTrainingName == "free",
                          onSelected: () => widget.viewModel.selectedPreTrainingName = "free",
                          color: AppTheme.primaryColor,
                        ),
                        _ChoiceChip(
                          label: locale.distance,
                          icon: Icons.straighten,
                          isSelected: widget.viewModel.selectedPreTrainingName == "distance",
                          onSelected: () => widget.viewModel.selectedPreTrainingName = "distance",
                          color: AppTheme.primaryColor,
                        ),
                        _ChoiceChip(
                          label: locale.time,
                          icon: Icons.timer,
                          isSelected: widget.viewModel.selectedPreTrainingName == "time",
                          onSelected: () => widget.viewModel.selectedPreTrainingName = "time",
                          color: AppTheme.primaryColor,
                        ),
                        _ChoiceChip(
                          label: locale.pace,
                          icon: Icons.linear_scale,
                          isSelected: widget.viewModel.selectedPreTrainingName == "pace",
                          onSelected: () => widget.viewModel.selectedPreTrainingName = "pace",
                          color: AppTheme.primaryColor,
                        ),
                        _ChoiceChip(
                          label: locale.timeTrial,
                          icon: Icons.av_timer_sharp,
                          isSelected: widget.viewModel.selectedPreTrainingName == "timeTrial",
                          onSelected: () => widget.viewModel.selectedPreTrainingName = "timeTrial",
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (widget.viewModel.selectedPreTrainingName != "free" && widget.viewModel.selectedPreTrainingName != null) ...[
                      Text(
                        locale.setObjective.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildObjectiveInputs(context),
                      const SizedBox(height: 32),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onConfirm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: Text(locale.confirm.toUpperCase(), style: TextStyle(color: Colors.black87) ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveInputs(BuildContext context) {
    final training = widget.viewModel.selectedPreTrainingName;
    final locale = AppLocalizations.of(context)!;
    if (training == "distance") {
      return Row(
        children: [
          Expanded(
              child: _TargetInputField(
                  controller: _kmController,
                  inputType: TextInputType.number,
                  label: locale.km.toUpperCase(),
                  value: (widget.viewModel.selectedDistance != null ? (widget.viewModel.selectedDistance! ~/ 1000) : 0))
          ),
          const SizedBox(width: 16),
          Expanded(child: _TargetInputField(
              controller: _mController,
              inputType: TextInputType.number,
              label: locale.meters.toUpperCase(),
              value: int.tryParse(_mController.text) ?? 0)),
        ],
      );
    } else if (training == "time") {
      return Row(
        children: [
          Expanded(child: _TargetInputField(
              controller: _hController,
              inputType: TextInputType.number,
              label: locale.hours.toUpperCase(),
              value: int.tryParse(_hController.text) ?? 0)),
          const SizedBox(width: 12),
          Expanded(child: _TargetInputField(
              controller: _minController,
              inputType: TextInputType.number,
              label: locale.min.toUpperCase(),
              value: int.tryParse(_minController.text) ?? 0)),
          const SizedBox(width: 12),
          Expanded(child: _TargetInputField(
              controller: _secController,
              inputType: TextInputType.number,
              label: locale.sec.toUpperCase(),
              value: int.tryParse(_secController.text) ?? 0)),
        ],
      );
    } else if (training == "pace") {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _TargetInputField(
                  controller: _kmController,
                  inputType: TextInputType.number,
                  label: locale.km.toUpperCase(),
                  value: int.tryParse(_kmController.text) ?? 0)),
              const SizedBox(width: 16),
              Expanded(child: _TargetInputField(
                  controller: _mController,
                  inputType: TextInputType.number,
                  label: locale.meters.toUpperCase(),
                  value: int.tryParse(_mController.text) ?? 0)),
            ],
          ),
          const SizedBox(height: 16),
          _TargetInputField(
              controller: _paceController,
              inputType: const TextInputType.numberWithOptions(decimal: true),
              label: locale.targetPace.toUpperCase(),
              value: double.tryParse(_paceController.text) ?? 0.0),
        ],
      );
    } else if (training == "timeTrial") {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _TargetInputField(
                  controller: _kmController,
                  inputType: TextInputType.number,
                  label: locale.km.toUpperCase(),
                  value: int.tryParse(_kmController.text) ?? 0)),
              const SizedBox(width: 16),
              Expanded(child: _TargetInputField(
                  controller: _mController,
                  inputType: TextInputType.number,
                  label: locale.meters.toUpperCase(),
                  value: int.tryParse(_mController.text) ?? 0)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TargetInputField(
                  controller: _hController,
                  inputType: TextInputType.number,
                  label: locale.hours.toUpperCase(),
                  value: int.tryParse(_hController.text) ?? 0)),
              const SizedBox(width: 12),
              Expanded(child: _TargetInputField(
                  controller: _minController,
                  inputType: TextInputType.number,
                  label: locale.min.toUpperCase(),
                  value: int.tryParse(_minController.text) ?? 0)),
              const SizedBox(width: 12),
              Expanded(child: _TargetInputField(
                  controller: _secController,
                  inputType: TextInputType.number,
                  label: locale.sec.toUpperCase(),
                  value: int.tryParse(_secController.text) ?? 0)),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _TargetInputField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType inputType;
  final String label;
  final num value;

  const _TargetInputField({required this.controller, required this.inputType, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: inputType,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          inputFormatters: [
            inputType == const TextInputType.numberWithOptions(decimal: true) ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')) : FilteringTextInputFormatter.digitsOnly
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withAlpha(10),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
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
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTheme.darkBackground : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuAction {
  final IconData icon;
  final VoidCallback onTap;
  _MenuAction({required this.icon, required this.onTap});
}

class _FloatingHexMenu extends StatefulWidget {
  final IconData mainIcon;
  final IconData mainIconPressed;
  final List<_MenuAction> menuItems;
  final Color mainColor;
  final Color mainIconColor;
  final Color mainBorderColor;
  final Color menuColor;
  final Color menuIconColor;
  final Color menuBorderColor;

  const _FloatingHexMenu({
    required this.mainIcon,
    required this.mainIconPressed,
    required this.menuItems,
    required this.mainColor,
    required this.mainIconColor,
    required this.mainBorderColor,
    required this.menuColor,
    required this.menuIconColor,
    required this.menuBorderColor,
  });

  @override
  State<_FloatingHexMenu> createState() => _FloatingHexMenuState();
}

class _FloatingHexMenuState extends State<_FloatingHexMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInOutCubicEmphasized,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 72,
          height: 72 + (widget.menuItems.length * 63.0 * _expandAnimation.value),
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              ...List.generate(widget.menuItems.length, (index) {
                return _buildExpandingItem(
                  index: index,
                  action: widget.menuItems[index],
                );
              }),

              _MapActionButton(
                icon: _isOpen ? widget.mainIconPressed : widget.mainIcon,
                color: widget.mainColor,
                iconColor: widget.mainIconColor,
                borderColor: widget.mainBorderColor,
                onTap: _toggle,
                shape: StarBorder(
                  side: BorderSide(color: widget.mainBorderColor, width: 2),
                  points: 6,
                  innerRadiusRatio: 0.86,
                  rotation: 30,
                  pointRounding: 0.15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandingItem({required int index, required _MenuAction action}) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final double offset = (index + 1) * 63.0 * _expandAnimation.value;
        return Positioned(
          bottom: offset,
          child: Transform.translate(
            offset: Offset(0, (1 - _expandAnimation.value) * 15),
            child: Opacity(
              opacity: _expandAnimation.value,
              child: _MapActionButton(
                icon: action.icon,
                color: widget.menuColor,
                iconColor: widget.menuIconColor,
                borderColor: widget.menuBorderColor,
                onTap: () {
                  _toggle();
                  action.onTap();
                },
                shape: StarBorder(
                  side: BorderSide(color: widget.menuBorderColor, width: 2),
                  points: 6,
                  innerRadiusRatio: 0.86,
                  rotation: 30,
                  pointRounding: 0.15,
                ),
              ),
            ),
          ),
        );
      },
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
