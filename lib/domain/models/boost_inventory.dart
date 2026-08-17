import 'package:freezed_annotation/freezed_annotation.dart';

part 'boost_inventory.freezed.dart';
part 'boost_inventory.g.dart';


@freezed
abstract class BoostInventory with _$BoostInventory {
  const BoostInventory._();
  const factory BoostInventory({
    @JsonKey(name: 'boost_id') required int boostId,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'amount') required int amount,
  }) = _BoostInventory;

  factory BoostInventory.fromJson(Map<String, dynamic> json) => _$BoostInventoryFromJson(json);
}