import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/domain/models/active_challenge.dart';
import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/started_challenge.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/map/view_models/map_viewmodel.dart';
import 'package:colonia_front_app/utils/time_converter.dart';

void showChallengesSheet(BuildContext context, MapViewModel viewModel) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ActiveChallengesSheet(viewModel: viewModel),
  );
}

class ActiveChallengesSheet extends StatefulWidget {
  final MapViewModel viewModel;
  const ActiveChallengesSheet({super.key, required this.viewModel});

  @override
  State<ActiveChallengesSheet> createState() => _ActiveChallengesSheetState();
}

class _ActiveChallengesSheetState extends State<ActiveChallengesSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.fetchActiveChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final activeChallenges = widget.viewModel.activeChallenges;
        final myProgress = widget.viewModel.myStartedChallenges;
        final isLoading = widget.viewModel.isChallengesLoading;

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: const ShapeDecoration(
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            color: AppTheme.darkBackground,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.fact_check_outlined,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        locale.weekChallenges.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Oswald',
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.viewModel.completedChallengesCount}/${widget.viewModel.activeChallenges.length}',
                style: TextStyle(
                  color: AppTheme.primaryColor.withAlpha(150),
                  fontFamily: 'Oswald',
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading && activeChallenges.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : activeChallenges.isEmpty
                        ? const Center(
                            child: Text(
                              "No active challenges this week.",
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: activeChallenges.length,
                            itemBuilder: (context, index) {
                              final activeChallenge = activeChallenges[index];
                              final started = myProgress.where((s) => s.activeChallenge.id == activeChallenge.id).firstOrNull;

                              return ChallengeListItem(
                                activeChallenge: activeChallenge,
                                startedChallenge: started,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChallengeListItem extends StatelessWidget {
  final ActiveChallenge activeChallenge;
  final StartedChallenge? startedChallenge;

  const ChallengeListItem({
    super.key,
    required this.activeChallenge,
    this.startedChallenge,
  });

  String _formatChallengeProgressText({
    required Challenge challenge,
    required int currentProgress,
    required bool isCompleted,
  }) {
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
        return "$currentFormatted / ${targetHours}h";

      case ChallengeObjectiveType.total_distance:
      case ChallengeObjectiveType.walk_distance:
      case ChallengeObjectiveType.run_distance:
      case ChallengeObjectiveType.bike_distance:
        final currentKm = TimeConverter.metersToKilometers(currentProgress);
        final targetKm = TimeConverter.metersToKilometers(targetNum.toInt()).round();
        final currentFormatted = currentKm >= 10
            ? currentKm.round().toString()
            : currentKm.toStringAsFixed(1);
        return "$currentFormatted / ${targetKm}km";

      case ChallengeObjectiveType.captured_territories:
        return "$currentProgress / ${targetNum.toInt()}";

      case ChallengeObjectiveType.route:
        return isCompleted ? "1 / 1" : "0 / 1";
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final challenge = activeChallenge.challenge;
    final isCompleted = startedChallenge?.isComplete ?? false;
    final progress = startedChallenge?.progress ?? 0;
    final num targetVal = (challenge.objectiveValue as num?) ?? 1;
    final double progressRatio = targetVal > 0 
        ? (progress / targetVal).clamp(0.0, 1.0) 
        : (isCompleted ? 1.0 : 0.0);

    final progressText = _formatChallengeProgressText(
      challenge: challenge,
      currentProgress: progress,
      isCompleted: isCompleted,
    );

    final boostRewards = activeChallenge.challenge.boostRewards;
    final descriptionParts = challenge.getDescriptionParts(locale);

    final difficultyColor = switch (challenge.difficulty) {
      ChallengeDifficulty.easy => Colors.greenAccent,
      ChallengeDifficulty.normal => Colors.orangeAccent,
      ChallengeDifficulty.hard => Colors.redAccent,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: isCompleted
            ? AppTheme.successColor.withAlpha(20)
            : Colors.white.withAlpha(10),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: ShapeDecoration(
                      color: AppTheme.secondaryColor.withAlpha(25),
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: AppTheme.secondaryColor.withAlpha(120), width: 1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(challenge.objectiveIcon, color: Colors.white70, size: 18)
                      ]
                    )
                  ),
                  const SizedBox(width: 10),
                  RichText(
                      text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          children: <TextSpan> [
                            TextSpan(text: "${descriptionParts['action']} "),
                            TextSpan(text: "${descriptionParts['value']} ", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                            TextSpan(text: descriptionParts['unit']),
                          ]
                      )
                  ),
                ]
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: difficultyColor.withAlpha(25),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: difficultyColor.withAlpha(120), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "XP",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${challenge.xpReward}",
                      style: TextStyle(
                        color: difficultyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ),
          const SizedBox(height: 12),
          _ChallengeProgressBar(
            progress: isCompleted ? 1.0 : progressRatio,
            progressText: progressText,
            isCompleted: isCompleted,
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 0.2),
          const SizedBox(height: 12),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${locale.rewards.toUpperCase()}:',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (boostRewards.isNotEmpty) ...[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: boostRewards.map((boostReward) =>
                            ExpandableRewardCard(boostReward: boostReward.boost, avatarItemReward: null, amount: boostReward.amount, locale: locale)
                          ).toList()
                        )
                    ],

                  ],
                )
              ]
          ),
        ],
      ),
    );
  }
}

class _ChallengeProgressBar extends StatelessWidget {
  final double progress;
  final String progressText;
  final bool isCompleted;
  final int segments;

  const _ChallengeProgressBar({
    required this.progress,
    required this.progressText,
    required this.isCompleted,
    this.segments = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? AppTheme.successColor : AppTheme.secondaryColor;
    final clampedProgress = progress.clamp(0.0, 1.0);

    final locale = AppLocalizations.of(context)!;

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
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(horizontal: index == 0 || index == segments - 1 ? 0 : 1.5),
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
}

class ExpandableRewardCard extends StatefulWidget {
  final Boost? boostReward;
  final AvatarItem? avatarItemReward;
  final int amount;
  final AppLocalizations locale;

  const ExpandableRewardCard({
    super.key,
    required this.boostReward,
    required this.avatarItemReward,
    required this.amount,
    required this.locale,
  });

  @override
  State<ExpandableRewardCard> createState() => _ExpandableRewardCardState();
}

class _ExpandableRewardCardState extends State<ExpandableRewardCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final boost = widget.boostReward;
    final avatarItem = widget.avatarItemReward;

    IconData icon = Icons.attach_money;
    String desc = '';

    if (boost != null) {
      icon = BoostInventory.getBoostIcon(boost.type);
      desc = boost.getName(widget.locale).toUpperCase();
    } else if (avatarItem != null) {
      icon = Icons.checkroom;
      desc = avatarItem.name.toUpperCase();
    }

    return GestureDetector(
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: ShapeDecoration(
          color: _isExpanded
              ? AppTheme.tertiaryColor.withAlpha(50)
              : AppTheme.tertiaryColor.withAlpha(25),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _isExpanded
                  ? Colors.white70
                  : AppTheme.tertiaryColor.withAlpha(140),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            if (boost != null)
              Text(
                boost.getEffectFormatted().toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  decoration: TextDecoration.none,
                ),
              ),

            const SizedBox(width: 6),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubicEmphasized,
              child: _isExpanded && desc.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Text(
                        desc,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: ShapeDecoration(
                color: AppTheme.secondaryColor.withAlpha(180),
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                "x${widget.amount}",
                style: const TextStyle(
                  color: AppTheme.darkBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
