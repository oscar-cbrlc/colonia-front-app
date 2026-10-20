import 'dart:ui';
import 'package:colonia_front_app/domain/models/active_challenge.dart';
import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/started_challenge.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/utils/time_converter.dart';
import 'package:colonia_front_app/ui/core/navigation/navigation_callbacks.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/map_control_group.dart';
import 'package:colonia_front_app/ui/core/ui/territory_summary_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:colonia_front_app/env/env.dart';
import 'package:colonia_front_app/ui/map/view_models/map_viewmodel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.viewModel});
  final MapViewModel viewModel;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with RouteAware {
  @override
  void didPopNext() {
    widget.viewModel.checkPendingActivities();
  }

  Widget get _profileGroup => Visibility(
      visible: true,
      child: Align(
        alignment: Alignment.topLeft,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 32.0, left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapActionButton(
                      icon: Icons.notifications,
                      color: AppTheme.primaryColor.withAlpha(100),
                      iconColor: AppTheme.tertiaryColor,
                      borderColor: AppTheme.primaryColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      shape: const StarBorder(
                        side: BorderSide(color: AppTheme.primaryColor, width: 2),
                        points: 6,
                        innerRadiusRatio: 0.86,
                        rotation: 30,
                        pointRounding: 0.15,
                      )
                  ),
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: _MapActionButton(
                      icon: Icons.group,
                      color: AppTheme.primaryColor.withAlpha(100),
                      iconColor: AppTheme.tertiaryColor,
                      borderColor: AppTheme.primaryColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                        shape: const StarBorder(
                          side: BorderSide(color: AppTheme.primaryColor, width: 2),
                          points: 6,
                          innerRadiusRatio: 0.86,
                          rotation: 30,
                          pointRounding: 0.15,
                        )
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(-18, -40),
                  child: _MapActionButton(
                    icon: Icons.person,
                    color: AppTheme.primaryColor.withAlpha(100),
                    iconColor: AppTheme.tertiaryColor,
                    borderColor: AppTheme.primaryColor,
                    onTap: () {
                      HapticFeedback.lightImpact();
                    },
                    shape: const StarBorder(
                      side: BorderSide(color: AppTheme.primaryColor, width: 2),
                      points: 6,
                      innerRadiusRatio: 0.86,
                      rotation: 30,
                      pointRounding: 0.15,
                    )
                  )
              ),
            ],
          ),
        ),
      ),
    )
  );

  Widget get _activityGroup => Visibility(
      visible: true,
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


  void _showSyncNotification(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.viewModel.clearSyncMessage();
    });
  }

  @override
  void initState() {
    super.initState();
    mapbox.MapboxOptions.setAccessToken(Env.mapboxAccessToken);
    widget.viewModel.requestLocationPermission();
    widget.viewModel.checkPendingActivities();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.didSync) {
          _showSyncNotification(locale.pendingActivitiesSynced);
        }
        
        return Stack(
          children: [
            mapbox.MapWidget(
              key: const ValueKey("map_screen_mapbox"),
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
          viewport: widget.viewModel.viewport ?? (widget.viewModel.userPosition != null ? mapbox.CameraViewportState(
            center: widget.viewModel.userPosition!,
            zoom: 15.0,
          ) : null),
        ),

        Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IndividualMapButton(
                    icon: Icons.fact_check_outlined,
                    iconColor: Colors.white,
                    borderColor: AppTheme.primaryColor,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showActiveChallengesSheet(context);
                    },
                    width: 54,
                    height: 54,
                  ),
                  Container(
                    width: 32,
                    height: 21,
                    decoration: ShapeDecoration(
                      color: AppTheme.primaryColor.withAlpha(200),
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        side: BorderSide(
                          color: Colors.white60,
                          width: 1,
                        )
                      ),
                    ),
                    child: Text(
                      '${widget.viewModel.completedChallengesCount}/${widget.viewModel.activeChallenges.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                ]
              )
            ),
          ),
        ),

        Align(
          alignment: Alignment.centerRight,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120, right: 16),
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

        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child:ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  navigateToActivityScreen(context);
                },
                child: Text(locale.startActivity)
              )
            ),
          ),
        ),

        //_profileGroup,
        //_activityGroup,
      ],
    );
      },
    );
  }

  void _showActiveChallengesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActiveChallengesSheet(viewModel: widget.viewModel),
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

class _ActiveChallengesSheet extends StatefulWidget {
  final MapViewModel viewModel;
  const _ActiveChallengesSheet({required this.viewModel});

  @override
  State<_ActiveChallengesSheet> createState() => _ActiveChallengesSheetState();
}

class _ActiveChallengesSheetState extends State<_ActiveChallengesSheet> {
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
                          fontSize: 20,
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

                              return _ChallengeListItem(
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

class _ChallengeListItem extends StatelessWidget {
  final ActiveChallenge activeChallenge;
  final StartedChallenge? startedChallenge;

  const _ChallengeListItem({
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
    final reward = challenge.reward;
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

    final boostReward = reward.boost;

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
          const SizedBox(height: 12),
          _ChallengeProgressBar(
            progress: isCompleted ? 1.0 : progressRatio,
            progressText: progressText,
            isCompleted: isCompleted,
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 0.2),

          const SizedBox(height: 12),

          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (reward.amount > 0) ...[
                      const SizedBox(width: 8),
                      _ExpandableRewardCard(
                        boostReward: boostReward,
                        avatarItemReward: reward.avatarItem,
                        amount: reward.amount,
                        locale: locale,
                      ),
                    ],
                    const SizedBox(width: 8),
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
                          //Icon(Icons.star, color: difficultyColor, size: 14),
                          Text(
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

class _ExpandableRewardCard extends StatefulWidget {
  final Boost? boostReward;
  final AvatarItem? avatarItemReward;
  final int amount;
  final AppLocalizations locale;

  const _ExpandableRewardCard({
    required this.boostReward,
    required this.avatarItemReward,
    required this.amount,
    required this.locale,
  });

  @override
  State<_ExpandableRewardCard> createState() => _ExpandableRewardCardState();
}

class _ExpandableRewardCardState extends State<_ExpandableRewardCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final boost = widget.boostReward;
    final avatarItem = widget.avatarItemReward;

    IconData icon = Icons.attach_money;
    String nameType = '';

    if (boost != null) {
      icon = BoostInventory.getBoostIcon(boost.type);
      nameType = BoostInventory.getNameType(widget.locale, boost.type).toUpperCase();
    } else if (avatarItem != null) {
      icon = Icons.checkroom;
      nameType = avatarItem.name.toUpperCase();
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
                  ? Colors.white
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
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubicEmphasized,
              child: _isExpanded && nameType.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Text(
                        nameType,
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
