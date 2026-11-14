import 'dart:ui';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/navigation/navigation_callbacks.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/map_control_group.dart';
import 'package:colonia_front_app/ui/core/ui/loading_widget.dart';
import 'package:colonia_front_app/ui/core/ui/territory_summary_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:colonia_front_app/env/env.dart';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/ui/events/widgets/challenges_sheet.dart';
import 'package:colonia_front_app/ui/events/widgets/events_sheet.dart';
import 'package:colonia_front_app/ui/notifications/widgets/notifications_sheet.dart';
import 'package:colonia_front_app/ui/map/view_models/map_viewmodel.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.viewModel});
  final MapViewModel viewModel;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    widget.viewModel.reloadMapData();
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
                        showNotificationsSheet(context);
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
    super.build(context);
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

        if (!widget.viewModel.isMapReady)
          const Positioned.fill(
            child: LoadingWidget(),
          ),

        if (widget.viewModel.isOffline)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 82.0),
                child: _MapOfflineWidget(
                  isReconnecting: widget.viewModel.isReconnecting,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await widget.viewModel.checkConnectionAndReload();
                    if (!success && mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(locale.stillOffline),
                          backgroundColor: AppTheme.errorColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),

        Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 80, left: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IndividualMapButton(
                    icon: Icons.notifications_sharp,
                    iconColor: Colors.white,
                    borderColor: AppTheme.secondaryColor,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      showNotificationsSheet(context);
                    },
                    width: 54,
                    height: 54,
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: widget.viewModel.isOffline ? 0.4 : 1.0,
                    child: IndividualMapButton(
                      icon: Icons.event_sharp,
                      iconColor: widget.viewModel.isOffline ? Colors.white38 : Colors.white,
                      borderColor: widget.viewModel.isOffline ? Colors.grey : AppTheme.tertiaryColor,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (widget.viewModel.isOffline) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(locale.eventsUnavailableOffline),
                              backgroundColor: Colors.orangeAccent,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          widget.viewModel.checkConnectionAndReload();
                          return;
                        }
                        showEventsSheet(context);
                      },
                      width: 54,
                      height: 54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: widget.viewModel.isOffline ? 0.4 : 1.0,
                    child: IndividualMapButton(
                      icon: Icons.fact_check_outlined,
                      iconColor: widget.viewModel.isOffline ? Colors.white38 : Colors.white,
                      borderColor: widget.viewModel.isOffline ? Colors.grey : AppTheme.primaryColor,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (widget.viewModel.isOffline) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(locale.challengesUnavailableOffline),
                              backgroundColor: Colors.orangeAccent,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          widget.viewModel.checkConnectionAndReload();
                          return;
                        }
                        _showActiveChallengesSheet(context);
                      },
                      width: 54,
                      height: 54,
                    ),
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
                  ),
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
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final currentUser = AuthRepository.instance.currentUser;
                  final hasTeam = currentUser?.hasTeam ?? false;
                  if (!hasTeam) {
                    _showBlockedToExcursionDialog(context);
                    return;
                  }
                  await navigateToActivityScreen(context);
                  widget.viewModel.reloadMapData();
                },
                child: Text(
                    locale.startActivity.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.0,
                      color: AppTheme.darkBackground
                    ),
                )
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
    showChallengesSheet(context, widget.viewModel);
  }
}

class _MapOfflineWidget extends StatelessWidget {
  final VoidCallback onTap;
  final bool isReconnecting;

  const _MapOfflineWidget({
    required this.onTap,
    this.isReconnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = AppTheme.errorColor.withAlpha(200);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: AppTheme.darkBackground.withAlpha(215),
          shape: BeveledRectangleBorder(
            side: BorderSide(color: color, width: 1.2),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReconnecting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.errorColor,
                ),
              )
            else
              Icon(Icons.wifi_off_sharp, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locale.offline.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                    fontFamily: 'Oswald',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: ShapeDecoration(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                color: color,
              ),
              child: Text(
                locale.reconnect.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oswald',
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showBlockedToExcursionDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withAlpha(180),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _BlockedToExcursionDialog();
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

class _BlockedToExcursionDialog extends StatelessWidget {
  const _BlockedToExcursionDialog();

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
                  Icons.no_accounts_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locale.blockedToExcursionTitle.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.0,
                      fontFamily: 'Oswald',
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
            Text(
              locale.blockedToExcursionText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.darkBackground,
                  shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Text(
                  locale.ok.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
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
