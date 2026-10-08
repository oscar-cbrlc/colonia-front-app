import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

class MapControlGroup extends StatelessWidget {
  final Listenable listenable;
  final double currentBearing;
  final bool showPoints;
  final VoidCallback onCenterOnUser;
  final VoidCallback onToggleShowPoints;
  final VoidCallback onResetNorth;

  const MapControlGroup({
    super.key,
    required this.listenable,
    required this.currentBearing,
    required this.showPoints,
    required this.onCenterOnUser,
    required this.onToggleShowPoints,
    required this.onResetNorth,
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
              icon: Icons.my_location,
              iconColor: Colors.redAccent,
              borderColor: Colors.redAccent.withAlpha(150),
              onPressed: () {
                HapticFeedback.mediumImpact();
                onCenterOnUser();
              },
            ),
            const SizedBox(height: 8),

            IndividualMapButton(
              icon: showPoints ? Icons.shield_sharp : Icons.shield_outlined,
              iconColor: showPoints ? AppTheme.primaryColor : Colors.white38,
              borderColor: showPoints ? AppTheme.primaryColor.withAlpha(180) : null,
              onPressed: () {
                HapticFeedback.mediumImpact();
                onToggleShowPoints();
              },
            ),
            const SizedBox(height: 8),

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
  final VoidCallback onPressed;

  const IndividualMapButton({
    super.key,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppTheme.primaryColor.withAlpha(120);

    return Container(
      width: 44,
      height: 44,
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
          splashColor: AppTheme.primaryColor.withAlpha(40),
          child: Center(
            child: iconWidget ?? Icon(icon, color: iconColor ?? Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
