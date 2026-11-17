import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/data/repositories/training_repository.dart';
import 'package:colonia_front_app/domain/models/user_training.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/loading_widget.dart';

void showUserTrainingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const UserTrainingsSheet(),
  );
}

class UserTrainingsSheet extends StatefulWidget {
  const UserTrainingsSheet({super.key});

  @override
  State<UserTrainingsSheet> createState() => _UserTrainingsSheetState();
}

class _UserTrainingsSheetState extends State<UserTrainingsSheet> {
  final Set<String> _expandedTrainingUuids = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TrainingRepository>().fetchMyTrainings();
      }
    });
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$secs';
    }
    return '$minutes:$secs';
  }

  String _formatDistance(num meters) {
    final double m = meters.toDouble();
    if (m >= 1000) {
      return '${(m / 1000.0).toStringAsFixed(2)} km';
    }
    return '${m.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final repository = context.watch<TrainingRepository>();

    final trainings = repository.userTrainings;
    final isLoading = repository.isUserTrainingsLoading;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(24),
      decoration: const ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        color: AppTheme.darkBackground,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fitness_center_sharp,
                        color: AppTheme.secondaryColor,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          locale.myTrainings.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Oswald',
                            fontSize: 21,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              locale.myTrainingsSubtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: isLoading && trainings.isEmpty
                  ? const LoadingWidget()
                  : trainings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                locale.noTrainingsYet,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Oswald',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                locale.noTrainingsYetDescription,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(140),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await context.read<TrainingRepository>().fetchMyTrainings();
                          },
                          color: AppTheme.secondaryColor,
                          child: ListView.builder(
                            itemCount: trainings.length,
                            itemBuilder: (context, index) {
                              final training = trainings[index];
                              final isExpanded = _expandedTrainingUuids.contains(training.uuid);

                              return _buildTrainingCard(
                                context,
                                locale,
                                training,
                                isExpanded,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingCard(
    BuildContext context,
    AppLocalizations locale,
    UserTraining training,
    bool isExpanded,
  ) {
    final hasWalk = training.secondsWalk > 0 || training.metersWalk > 0;
    final hasRun = training.secondsRun > 0 || training.metersRun > 0;
    final hasBike = training.secondsBike > 0 || training.metersBike > 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isExpanded) {
            _expandedTrainingUuids.remove(training.uuid);
          } else {
            _expandedTrainingUuids.add(training.uuid);
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: AppTheme.primaryColor.withAlpha(12),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isExpanded
                  ? AppTheme.secondaryColor
                  : AppTheme.primaryColor.withAlpha(125),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppTheme.primaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(training.startedAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Oswald',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white54,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(training.time),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.straighten_outlined,
                                color: Colors.white54,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDistance(training.distance),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ],
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubicEmphasized,
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white12, height: 1),
                          ),
                          // Stats row (Captured Territories, Attack, Defense)
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.shield_sharp,
                                  iconColor: AppTheme.primaryColor,
                                  value: (training.capturedTerritories ?? 0).toString(),
                                  label: locale.territories.toUpperCase(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.flash_on_sharp,
                                  iconColor: AppTheme.secondaryColor,
                                  value: (training.trainingAttack ?? 0).toString(),
                                  label: locale.attack.toUpperCase(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.security_sharp,
                                  iconColor: AppTheme.tertiaryColor,
                                  value: (training.trainingDefence ?? 0).toString(),
                                  label: locale.defense.toUpperCase(),
                                ),
                              ),
                            ],
                          ),
                          // Activities breakdown
                          if (hasWalk || hasRun || hasBike) ...[
                            const SizedBox(height: 14),
                            Text(
                              locale.activities.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Oswald',
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (hasWalk)
                              _buildActivityRow(
                                icon: Icons.directions_walk,
                                color: AppTheme.walkColor,
                                label: locale.walk,
                                distance: _formatDistance(training.metersWalk),
                                duration: _formatDuration(training.secondsWalk),
                              ),
                            if (hasRun)
                              _buildActivityRow(
                                icon: Icons.directions_run,
                                color: AppTheme.runColor,
                                label: locale.run,
                                distance: _formatDistance(training.metersRun),
                                duration: _formatDuration(training.secondsRun),
                              ),
                            if (hasBike)
                              _buildActivityRow(
                                icon: Icons.directions_bike,
                                color: AppTheme.bikeColor,
                                label: locale.bike,
                                distance: _formatDistance(training.metersBike),
                                duration: _formatDuration(training.secondsBike),
                              ),
                          ],
                          // Boosts used
                          if (training.boost != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              locale.boostUsed.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Oswald',
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: ShapeDecoration(
                                color: AppTheme.secondaryColor.withAlpha(20),
                                shape: BeveledRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: AppTheme.secondaryColor.withAlpha(120),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    training.boost!.icon,
                                    color: AppTheme.secondaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    training.boost!.getCompleteName(locale),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: ShapeDecoration(
        color: Colors.white.withAlpha(10),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: iconColor.withAlpha(80), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(140),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required Color color,
    required String label,
    required String distance,
    required String duration,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ShapeDecoration(
        color: Colors.white.withAlpha(8),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                distance,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($duration)',
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
