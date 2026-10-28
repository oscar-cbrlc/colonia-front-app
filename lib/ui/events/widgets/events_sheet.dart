import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/challenge_repository.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/events/widgets/challenges_sheet.dart';

enum EventState {
  notStarted,
  inCourse,
  expired;

  String getLocale(AppLocalizations locale) {
    switch (this) {
      case EventState.notStarted:
        return locale.comingSoonLabel;
      case EventState.inCourse:
        return locale.inProgressLabel;
      case EventState.expired:
        return locale.endedLabel;
    }
  }
}

enum EventCompletionState {
  notCompleted,
  completed,
}

void showEventsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const EventsSheet(),
  );
}

class EventsSheet extends StatefulWidget {
  const EventsSheet({super.key});

  @override
  State<EventsSheet> createState() => _EventsSheetState();
}

class _EventsSheetState extends State<EventsSheet> {
  int? _expandedEventId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final repo = context.read<ChallengeRepository>();
        repo.fetchEvents();
        repo.fetchMyEventProgress();
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

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final challengeRepository = context.watch<ChallengeRepository>();
    final authRepository = context.watch<AuthRepository>();

    final events = challengeRepository.events;
    events.sort(
      (a, b) => b.startDate.compareTo(a.startDate),
    );
    final myStartedEvents = challengeRepository.myStartedEvents;
    final isLoading = challengeRepository.isLoading;
    final isAdmin = authRepository.currentUser?.isAdmin ?? false;

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
                Row(
                  children: [
                    const Icon(
                      Icons.event_sharp,
                      color: AppTheme.tertiaryColor,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      locale.events.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                        fontSize: 21,
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
            const SizedBox(height: 8),
            Text(
              locale.eventsSubtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: isLoading && events.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.tertiaryColor,
                      ),
                    )
                  : events.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                locale.noActiveEvents,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Oswald',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                locale.noActiveEventsDescription,
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
                            final repo = context.read<ChallengeRepository>();
                            await repo.fetchEvents();
                            await repo.fetchMyEventProgress();
                          },
                          color: AppTheme.tertiaryColor,
                          child: ListView.builder(
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              final challenge = event.challenge;
                              final boostRewards = challenge.boostRewards;

                              final now = DateTime.now();

                              final eventState =
                                event.startDate.isAfter(now) ? EventState.notStarted :
                                event.startDate.isBefore(now) && event.endDate.isAfter(now) ? EventState.inCourse :
                                EventState.expired;
                              final isNotYet = eventState == EventState.notStarted;
                              final isInCourse = eventState == EventState.inCourse;
                              final isExpired = eventState == EventState.expired;

                              final started = myStartedEvents
                                  .where((s) => s.activeChallenge.id == event.id)
                                  .firstOrNull;
                              final isCompleted = started?.isComplete ?? false;
                              final isExpanded = _expandedEventId == event.id;

                              if (!isAdmin && isExpired) return const SizedBox.shrink();

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _expandedEventId = isExpanded ? null : event.id;
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: ShapeDecoration(
                                    color:
                                        isNotYet? AppTheme.tertiaryColor.withAlpha(5) :
                                        isInCourse? AppTheme.tertiaryColor.withAlpha(5) :
                                        isExpired? AppTheme.tertiaryColor.withAlpha(10) :
                                        AppTheme.primaryColor.withAlpha(125),

                                    shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isCompleted
                                            ? AppTheme.successColor
                                            : isNotYet? AppTheme.tertiaryColor
                                            : isInCourse? AppTheme.secondaryColor
                                            : isExpired? AppTheme.secondaryColor.withAlpha(75)
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
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        challenge.name ?? locale.events,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'Oswald',
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (isCompleted) ...[
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: ShapeDecoration(
                                                              color: AppTheme.successColor.withAlpha(25),
                                                              shape: BeveledRectangleBorder(
                                                                borderRadius: BorderRadius.circular(4),
                                                                side: const BorderSide(color: AppTheme.successColor, width: 1),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              locale.completed.toUpperCase(),
                                                              style: const TextStyle(
                                                                color: AppTheme.successColor,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 9,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                        ],
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: ShapeDecoration(
                                                            color: isNotYet? AppTheme.secondaryColor.withAlpha(2) : isInCourse? AppTheme.tertiaryColor.withAlpha(120) : Colors.transparent,
                                                            shape: BeveledRectangleBorder(
                                                              borderRadius: BorderRadius.circular(6),
                                                              side: BorderSide(color: isNotYet? AppTheme.secondaryColor.withAlpha(120) : isInCourse? AppTheme.tertiaryColor : AppTheme.primaryColor.withAlpha(90), width: 1),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            eventState.getLocale(locale).toUpperCase(),
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${_formatDate(event.startDate)} - ${_formatDate(event.endDate)}',
                                                  style: TextStyle(
                                                    color: AppTheme.primaryColor.withAlpha(150),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (boostRewards.isNotEmpty) ...[
                                        const SizedBox(height: 16),
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
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: boostRewards.map((boostReward) =>
                                                ExpandableRewardCard(
                                                  boostReward: boostReward.boost,
                                                  avatarItemReward: null,
                                                  amount: boostReward.amount,
                                                  locale: locale,
                                                  mainColor:
                                                    (isInCourse || isExpired) ? AppTheme.secondaryColor :
                                                    AppTheme.tertiaryColor,
                                                  mainTextColor: Colors.white,
                                                  secondaryColor: (isInCourse || isExpired)? AppTheme.tertiaryColor : AppTheme.secondaryColor,
                                                  secondaryTextColor: (isInCourse || isExpired) ? Colors.white : AppTheme.darkBackground,
                                                )
                                              ).toList(),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      if (isCompleted) ...[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: ShapeDecoration(
                                                color: AppTheme.secondaryColor.withAlpha(15),
                                                shape: BeveledRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  side: const BorderSide(color: AppTheme.secondaryColor, width: 1),
                                                ),
                                              ),
                                              child: Text(
                                                locale.completed.toUpperCase(),
                                                style: const TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  fontFamily: 'Oswald',
                                                  letterSpacing: 1.6,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ]
                                        )
                                      ],
                                      AnimatedSize(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOutCubicEmphasized,
                                        alignment: Alignment.topCenter,
                                        child: isExpanded
                                            ? SizedBox(
                                                width: double.infinity,
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(height: 16),
                                                    const Divider(color: Colors.white12, height: 1),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        if (isAdmin) ...[
                                                          Expanded(
                                                            child: OutlinedButton.icon(
                                                              style: OutlinedButton.styleFrom(
                                                                side: BorderSide(
                                                                  color: AppTheme.tertiaryColor.withAlpha(180),
                                                                ),
                                                                foregroundColor: AppTheme.tertiaryColor,
                                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                                shape: BeveledRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                              ),
                                                              onPressed: () {
                                                                Navigator.pop(context);
                                                                Navigator.pushNamed(
                                                                  context,
                                                                  AppRouter.createEvent,
                                                                  arguments: event,
                                                                );
                                                              },
                                                              icon: const Icon(Icons.edit_note, size: 18),
                                                              label: Text(
                                                                locale.editForNewEvent.toUpperCase(),
                                                                textAlign: TextAlign.center,
                                                                style: const TextStyle(
                                                                  fontFamily: 'Oswald',
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                        ],
                                                        Expanded(
                                                          child: ElevatedButton.icon(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: AppTheme.primaryColor,
                                                              foregroundColor: AppTheme.darkBackground,
                                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                                              shape: BeveledRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                              Navigator.pushNamed(
                                                                context,
                                                                AppRouter.eventDetails,
                                                                arguments: event,
                                                              );
                                                            },
                                                            icon: const Icon(Icons.map_outlined, size: 18),
                                                            label: Text(
                                                              locale.showRoute.toUpperCase(),
                                                              textAlign: TextAlign.center,
                                                              style: const TextStyle(
                                                                fontFamily: 'Oswald',
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 11,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox(width: double.infinity, height: 0),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            if (isAdmin) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.createEvent);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.tertiaryColor,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        locale.createNewEvent.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.darkBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
