import 'package:freezed_annotation/freezed_annotation.dart';

part 'boost.freezed.dart';
part 'boost.g.dart';

Object? _parseNumOrString(Map json, String key) {
  final val = json[key];
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return val;
}

@freezed
abstract class Boost with _$Boost {
  const Boost._();
  const factory Boost({
    @JsonKey(name: 'boost_id') required int id,
    @JsonKey(name: 'boost_type') required String type,
    @JsonKey(name: 'boost_effect', readValue: _parseNumOrString) required double effect,
  }) = _Boost;

  factory Boost.fromJson(Map<String, dynamic> json) => _$BoostFromJson(json);
}