import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/challenge_repository.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/events/widgets/challenges_sheet.dart';

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

                              final started = myStartedEvents
                                  .where((s) => s.activeChallenge.id == event.id)
                                  .firstOrNull;
                              final isCompleted = started?.isComplete ?? false;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.eventDetails,
                                    arguments: event,
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: ShapeDecoration(
                                    color: isCompleted
                                        ? AppTheme.tertiaryColor.withAlpha(20)
                                        : Colors.white.withAlpha(10),
                                    shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isCompleted
                                            ? AppTheme.primaryColor
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
                                                Text(
                                                  challenge.name ?? locale.events,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Oswald',
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${_formatDate(event.startDate)} - ${_formatDate(event.endDate)}',
                                                  style: TextStyle(
                                                    color: Colors.white.withAlpha(150),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isCompleted)
                                            Text(
                                              locale.completed.toUpperCase(),
                                              style: const TextStyle(
                                                color: AppTheme.secondaryColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
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
                                                )
                                              ).toList(),
                                            ),
                                          ],
                                        ),
                                      ],
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
