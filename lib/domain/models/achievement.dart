import 'package:colonia_front_app/domain/models/enums/achievement_type.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

@freezed
abstract class Achievement with _$Achievement {
  const Achievement._();

  const factory Achievement({
    @JsonKey(name: 'achievement_id') required int id,
    @JsonKey(name: 'achievement_name') required String name,
    @JsonKey(name: 'achievement_type') required String type,
    @JsonKey(name: 'achievement_objective') required int objective,
    @JsonKey(name: 'achievement_acquisition_date') String? acquisitionDate,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);

  String? get formattedAcquisitionDate {
    if (acquisitionDate == null || acquisitionDate!.isEmpty) return null;

    DateTime? date;
    try {
      date = DateTime.parse(acquisitionDate!);
    } catch (_) {
      final ms = int.tryParse(acquisitionDate!);
      if (ms != null) {
        date = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }

    if (date == null) return acquisitionDate;

    return DateFormat('dd/MM/yyyy').format(date);
  }

  String getDescription(AppLocalizations locale) {
    if (type == AchievementType.total_distance.name) {
      // meters to km
      return locale.achievementTotalDistanceDescription(objective ~/ 1000);
    }
    if (type == AchievementType.total_time.name) {
      // seconds to hours
      return locale.achievementTotalTimeDescription(objective ~/ 3600);
    }
    if (type == AchievementType.captured_territories.name) {
      return locale.achievementTerritoriesCapturedDescription(objective);
    }
    if (type == AchievementType.total_attack.name) {
      return locale.achievementTotalAttackDescription(objective);
    }
    if (type == AchievementType.total_defense.name) {
      return locale.achievementTotalDefenseDescription(objective);
    }
    return "";
  }

  String getTitle(AppLocalizations locale) {
    switch(name) {
      case 'ach_dist_1':
        return locale.ach_dist_1;
      case 'ach_dist_2':
        return locale.ach_dist_2;
      case 'ach_dist_3':
        return locale.ach_dist_3;
      case 'ach_dist_4':
        return locale.ach_dist_4;
      case 'ach_dist_5':
        return locale.ach_dist_5;
      case 'ach_time_1':
        return locale.ach_time_1;
      case 'ach_time_2':
        return locale.ach_time_2;
      case 'ach_time_3':
        return locale.ach_time_3;
      case 'ach_time_4':
        return locale.ach_time_4;
      case 'ach_time_5':
        return locale.ach_time_5;
      case 'ach_atk_1':
        return locale.ach_atk_1;
      case 'ach_atk_2':
        return locale.ach_atk_2;
      case 'ach_atk_3':
        return locale.ach_atk_3;
      case 'ach_atk_4':
        return locale.ach_atk_4;
      case 'ach_atk_5':
        return locale.ach_atk_5;
      case 'ach_def_1':
        return locale.ach_def_1;
      case 'ach_def_2':
        return locale.ach_def_2;
      case 'ach_def_3':
        return locale.ach_def_3;
      case 'ach_def_4':
        return locale.ach_def_4;
      case 'ach_def_5':
        return locale.ach_def_5;
      case 'ach_terr_1':
        return locale.ach_terr_1;
      case 'ach_terr_2':
        return locale.ach_terr_2;
      case 'ach_terr_3':
        return locale.ach_terr_3;
      case 'ach_terr_4':
        return locale.ach_terr_4;
      case 'ach_terr_5':
        return locale.ach_terr_5;
      default:
        return 'default';
    }
  }
}
