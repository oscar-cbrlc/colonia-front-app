import 'package:colonia_front_app/l10n/app_localizations.dart';

enum ActivityType {
  onFoot,
  onBike;

  String get name => toString().split('.').last;

  String getLocale(AppLocalizations locale) {
    switch (this) {
      case onFoot:
        return locale.onFoot;
      case onBike:
        return locale.onBike;
    }
  }
}