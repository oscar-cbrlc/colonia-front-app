import 'dart:ui';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/navigation/navigation_callbacks.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
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

class _MapScreenState extends State<MapScreen> {


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


  @override
  void initState() {
    super.initState();
    mapbox.MapboxOptions.setAccessToken(Env.mapboxAccessToken);
    widget.viewModel.requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
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
          alignment: Alignment.topRight,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 124, right: 16),
              child: IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.viewModel.centerOnUser();
                },
                icon: const Icon(Icons.location_searching),
                color: Colors.redAccent,
                iconSize: 32,
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
