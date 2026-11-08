import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum TrainingType {
  distance,
  free,
  pace,
  time,
  timeTrial;

  String getLocale(AppLocalizations locale) {
    switch (this) {
      case TrainingType.distance:
        return locale.distance;
      case TrainingType.free:
        return locale.free;
      case TrainingType.pace:
        return locale.pace;
      case TrainingType.time:
        return locale.time;
      case TrainingType.timeTrial:
        return locale.timeTrial;
    }
  }

  IconData getIcon() {
    switch (this) {
      case TrainingType.distance:
        return Icons.straighten;
      case TrainingType.free:
        return Icons.timer_off_outlined;
      case TrainingType.pace:
        return Icons.speed;
      case TrainingType.time:
        return Icons.timer;
      case TrainingType.timeTrial:
        return Icons.av_timer_sharp;
    }
  }
}