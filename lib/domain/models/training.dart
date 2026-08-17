
import 'package:freezed_annotation/freezed_annotation.dart';

part 'training.freezed.dart';
part 'training.g.dart';


@freezed
abstract class Training with _$Training {
  const Training._();
  const factory Training({
    @JsonKey(name: 'training_id') required int id,
    @JsonKey(name: 'training_name') required String name,
    @JsonKey(name: 'attack_points') @Default(1.0) double attackPoints,
    @JsonKey(name: 'deffence_points') @Default(1.0) double defensePoints,
  }) = _Training;

  factory Training.fromJson(Map<String, dynamic> json) => _$TrainingFromJson(json);
}
