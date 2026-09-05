import 'package:freezed_annotation/freezed_annotation.dart';

part 'boost_inventory.freezed.dart';
part 'boost_inventory.g.dart';

@freezed
abstract class BoostInventory with _$BoostInventory {
  const BoostInventory._();
  const factory BoostInventory({
    @JsonKey(name: 'boost_id') required int boostId,
    @JsonKey(name: 'inventory_quantity') required int inventoryQuantity,
    @JsonKey(name: 'boost_name') required String boostName,
    @JsonKey(name: 'boost_description') required String boostDescription,
    @JsonKey(name: 'boost_effect') required double boostEffect,
    @JsonKey(name: 'boost_image') required String boostImage,
  }) = _BoostInventory;

  factory BoostInventory.fromJson(Map<String, dynamic> json) => _$BoostInventoryFromJson(json);
}