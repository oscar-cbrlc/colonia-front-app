import 'package:colonia_front_app/l10n/app_localizations.dart';

enum HarActivity {
  walk,
  run,
  bike,
  vehicle,
  standing,
  unknown;

  String get name => toString().split('.').last;
  String getLocale(AppLocalizations locale) {
    switch (this) {
      case HarActivity.walk:
        return locale.walk;
      case HarActivity.run:
        return locale.run;
      case HarActivity.bike:
        return locale.bike;
      case HarActivity.vehicle:
        return locale.vehicle;
      case HarActivity.standing:
        return locale.standing;
      default:
        return locale.unknown;
    }
  }
}