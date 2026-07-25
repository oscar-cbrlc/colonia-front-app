import 'dart:ui';
import 'package:colonia_front_app/domain/models/session_models.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/activity/view_models/activity_viewmodel.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:colonia_front_app/env/env.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.viewModel});
  final ActivityViewModel viewModel;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Widget get _activityGroup => Visibility(
      visible: widget.viewModel.playingState != PlayingState.playing,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showActivitySelector();
    });
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
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      color: AppTheme.primaryColor,
                      size: 32.0,
                    ),
                  ],
                ),
              ),
            ),
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
                    onPressed: _showActivitySelector,
                    child: Text(locale.startActivity)
                )
            ),
          ),
        ),

        _activityGroup,
      ],
    );
  }


  void _showActivitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivitySelectorSheet(viewModel: widget.viewModel),
    );
  }



  void handlePushPlayButton() {
    widget.viewModel.onPushPlayButton();
  }
}

class _ActivitySelectorSheet extends StatefulWidget {
  final ActivityViewModel viewModel;
  const _ActivitySelectorSheet({required this.viewModel});

  @override
  State<_ActivitySelectorSheet> createState() => _ActivitySelectorSheetState();
}

class _ActivitySelectorSheetState extends State<_ActivitySelectorSheet> {
  final TextEditingController _kmController = TextEditingController(text: "0");
  final TextEditingController _mController = TextEditingController(text: "0");
  final TextEditingController _hController = TextEditingController(text: "0");
  final TextEditingController _minController = TextEditingController(text: "0");
  final TextEditingController _secController = TextEditingController(text: "0");


