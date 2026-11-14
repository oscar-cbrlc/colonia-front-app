import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size = 36.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final targetColor = color ?? AppTheme.primaryColor;

    return Lottie.asset(
      'assets/animations/loading.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      delegates: LottieDelegates(
        values: [
          ValueDelegate.color(
            const ['**'],
            value: targetColor,
          ),
          ValueDelegate.strokeColor(
            const ['**'],
            value: targetColor,
          ),
        ],
      ),
    );
  }
}