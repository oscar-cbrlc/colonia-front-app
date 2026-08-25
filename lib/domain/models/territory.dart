import 'package:freezed_annotation/freezed_annotation.dart';

part 'territory.freezed.dart';
part 'territory.g.dart';

@freezed
abstract class Territory with _$Territory {
  const Territory._();
  const factory Territory({
    @JsonKey(name: 'territory_id') required String id,
    required TerritoryTeam? team,
    @JsonKey(name: 'health_points') required double healthPoints,
  }) = _Territory;

  factory Territory.fromJson(Map<String, dynamic> json) => _$TerritoryFromJson(json);

  bool get isCaptured => team != null;
}

@freezed
abstract class TerritoryTeam with _$TerritoryTeam {
  const factory TerritoryTeam({
    required int id,
    required String name,
    required int color,
  }) = _TerritoryTeam;

  factory TerritoryTeam.fromJson(Map<String, dynamic> json) => _$TerritoryTeamFromJson(json);
}