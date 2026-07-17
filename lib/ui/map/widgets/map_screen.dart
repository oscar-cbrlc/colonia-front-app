import 'dart:ui';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:colonia_front_app/env/env.dart';
import 'package:colonia_front_app/ui/map/view_models/map_viewmodel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.viewModel});
  final MapViewModel viewModel;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(Env.mapboxAccessToken);
    widget.viewModel.requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppTheme.primaryColor,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, child) {
          return Stack(
            children: [
              MapWidget(
                key: const ValueKey("mapWidget"),
                styleUri: MapboxStyles.STANDARD,
                onMapCreated: widget.viewModel.onMapCreated,
                onStyleLoadedListener: (data) => widget.viewModel.onStyleLoaded(),
                onCameraChangeListener: (data) => widget.viewModel.onCameraChanged(data),
                viewport: widget.viewModel.viewport ?? CameraViewportState(
                  center: Point(coordinates: Position(0, 0)),
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
                        padding: const EdgeInsetsGeometry.all(16),
                        child: _MapActionButton(
                            icon: Icons.play_arrow,
                            color: AppTheme.primaryColor.withAlpha(125),
                            iconColor: AppTheme.secondaryColor,
                            borderColor: AppTheme.secondaryColor,
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
                    )
                ),
              ),

              Align(
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
                                iconColor: AppTheme.primaryColor,
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
                                  iconColor: AppTheme.primaryColor,
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
                          offset: const Offset(-20, -40),
                          child: _MapActionButton(
                              icon: Icons.person,
                              color: AppTheme.primaryColor.withAlpha(100),
                              iconColor: AppTheme.primaryColor,
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
              ),



              Align(
                alignment: Alignment.bottomRight,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48.0, right: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Transform.translate(
                          offset: const Offset(20, -40),
                          child: _FloatingHexMenu(
                            mainColor: AppTheme.tertiaryColor.withAlpha(90),
                            mainIconColor: AppTheme.primaryColor,
                            mainBorderColor: AppTheme.tertiaryColor,
                            menuColor: AppTheme.tertiaryColor.withAlpha(10),
                            menuIconColor: AppTheme.tertiaryColor,
                            menuBorderColor: AppTheme.primaryColor,
                            mainIcon: Icons.shield_rounded,
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
              ),
            ],
          );
        },
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
  final List<_MenuAction> menuItems;
  final Color mainColor;
  final Color mainIconColor;
  final Color mainBorderColor;
  final Color menuColor;
  final Color menuIconColor;
  final Color menuBorderColor;

  const _FloatingHexMenu({
    required this.mainIcon,
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
          height: 72 + (widget.menuItems.length * 60.0 * _expandAnimation.value),
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
                icon: _isOpen ? Icons.close_rounded : widget.mainIcon,
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
        final double offset = (index + 1) * 60.0 * _expandAnimation.value;
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
      elevation: 9,
      shadowColor: Colors.black45,
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
