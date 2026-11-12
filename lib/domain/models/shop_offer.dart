import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_offer.freezed.dart';
part 'shop_offer.g.dart';

enum ShopOfferType {
  item,
  bundle;

  String get name => toString().split('.').last;

  String getLocale(AppLocalizations locale) {
    switch(this) {
      case ShopOfferType.item:
        return locale.item;
      case ShopOfferType.bundle:
        return locale.bundle;
    }
  }
}

@freezed
abstract class ShopOffer with _$ShopOffer {
  const ShopOffer._();
  const factory ShopOffer({
    @JsonKey(name: 'offer_id') required int id,
    @JsonKey(name: 'offer_name') required String name,
    @JsonKey(name: 'offer_type') required String type,
    @JsonKey(name: 'offer_image') required String image,
    @JsonKey(name: 'offer_price') required int price,
    @JsonKey(name: 'avatar_item') AvatarItem? avatarItem,
    @JsonKey(name: 'bundle') Bundle? bundle,
    @JsonKey(name: 'avatar_items') List<AvatarItem>? avatarItems,
  }) = _ShopOffer;

  factory ShopOffer.fromJson(Map<String, dynamic> json) {
    num parsedPrice = 0;
    final rawPrice = json['offer_price'];
    if (rawPrice is num) {
      parsedPrice = rawPrice;
    } else if (rawPrice is String) {
      parsedPrice = num.tryParse(rawPrice) ?? 0;
    }

    Bundle? bundleObj;
    List<AvatarItem>? items;

    if (json['bundle'] != null && json['bundle'] is Map<String, dynamic>) {
      final bundleMap = json['bundle'] as Map<String, dynamic>;
      if (bundleMap.containsKey('bundle') && bundleMap['bundle'] is Map<String, dynamic>) {
        bundleObj = Bundle.fromJson(bundleMap['bundle'] as Map<String, dynamic>);
      } else if (bundleMap.containsKey('bundle_id')) {
        bundleObj = Bundle.fromJson(bundleMap);
      }

      if (bundleMap.containsKey('avatar_items') && bundleMap['avatar_items'] is List) {
        items = (bundleMap['avatar_items'] as List)
            .map((e) => AvatarItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    if (items == null && json['avatar_items'] != null && json['avatar_items'] is List) {
      items = (json['avatar_items'] as List)
          .map((e) => AvatarItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    AvatarItem? singleItem;
    if (json['avatar_item'] != null && json['avatar_item'] is Map<String, dynamic>) {
      singleItem = AvatarItem.fromJson(json['avatar_item'] as Map<String, dynamic>);
    }

    final String offerType = (json['offer_type'] as String?) ?? 'item';

    return ShopOffer(
      id: json['offer_id'] is num
          ? (json['offer_id'] as num).toInt()
          : (int.tryParse(json['offer_id'].toString()) ?? 0),
      name: (json['offer_name'] as String?) ?? '',
      type: offerType,
      image: (json['offer_image'] as String?) ?? '',
      price: parsedPrice.round(),
      avatarItem: singleItem,
      bundle: bundleObj,
      avatarItems: items,
    );
  }

  ShopOfferType get typeEnum {
    return ShopOfferType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => ShopOfferType.item,
    );
  }

  List<AvatarItem> get itemsInOffer {
    if (avatarItem != null) return [avatarItem!];
    if (avatarItems != null && avatarItems!.isNotEmpty) return avatarItems!;
    return [];
  }
}

@freezed
abstract class Bundle with _$Bundle {
  const Bundle._();
  const factory Bundle({
    @JsonKey(name: 'bundle_id') required int id,
    @JsonKey(name: 'bundle_name') required String name,
    @JsonKey(name: 'bundle_image') required String image,
  }) = _Bundle;
  factory Bundle.fromJson(Map<String, dynamic> json) => _$BundleFromJson(json);
}