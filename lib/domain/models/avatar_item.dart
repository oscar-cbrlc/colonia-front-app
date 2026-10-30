import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'avatar_item.freezed.dart';
part 'avatar_item.g.dart';

enum AvatarItemType {
  head,
  neck,
  body,
  footwear;

  String getLocale(AppLocalizations locale) {
    switch(this) {
      case AvatarItemType.head:
        return locale.avatarItemTypeHead;
      case AvatarItemType.neck:
        return locale.avatarItemTypeNeck;
      case AvatarItemType.body:
        return locale.avatarItemTypeBody;
      case AvatarItemType.footwear:
        return locale.avatarItemTypeFootwear;
    }
  }
}
@freezed
abstract class AvatarItem with _$AvatarItem {
  const AvatarItem._();
  const factory AvatarItem({
    @JsonKey(name: 'avatar_item_id') required int id,
    @JsonKey(name: 'item_name') required String name,
    @JsonKey(name: 'item_type') required String type,
    @JsonKey(name: 'item_image') required String image,
    @JsonKey(name: 'item_url') required String url
  }) = _AvatarItem;

  factory AvatarItem.fromJson(Map<String, dynamic> json) => _$AvatarItemFromJson(json);
}

@freezed
abstract class AvatarItemModel with _$AvatarItemModel {
  const AvatarItemModel._();
  const factory AvatarItemModel({
    @JsonKey(name: 'avatar_item_id') required int id,
    @JsonKey(name: 'item_file_path') required String filePath,
  }) = _AvatarItemModel;
  factory AvatarItemModel.fromJson(Map<String, dynamic> json) => _$AvatarItemModelFromJson(json);
}


final Map<AvatarItemType, IconData> avatarItemTypeIcons = {
  AvatarItemType.head: Icons.headphones,
  AvatarItemType.neck: Icons.headphones,
  AvatarItemType.body: Icons.shopping_bag,
  AvatarItemType.footwear: Icons.do_not_step_sharp,
};

class AvatarInventoryItem {
  final AvatarItem item;
  final DateTime acquisitionDate;

  const AvatarInventoryItem({
    required this.item,
    required this.acquisitionDate,
  });

  factory AvatarInventoryItem.fromJson(Map<String, dynamic> json) {
    return AvatarInventoryItem(
      item: AvatarItem.fromJson(json['item'] as Map<String, dynamic>),
      acquisitionDate: DateTime.parse(json['item_adquisition_date'] as String),
    );
  }
}

class AvatarUpdateResponse {
  final String? userThumbnail;
  final String modelUrl;
  final AvatarItem? head;
  final AvatarItem? neck;
  final AvatarItem? body;
  final AvatarItem? footwear;
  final int color;

  const AvatarUpdateResponse({
    this.userThumbnail,
    required this.modelUrl,
    this.head,
    this.neck,
    this.body,
    this.footwear,
    required this.color,
  });

  factory AvatarUpdateResponse.fromJson(Map<String, dynamic> json) {
    return AvatarUpdateResponse(
      userThumbnail: json['user_thumbnail'] as String?,
      modelUrl: json['model_url'] as String,
      head: json['avatar_head'] != null
          ? AvatarItem.fromJson(json['avatar_head'] as Map<String, dynamic>)
          : null,
      neck: json['avatar_neck'] != null
          ? AvatarItem.fromJson(json['avatar_neck'] as Map<String, dynamic>)
          : null,
      body: json['avatar_body'] != null
          ? AvatarItem.fromJson(json['avatar_body'] as Map<String, dynamic>)
          : null,
      footwear: json['avatar_footwear'] != null
          ? AvatarItem.fromJson(json['avatar_footwear'] as Map<String, dynamic>)
          : null,
      color: json['avatar_color'] as int,
    );
  }
}