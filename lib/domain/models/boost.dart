import 'package:freezed_annotation/freezed_annotation.dart';

part 'boost.freezed.dart';
part 'boost.g.dart';


@freezed
abstract class Boost with _$Boost {
  const Boost._();
  const factory Boost({
    @JsonKey(name: 'boost_id') required int id,
    @JsonKey(name: 'boost_name') required String name,
    @JsonKey(name: 'boost_description') @Default("") String description,
    @JsonKey(name: 'boost_effect') @Default(1.0) double effect,
    @JsonKey(name: 'boost_image') @Default("") String image,
  }) = _Boost;

  factory Boost.fromJson(Map<String, dynamic> json) => _$BoostFromJson(json);
}