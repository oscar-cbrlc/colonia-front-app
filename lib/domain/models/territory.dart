import 'package:freezed_annotation/freezed_annotation.dart';

part 'territory.freezed.dart';
part 'territory.g.dart';

Object? _readHealthPoints(Map json, String key) {
  final val = json[key];
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return val;
}

@freezed
abstract class Territory with _$Territory {
  const Territory._();

  const factory Territory({
    @JsonKey(name: 'territory_id') required String id,
    @JsonKey(name: 'health_points', readValue: _readHealthPoints) required double healthPoints,
    @JsonKey(name: 'action') String? action,
    @JsonKey(name: 'team') TerritoryTeam? team,
  }) = _Territory;

  factory Territory.fromJson(Map<String, dynamic> json) => _$TerritoryFromJson(json);
}

@freezed
abstract class TerritoryTeam with _$TerritoryTeam {
  const TerritoryTeam._();

  const factory TerritoryTeam({
    @JsonKey(name: 'team_id') required int id,
    @JsonKey(name: 'team_name') required String name,
    @JsonKey(name: 'team_color') required int color,
  }) = _TerritoryTeam;

  factory TerritoryTeam.fromJson(Map<String, dynamic> json) => _$TerritoryTeamFromJson(json);
}
