import 'package:colonia_front_app/domain/models/enums/boost_type.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'boost_inventory.freezed.dart';
part 'boost_inventory.g.dart';

Object? _parseNumOrString(Map json, String key) {
  final val = json[key];
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return val;
}

@freezed
abstract class BoostInventory with _$BoostInventory {
  const BoostInventory._();
  const factory BoostInventory({
    @JsonKey(name: 'boost_id') required int id,
    @JsonKey(name: 'boost_type') required String type,
    @JsonKey(name: 'inventory_quantity') required int quantity,
    @JsonKey(name: 'boost_effect', readValue: _parseNumOrString) required double effect,
  }) = _BoostInventory;

  factory BoostInventory.fromJson(Map<String, dynamic> json) => _$BoostInventoryFromJson(json);

  IconData get icon => _boostTypeIcons[type] ?? Icons.bolt;

  String getName(AppLocalizations locale) {
    if (type == BoostType.score.name) return '${locale.boostMultiplierName} x$effect';
    if (type == BoostType.impact_area.name) return '${locale.boostRadioName} ${(effect*100).round()}%';
    if (type == BoostType.impact_distance.name) return '${locale.boostDistanceName} ${(effect*100).round()}%';
    return locale.errorUnknown;
  }

  String getDescription(AppLocalizations locale) {
    if (type == BoostType.score.name) {
      return locale.boostMultiplierDescription(effect);
    }
    if (type == BoostType.impact_area.name) {
      return locale.boostRadioDescription((effect*100).round());
    }
    if (type == BoostType.impact_distance.name) {
      return locale.boostDistanceDescription((effect*100).round());
    }
    return "";
  }

  String getEffectFormatted() {
    if (type == BoostType.score.name) {
      return effect.toStringAsFixed(2);
    }
    return '${(effect*100).round()}%';
  }
}

final Map<String, IconData> _boostTypeIcons = {
  BoostType.score.name: Icons.electric_bolt_sharp,
  BoostType.impact_distance.name: Icons.linear_scale_sharp,
  BoostType.impact_area.name: Icons.hexagon_sharp,
};