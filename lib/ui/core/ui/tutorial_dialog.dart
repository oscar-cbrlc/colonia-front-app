import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

Future<T?> showTutorialDialog<T>(BuildContext context) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withAlpha(200),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const TutorialDialog();
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

class TutorialDialog extends StatefulWidget {
  const TutorialDialog({super.key});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(false);
    }
  }

  void _goToPage(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.82;

    final sectionNames = [
      locale.tutorialSectionInfo,
      locale.tutorialSectionTeam,
      locale.tutorialSectionActivity,
      locale.tutorialSectionProfile,
      locale.tutorialSectionChallengesAndEvents,
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight: maxHeight,
        ),
        padding: const EdgeInsets.all(20),
        decoration: ShapeDecoration(
          color: AppTheme.darkBackground.withAlpha(245),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: AppTheme.primaryColor,
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
                  Icons.map,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locale.coloniaTitle.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.0,
                      fontFamily: 'Oswald',
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: ShapeDecoration(
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    color: AppTheme.primaryColor.withAlpha(40),
                  ),
                  child: Text(
                    "${_currentPage + 1} / $_totalPages",
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Oswald',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 22),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(false);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_totalPages, (index) {
                  final isSelected = _currentPage == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => _goToPage(index),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: ShapeDecoration(
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryColor : Colors.white24,
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          color: isSelected
                              ? AppTheme.primaryColor.withAlpha(40)
                              : Colors.white.withAlpha(10),
                        ),
                        child: Text(
                          sectionNames[index].toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : Colors.white60,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 10,
                            fontFamily: 'Oswald',
                            letterSpacing: 0.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _InfoSection(locale: locale),
                  _TeamSection(locale: locale),
                  _ActivitySection(locale: locale),
                  _ProfileSection(locale: locale),
                  _ChallengesAndEventsSection(locale: locale),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.white38, width: 1),
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    onPressed: _previousPage,
                    child: Text(
                      _currentPage == 0
                          ? locale.tutorialSkip.toUpperCase()
                          : locale.tutorialPrevious.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_totalPages, (index) {
                    final isCurrent = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isCurrent ? 16 : 6,
                      height: 6,
                      decoration: ShapeDecoration(
                        color: isCurrent ? AppTheme.primaryColor : Colors.white24,
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.darkBackground,
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _totalPages - 1
                          ? locale.tutorialFinish.toUpperCase()
                          : locale.tutorialNext.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.darkBackground,
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final AppLocalizations locale;
  const _InfoSection({required this.locale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            locale.tutorialTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: ShapeDecoration(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.secondaryColor.withAlpha(120), width: 1.5),
                ),
                color: AppTheme.secondaryColor.withAlpha(10),
              ),
              child: Text(
                locale.tutorialInfo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(240),
                  fontSize: 13.5,
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),


          const SizedBox(height: 24),


        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  final AppLocalizations locale;
  const _TeamSection({required this.locale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.tutorialTeamSubtitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          _TutorialFeatureTile(
            icon: Icons.group_add_sharp,
            iconColor: AppTheme.secondaryColor,
            title: locale.joinATeam.toUpperCase(),
            description: locale.tutorialTeamInfo1,
          ),
          const SizedBox(height: 10),
          _TutorialFeatureTile(
            icon: Icons.flag_sharp,
            iconColor: AppTheme.primaryColor,
            title: locale.createTeam.toUpperCase(),
            description: locale.tutorialTeamInfo2,
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  final AppLocalizations locale;
  const _ActivitySection({required this.locale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.tutorialActivitySubtitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),


          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppTheme.tertiaryColor.withAlpha(140), width: 1),
              ),
              color: AppTheme.tertiaryColor.withAlpha(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hexagon_outlined, color: AppTheme.tertiaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locale.tutorialTerritoriesTitle.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Oswald',
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  locale.tutorialTerritoriesInfo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.35,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),



          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          Text(
            locale.tutorialActivityInfo1.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
              fontFamily: 'Oswald',
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            locale.tutorialOnFoot,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'Oswald',
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _TutorialActivityCard(
                  label: locale.walk.toUpperCase(),
                  icon: Icons.directions_walk,
                  color: AppTheme.walkColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TutorialActivityCard(
                  label: locale.run.toUpperCase(),
                  icon: Icons.directions_run,
                  color: AppTheme.runColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            locale.tutorialOnBike,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'Oswald',
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _TutorialActivityCard(
                  label: locale.bike.toUpperCase(),
                  icon: Icons.directions_bike,
                  color: AppTheme.bikeColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                locale.tutorialActivityInfo2.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  fontFamily: 'Oswald',
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ObjectiveWrapCard(name: locale.free.toUpperCase(), icon: Icons.explore, color: Colors.white70, width: itemWidth),
                  _ObjectiveWrapCard(name: locale.distance.toUpperCase(), icon: Icons.straighten, color: AppTheme.walkColor, width: itemWidth),
                  _ObjectiveWrapCard(name: locale.time.toUpperCase(), icon: Icons.timer, color: AppTheme.bikeColor, width: itemWidth),
                  _ObjectiveWrapCard(name: locale.pace.toUpperCase(), icon: Icons.speed, color: AppTheme.runColor, width: itemWidth),
                  _ObjectiveWrapCard(name: locale.timeTrial.toUpperCase(), icon: Icons.bolt, color: AppTheme.primaryColor, width: itemWidth),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TutorialActivityCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TutorialActivityCard({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withAlpha(120), width: 1),
        ),
        color: color.withAlpha(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                    decoration: TextDecoration.none,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveWrapCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final double width;

  const _ObjectiveWrapCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: ShapeDecoration(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withAlpha(120), width: 1),
          ),
          color: color.withAlpha(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oswald',
                  decoration: TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final AppLocalizations locale;
  const _ProfileSection({required this.locale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.tutorialProfileSubtitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          _TutorialFeatureTile(
            icon: Icons.edit_sharp,
            iconColor: AppTheme.primaryColor,
            title: locale.profile.toUpperCase(),
            description: locale.tutorialProfileInfo1,
          ),
          const SizedBox(height: 10),
          _TutorialFeatureTile(
            icon: Icons.dry_cleaning_sharp,
            iconColor: AppTheme.secondaryColor,
            title: locale.avatar.toUpperCase(),
            description: locale.tutorialProfileInfo2,
          ),
          const SizedBox(height: 10),
          _TutorialFeatureTile(
            icon: Icons.military_tech_sharp,
            iconColor: AppTheme.tertiaryColor,
            title: locale.achievements.toUpperCase(),
            description: locale.tutorialProfileInfo3,
          ),
        ],
      ),
    );
  }
}

class _ChallengesAndEventsSection extends StatelessWidget {
  final AppLocalizations locale;
  const _ChallengesAndEventsSection({required this.locale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.tutorialChallengesAndEventsSubtitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          _TutorialFeatureTile(
            icon: Icons.fact_check_outlined,
            iconColor: AppTheme.secondaryColor,
            title: locale.weekChallenges.toUpperCase(),
            description: locale.tutorialChallengesAndEventsInfo1,
          ),
          const SizedBox(height: 10),
          _TutorialFeatureTile(
            icon: Icons.today_sharp,
            iconColor: AppTheme.tertiaryColor,
            title: locale.events.toUpperCase(),
            description: locale.tutorialChallengesAndEventsInfo2,
          ),
        ],
      ),
    );
  }
}

class _TutorialFeatureTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _TutorialFeatureTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white12, width: 0.8),
        ),
        color: Colors.white.withAlpha(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.3,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


