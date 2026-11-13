import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/domain/models/active_challenge.dart';
import 'package:colonia_front_app/domain/models/activity_result.dart';
import 'package:colonia_front_app/domain/models/enums/training_type.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_summary_viewmodel.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/utils/time_converter.dart';

class SummaryExpandableCard extends StatefulWidget {
  final ActivitySummaryViewModel viewModel;
  final bool initiallyExpanded;

  const SummaryExpandableCard({
    super.key,
    required this.viewModel,
    this.initiallyExpanded = true,
  });

  @override
  State<SummaryExpandableCard> createState() => _SummaryExpandableCardState();
}

class _SummaryExpandableCardState extends State<SummaryExpandableCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final vm = widget.viewModel;
    final session = vm.session;

    final bool hasWalk = session.secondsWalk > 0 || session.distanceWalk > 0;
    final bool hasRun = session.secondsRun > 0 || session.distanceRun > 0;
    final bool hasBike = session.secondsBike > 0 || session.distanceBike > 0;

    final trainingIcon = switch (vm.trainingType) {
      TrainingType.distance => Icons.straighten,
      TrainingType.time => Icons.timer,
      TrainingType.pace => Icons.linear_scale,
      TrainingType.timeTrial => Icons.av_timer_sharp,
      TrainingType.free => Icons.timer_off,
    };

    final targetSummary = vm.formatObjectiveTarget(locale);
    final bool isSuccess = session.isSuccess;
    final Color statusColor = isSuccess ? AppTheme.successColor : AppTheme.errorColor;
    final String statusText = isSuccess
        ? (vm.trainingType == TrainingType.free
            ? locale.completed.toUpperCase()
            : locale.failed.toUpperCase())
        : locale.failed.toUpperCase();
    final IconData statusIcon = isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        behavior: HitTestBehavior.deferToChild,
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
                locale.results.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oswald',
                  fontSize: 16,
                  letterSpacing: 1.0,
                  decoration: TextDecoration.none,
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
                                  color: AppTheme.primaryColor.withAlpha(100),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: ShapeDecoration(
                                    color: isSuccess
                                        ? AppTheme.successColor.withAlpha(20)
                                        : (vm.trainingType == TrainingType.free
                                            ? AppTheme.primaryColor.withAlpha(20)
                                            : AppTheme.errorColor.withAlpha(20)),
                                    shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSuccess
                                            ? AppTheme.successColor.withAlpha(120)
                                            : (vm.trainingType == TrainingType.free
                                                ? AppTheme.primaryColor.withAlpha(120)
                                                : AppTheme.errorColor.withAlpha(120)),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              trainingIcon,
                                              color: AppTheme.primaryColor,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "${locale.setObjective.toUpperCase()}: ${vm.trainingType.getLocale(locale).toUpperCase()}",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppTheme.primaryColor,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Oswald',
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                  if (targetSummary.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      targetSummary,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: 'Oswald',
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: ShapeDecoration(
                                          color: statusColor.withAlpha(40),
                                          shape: BeveledRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                            side: BorderSide(color: statusColor, width: 1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              statusIcon,
                                              color: statusColor,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                letterSpacing: 0.8,
                                                fontFamily: 'Oswald',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                      child: SummaryStat(
                                        label: locale.distance.toUpperCase(),
                                        value: vm.formattedValidDistance,
                                        unit: locale.km.toUpperCase(),
                                      ),
                                    ),
                                    Expanded(
                                      child: SummaryStat(
                                        label: locale.time.toUpperCase(),
                                        value: vm.formattedValidTime,
                                        unit: "",
                                      ),
                                    ),
                                    Expanded(
                                      child: SummaryStat(
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
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      if (hasWalk)
                                        Expanded(
                                          child: SummaryStat(
                                            label: locale.walk.toUpperCase(),
                                            value: vm.formattedWalkDistance,
                                            unit: "${locale.km.toUpperCase()} (${vm.formattedWalkTime})",
                                            color: AppTheme.walkColor,
                                          ),
                                        ),
                                      if (hasRun)
                                        Expanded(
                                          child: SummaryStat(
                                            label: locale.run.toUpperCase(),
                                            value: vm.formattedRunDistance,
                                            unit: "${locale.km.toUpperCase()} (${vm.formattedRunTime})",
                                            color: AppTheme.runColor,
                                          ),
                                        ),
                                      if (hasBike)
                                        Expanded(
                                          child: SummaryStat(
                                            label: locale.bike.toUpperCase(),
                                            value: vm.formattedBikeDistance,
                                            unit: "${locale.km.toUpperCase()} (${vm.formattedBikeTime})",
                                            color: AppTheme.bikeColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(color: Colors.white12, height: 1),
                                ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                      child: SummaryStat(
                                        label: locale.impacted.toUpperCase(),
                                        value: vm.session.territories.length.toString(),
                                        unit: locale.territories.toUpperCase(),
                                        color: AppTheme.secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),

                                if (vm.activityResult != null) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Expanded(
                                        child: SummaryStat(
                                          label: locale.captured.toUpperCase(),
                                          value: vm.capturedCount.toString(),
                                          unit: "",
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      Expanded(
                                        child: SummaryStat(
                                          label: locale.attacked.toUpperCase(),
                                          value: vm.attackedCount.toString(),
                                          unit: "",
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      Expanded(
                                        child: SummaryStat(
                                          label: locale.defended.toUpperCase(),
                                          value: vm.defendedCount.toString(),
                                          unit: "",
                                          color: AppTheme.tertiaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ActivityResultStatusSection(
                                    activityResult: vm.activityResult!,
                                  ),
                                ],
                              ],
                            ),
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
  }
}

class SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;

  const SummaryStat({
    super.key,
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
                  fontSize: 20,
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

class ActivityResultStatusSection extends StatefulWidget {
  final ActivityResult activityResult;

  const ActivityResultStatusSection({
    super.key,
    required this.activityResult,
  });

  @override
  State<ActivityResultStatusSection> createState() => _ActivityResultStatusSectionState();
}

class _ActivityResultStatusSectionState extends State<ActivityResultStatusSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeInOutCubic)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final achievements = widget.activityResult.achievements;
    final challenges = widget.activityResult.challenges;

    if (achievements.isEmpty && challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white12, height: 1),
            ),
            if (achievements.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    locale.achievements.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Oswald',
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...achievements.map((achievement) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: ShapeDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: AppTheme.primaryColor.withAlpha(140),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: ShapeDecoration(
                          color: AppTheme.primaryColor.withAlpha(30),
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Icon(
                          Icons.military_tech_sharp,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.getTitle(locale).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Oswald',
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              achievement.getDescription(locale),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: ShapeDecoration(
                          color: AppTheme.successColor.withAlpha(30),
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: AppTheme.successColor, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, color: AppTheme.successColor, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              locale.completed.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                fontFamily: 'Oswald',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            if (challenges.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    locale.challengesProgress.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Oswald',
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: challenges.map((started) {
                      final challenge = started.activeChallenge.challenge;
                      final isCompleted = started.isComplete;
                      final progress = started.progress;
                      final num targetVal = (challenge.objectiveValue as num?) ?? 1;
                      final double targetRatio = targetVal > 0
                          ? (progress / targetVal).clamp(0.0, 1.0)
                          : (isCompleted ? 1.0 : 0.0);
                      final double currentAnimatedRatio = (targetRatio * _progressAnimation.value).clamp(0.0, 1.0);

                      final descriptionParts = challenge.getDescriptionParts(locale);
                      final progressText = _formatChallengeProgressText(
                        challenge: challenge,
                        currentProgress: progress,
                        isCompleted: isCompleted,
                        locale: locale,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: ShapeDecoration(
                          color: isCompleted
                              ? AppTheme.successColor.withAlpha(20)
                              : Colors.white.withAlpha(10),
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isCompleted
                                  ? AppTheme.successColor
                                  : AppTheme.primaryColor.withAlpha(100),
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
                                  challenge.objectiveIcon,
                                  color: AppTheme.secondaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: RichText(
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(text: "${descriptionParts['action']} "),
                                        TextSpan(
                                          text: "${descriptionParts['value']} ",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.secondaryColor,
                                          ),
                                        ),
                                        TextSpan(text: descriptionParts['unit']),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildChallengeProgressBar(
                              progressRatio: currentAnimatedRatio,
                              progressText: progressText,
                              isCompleted: isCompleted,
                              locale: locale,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeProgressBar({
    required double progressRatio,
    required String progressText,
    required bool isCompleted,
    required AppLocalizations locale,
    int segments = 12,
  }) {
    final color = isCompleted ? AppTheme.successColor : AppTheme.secondaryColor;
    final clampedProgress = progressRatio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progressText,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oswald',
                decoration: TextDecoration.none,
              ),
            ),
            if (isCompleted)
              Text(
                locale.completed.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.successColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  decoration: TextDecoration.none,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(segments, (index) {
            final double threshold = (index + 1) / segments;
            final bool isFilled = clampedProgress >= threshold;

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(
                  horizontal: index == 0 || index == segments - 1 ? 0 : 1.5,
                ),
                height: 6,
                decoration: ShapeDecoration(
                  color: isFilled ? color : Colors.white10,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _formatChallengeProgressText({
    required Challenge challenge,
    required int currentProgress,
    required bool isCompleted,
    required AppLocalizations locale,
  }) {
    if (isCompleted) {
      return locale.completed.toUpperCase();
    }

    final num targetNum = (challenge.objectiveValue as num?) ?? 1;

    switch (challenge.objective) {
      case ChallengeObjectiveType.total_time:
      case ChallengeObjectiveType.walk_time:
      case ChallengeObjectiveType.run_time:
      case ChallengeObjectiveType.bike_time:
        final currentHours = TimeConverter.secondsToHours(currentProgress);
        final targetHours = TimeConverter.secondsToHours(targetNum.toInt()).round();
        final currentFormatted = currentHours >= 10
            ? currentHours.round().toString()
            : currentHours.toStringAsFixed(1);
        final targetFormatted = targetHours > 0 ? targetHours.toString() : "1";
        return "$currentFormatted / ${targetFormatted}h";

      case ChallengeObjectiveType.total_distance:
      case ChallengeObjectiveType.walk_distance:
      case ChallengeObjectiveType.run_distance:
      case ChallengeObjectiveType.bike_distance:
        final currentKm = TimeConverter.metersToKilometers(currentProgress);
        final targetKm = TimeConverter.metersToKilometers(targetNum.toInt()).round();
        final currentFormatted = currentKm >= 10
            ? currentKm.round().toString()
            : currentKm.toStringAsFixed(1);
        final targetFormatted = targetKm > 0 ? targetKm.toString() : "1";
        return "$currentFormatted / ${targetFormatted}km";

      case ChallengeObjectiveType.captured_territories:
        return "$currentProgress / ${targetNum.toInt()}";

      case ChallengeObjectiveType.route:
        return isCompleted ? "1 / 1" : "0 / 1";
    }
  }
}
