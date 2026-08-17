import 'package:freezed_annotation/freezed_annotation.dart';

part 'territory.freezed.dart';
part 'territory.g.dart';


@freezed
abstract class Territory with _$Territory {
  const Territory._();
  const factory Territory({
    @JsonKey(name: 'territory_id') required String id,
    @JsonKey(name: 'team_id') required int teamId,
    @JsonKey(name: 'health_points') required double healthPoints
  }) = _Territory;

  factory Territory.fromJson(Map<String, dynamic> json) => _$TerritoryFromJson(json);
}