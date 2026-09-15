import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_result.freezed.dart';
part 'activity_result.g.dart';

Object? _parseNumOrString(Map json, String key) {
  final val = json[key];
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return val;
}

@freezed
abstract class ActivityResult with _$ActivityResult{
  const ActivityResult._();
  const factory ActivityResult({
    @JsonKey(name: 'user') required ActivityResultUser user,
    @JsonKey(name: 'territories') required List<Territory> territories,
  }) = _ActivityResult;

  factory ActivityResult.fromJson(Map<String, dynamic> json) => _$ActivityResultFromJson(json);
}

@freezed
abstract class ActivityResultUser with _$ActivityResultUser{
  const ActivityResultUser._();
  const factory ActivityResultUser({
    @JsonKey(name: 'user_id') required int id,
    @JsonKey(name: 'user_name') required String name,
    @JsonKey(name: 'total_distance', readValue: _parseNumOrString) required double totalDistance,
    @JsonKey(name: 'total_time', readValue: _parseNumOrString) required double totalTime
  }) = _ActivityResultUser;

  factory ActivityResultUser.fromJson(Map<String, dynamic> json) => _$ActivityResultUserFromJson(json);
}

