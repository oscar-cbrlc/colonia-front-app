import 'package:colonia_front_app/ui/core/ui/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: const SizedBox(
            width: 48,
            height: 48,
            child: AppLoadingIndicator(
              color: AppTheme.primaryColor,
            ),
          )
      ),
    );
  }
}
