import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

class MapControlGroup extends StatelessWidget {
  final Listenable listenable;
  final double currentBearing;
  final bool isFollowingUser;
  final bool? showPoints;
  final VoidCallback onCenterOnUser;
  final VoidCallback? onToggleShowPoints;
  final VoidCallback onResetNorth;
  final bool showPointsButton;

  const MapControlGroup({
    super.key,
    required this.listenable,
    required this.currentBearing,
    this.isFollowingUser = false,
    this.showPoints,
    required this.onCenterOnUser,
    this.onToggleShowPoints,
    required this.onResetNorth,
    this.showPointsButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IndividualMapButton(
              icon: isFollowingUser ? Icons.my_location : Icons.location_searching,
              iconColor: isFollowingUser ? AppTheme.secondaryColor : Colors.white54,
              borderColor: isFollowingUser
                  ? AppTheme.secondaryColor.withAlpha(180)
                  : Colors.white24,
              onPressed: () {
                HapticFeedback.mediumImpact();
                onCenterOnUser();
              },
            ),
            const SizedBox(height: 8),

            if (showPointsButton)...[
              IndividualMapButton(
                icon: showPoints! ? Icons.shield_sharp : Icons.shield_outlined,
                iconColor: showPoints! ? AppTheme.primaryColor : Colors.white38,
                borderColor: showPoints! ? AppTheme.primaryColor.withAlpha(180) : null,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onToggleShowPoints!();
                },
              ),
              const SizedBox(height: 8),
            ],

            IndividualMapButton(
              iconWidget: Transform.rotate(
                angle: -currentBearing * (3.141592653589793 / 180),
                child: const Icon(
                  Icons.navigation,
                  color: AppTheme.secondaryColor,
                  size: 20,
                ),
              ),
              borderColor: AppTheme.secondaryColor.withAlpha(180),
              onPressed: () {
                HapticFeedback.mediumImpact();
                onResetNorth();
              },
            ),
          ],
        );
      },
    );
  }
}

class IndividualMapButton extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconColor;
  final Color? borderColor;
  final Color? splashColor;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const IndividualMapButton({
    super.key,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.borderColor,
    this.splashColor,
    required this.onPressed,
    this.width = 44,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppTheme.primaryColor.withAlpha(120);
    final splashCol = splashColor ?? AppTheme.primaryColor;

    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: AppTheme.darkBackground.withAlpha(220),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: effectiveBorderColor,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          splashColor: splashCol.withAlpha(40),
          child: Center(
            child: iconWidget ?? Icon(icon, color: iconColor ?? Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
