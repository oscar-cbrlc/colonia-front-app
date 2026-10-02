import 'package:colonia_front_app/l10n/app_localizations.dart';

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
}