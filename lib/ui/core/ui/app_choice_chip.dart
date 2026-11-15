import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppChoiceChip extends StatelessWidget {
  final String label;
  final Widget? icon;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final BorderRadius? borderRadius;

  const AppChoiceChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onSelected,
    this.selectedColor = AppTheme.primaryColor,
    this.unselectedColor = AppTheme.tertiaryColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8);
    final textColor = isSelected ? AppTheme.darkBackground : Colors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: ShapeDecoration(
          color: isSelected
              ? selectedColor
              : unselectedColor.withAlpha(20),
          shape: BeveledRectangleBorder(
            borderRadius: effectiveBorderRadius,
            side: BorderSide(
              color: isSelected
                  ? Colors.white
                  : unselectedColor.withAlpha(100),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Oswald',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
