import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum AchievementType {
  total_distance,
  total_time,
  captured_territories,
  total_attack,
  total_defense;

  String get name => toString().split('.').last;

  IconData getIcon() {
    switch(this) {
      case AchievementType.total_distance:
        return Icons.straighten;
      case AchievementType.total_time:
        return Icons.timer;
      case AchievementType.captured_territories:
        return Icons.hexagon_outlined;
      case AchievementType.total_attack:
        return Icons.flash_on_sharp;
      case AchievementType.total_defense:
        return Icons.shield_sharp;
    }
  }

  String getDisplayName(AppLocalizations locale) {
    switch (this) {
      case AchievementType.total_distance:
        return locale.distance;
      case AchievementType.total_time:
        return locale.time;
      case AchievementType.captured_territories:
        return locale.captured;
      case AchievementType.total_attack:
        return locale.attack;
      case AchievementType.total_defense:
        return locale.defense;
    }
  }
}