  @override
  void dispose() {
    _kmController.dispose();
    _mController.dispose();
    _hController.dispose();
    _minController.dispose();
    _secController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final double km = double.tryParse(_kmController.text) ?? 0;
    final double m = double.tryParse(_mController.text) ?? 0;
    final int h = int.tryParse(_hController.text) ?? 0;
    final int min = int.tryParse(_minController.text) ?? 0;
    final int sec = int.tryParse(_secController.text) ?? 0;

    double finalTarget = 0;
    final training = widget.viewModel.selectedTraining;

    if (training == "distance" || training == "pace" || training == "timeTrial") {
      finalTarget = (km * 1000) + m;
    } else if (training == "time") {
      finalTarget = (h * 3600) + (min * 60) + sec.toDouble();
    }

    widget.viewModel.setActivityConfig(target: finalTarget);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final locale = AppLocalizations.of(context)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubicEmphasized,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + bottomInset,
      ),
      decoration: ShapeDecoration(
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        color: AppTheme.darkBackground.withAlpha(240),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListenableBuilder(
            listenable: Listenable.merge([widget.viewModel, _kmController, _mController, _hController, _minController, _secController]),
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      locale.activity.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.tertiaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                      children: [
                        _ChoiceChip(
                          label: locale.walk,
                          icon: Icons.directions_walk,
                          isSelected: widget.viewModel.selectedActivity == "walk",
                          onSelected: () => widget.viewModel.setActivityConfig(activity: "walk"),
                          color: AppTheme.walkColor,
                        ),
                        _ChoiceChip(
                          label: locale.run,
                          icon: Icons.directions_run,
                          isSelected: widget.viewModel.selectedActivity == "run",
                          onSelected: () => widget.viewModel.setActivityConfig(activity: "run"),
                          color: AppTheme.runColor,
                        ),
                        _ChoiceChip(
                          label: locale.bike,
                          icon: Icons.directions_bike,
                          isSelected: widget.viewModel.selectedActivity == "bike",
                          onSelected: () => widget.viewModel.setActivityConfig(activity: "bike"),
                          color: AppTheme.bikeColor,
                        ),
                      ]
                    ),
                    const SizedBox(height: 24),
                    Text(
                      locale.training.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.tertiaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                      children: [
                        _ChoiceChip(
                          label: locale.free,
                          icon: Icons.timer_off,
                          isSelected: widget.viewModel.selectedTraining == "free",
                          onSelected: () => widget.viewModel.setActivityConfig(training: "free"),
                          color: AppTheme.primaryColor,
                        ),
                        _ChoiceChip(
                          label: locale.distance,
                          icon: Icons.straighten,
                          isSelected: widget.viewModel.selectedTraining == "distance",
                          onSelected: () => widget.viewModel.setActivityConfig(training: "distance"),
                          color: AppTheme.primaryColor,
                        ),
                        _ChoiceChip(
                          label: locale.time,
                          icon: Icons.timer,
                          isSelected: widget.viewModel.selectedTraining == "time",
                          onSelected: () => widget.viewModel.setActivityConfig(training: "time"),
                          color: AppTheme.primaryColor,
                        ),
                        _ChoiceChip(
                          label: locale.pace,
                          icon: Icons.linear_scale,
                          isSelected: widget.viewModel.selectedTraining == "pace",
                          onSelected: () => widget.viewModel.setActivityConfig(training: "pace"),
                          color: AppTheme.primaryColor,
                        ),
                        _ChoiceChip(
                          label: locale.timeTrial,
                          icon: Icons.av_timer_sharp,
                          isSelected: widget.viewModel.selectedTraining == "timeTrial",
                          onSelected: () => widget.viewModel.setActivityConfig(training: "timeTrial"),
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (widget.viewModel.selectedTraining != "free" && widget.viewModel.selectedTraining != null) ...[
                      Text(
                        locale.setObjective.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.tertiaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildObjectiveInputs(context),
                      const SizedBox(height: 32),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onConfirm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: Text(locale.confirm.toUpperCase()),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveInputs(BuildContext context) {
    final training = widget.viewModel.selectedTraining;
    final locale = AppLocalizations.of(context)!;
    if (training == "distance") {
      return Row(
        children: [
          Expanded(child: _TargetInputField(controller: _kmController, label: locale.km.toUpperCase())),
          const SizedBox(width: 16),
          Expanded(child: _TargetInputField(controller: _mController, label: locale.meters.toUpperCase())),
        ],
      );
    } else if (training == "time") {
      return Row(
        children: [
          Expanded(child: _TargetInputField(controller: _hController, label: locale.hours.toUpperCase())),
          const SizedBox(width: 12),
          Expanded(child: _TargetInputField(controller: _minController, label: locale.min.toUpperCase())),
          const SizedBox(width: 12),
          Expanded(child: _TargetInputField(controller: _secController, label: locale.sec.toUpperCase())),
        ],
      );
    } else if (training == "pace") {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _TargetInputField(controller: _kmController, label: locale.km.toUpperCase())),
              const SizedBox(width: 16),
              Expanded(child: _TargetInputField(controller: _mController, label: locale.meters.toUpperCase())),
            ],
          ),
          const SizedBox(height: 16),
          _TargetInputField(controller: _minController, label: locale.targetPace.toUpperCase()),
        ],
      );
    } else if (training == "timeTrial") {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _TargetInputField(controller: _kmController, label: locale.km.toUpperCase())),
              const SizedBox(width: 16),
              Expanded(child: _TargetInputField(controller: _mController, label: locale.meters.toUpperCase())),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TargetInputField(controller: _hController, label: locale.hours.toUpperCase())),
              const SizedBox(width: 12),
              Expanded(child: _TargetInputField(controller: _minController, label: locale.min.toUpperCase())),
              const SizedBox(width: 12),
              Expanded(child: _TargetInputField(controller: _secController, label: locale.sec.toUpperCase())),
            ],
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _TargetInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _TargetInputField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withAlpha(10),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.tertiaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color color;

  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: isSelected ? color : color.withAlpha(20),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.white : color.withAlpha(100),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.darkBackground : Colors.white,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTheme.darkBackground : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
