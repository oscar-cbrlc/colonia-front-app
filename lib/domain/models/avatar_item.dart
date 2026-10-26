import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'avatar_item.freezed.dart';
part 'avatar_item.g.dart';

enum AvatarItemType {
  head,
  neck,
  body,
  footwear;

  // TODO: locales
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