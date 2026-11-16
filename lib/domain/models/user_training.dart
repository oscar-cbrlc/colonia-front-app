import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_training.freezed.dart';
part 'user_training.g.dart';

Object? _parseNumOrDouble(Map json, String key) {
  final val = json[key];
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return val;
}

Object? _parseNumOrInt(Map json, String key) {
  final val = json[key];
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return val;
}

@freezed
abstract class UserTraining with _$UserTraining {
  const UserTraining._();

  const factory UserTraining({
    @JsonKey(name: 'training_uuid') required String uuid,
    @JsonKey(name: 'user_id', readValue: _parseNumOrInt) int? userId,
    @JsonKey(name: 'training_distance', readValue: _parseNumOrDouble) required double distance,
    @JsonKey(name: 'training_time', readValue: _parseNumOrInt) required int time,
    @JsonKey(name: 'territories') @Default([]) List<Territory> territories,
    @JsonKey(name: 'started_at') required DateTime startedAt,
    @JsonKey(name: 'boost_id', readValue: _parseNumOrInt) int? boostId,
    @JsonKey(name: 'boost') Boost? boost,
    @JsonKey(name: 'seconds_walk', readValue: _parseNumOrInt) @Default(0) int secondsWalk,
    @JsonKey(name: 'seconds_run', readValue: _parseNumOrInt) @Default(0) int secondsRun,
    @JsonKey(name: 'seconds_bike', readValue: _parseNumOrInt) @Default(0) int secondsBike,
    @JsonKey(name: 'meters_walk', readValue: _parseNumOrInt) @Default(0) int metersWalk,
    @JsonKey(name: 'meters_run', readValue: _parseNumOrInt) @Default(0) int metersRun,
    @JsonKey(name: 'meters_bike', readValue: _parseNumOrInt) @Default(0) int metersBike,
    @JsonKey(name: 'captured_territories', readValue: _parseNumOrInt) int? capturedTerritories,
    @JsonKey(name: 'training_attack', readValue: _parseNumOrInt) int? trainingAttack,
    @JsonKey(name: 'training_defence', readValue: _parseNumOrInt) int? trainingDefence,
  }) = _UserTraining;

  factory UserTraining.fromJson(Map<String, dynamic> json) => _$UserTrainingFromJson(json);

  Map<String, dynamic> toCreateJson(List<Map<String, dynamic>> territoriesJson) {
    return {
      'training_uuid': uuid,
      'training_distance': distance.round(),
      'training_time': time,
      'territories': territoriesJson,
      'started_at': startedAt.toUtc().toIso8601String(),
      'boost_id': boostId ?? boost?.id,
      'seconds_walk': secondsWalk,
      'seconds_run': secondsRun,
      'seconds_bike': secondsBike,
      'meters_walk': metersWalk,
      'meters_run': metersRun,
      'meters_bike': metersBike,
    };
  }
}
