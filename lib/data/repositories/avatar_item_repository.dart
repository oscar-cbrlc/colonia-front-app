import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/data/services/local_storage_service.dart';
import 'package:colonia_front_app/domain/models/avatar_item.dart';

class AvatarItemRepository {

  final _localStorageService = LocalStorageService();

  String get baseModelPath => GameConfig.baseModelPath;

  // TODO: replace with API call when available
  void downloadAvatarItemModels() {
    final avatarItems = [
      AvatarItem(id: 1, name: 's_sandals', type: AvatarItemType.footwear.name, image: 'https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse3.mm.bing.net%2Fth%2Fid%2FOIP.7G49xS6h0NZJ6rwxayjF_gHaEA%3Fr%3D0%26pid%3DApi&f=1&ipt=7d1299f595c046aa963a86d548cfabcc33dd44e2a4a6217b25e4d3cdddfd8f51&ipo=images', url: 'https://colonia-assets.s3.us-west-2.amazonaws.com/models/shoes/crocs-texturized.glb'),
      AvatarItem(id: 2, name: 's_boots-cowboy', type: AvatarItemType.footwear.name, image: 'https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ffiles.cults3d.com%2Fuploaders%2F15566742%2Fillustration-file%2F0ba4b345-2e35-4cbc-ac3f-1c6ed8eb707e%2F2.jpg&f=1&nofb=1&ipt=ae961bf0bdf4f8edee233cfdbdeccc4897b1812b96dd446c0c457de70d4aa376&ipo=images', url: 'https://colonia-assets.s3.us-west-2.amazonaws.com/models/shoes/cowboyboots-texturized.glb'),
      AvatarItem(id: 3, name: 's_shoes-run', type: AvatarItemType.footwear.name, image: 'https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%2Fid%2FOIP.ublS3L1dxA2S1G3JAez0yAHaEO%3Fr%3D0%26pid%3DApi&f=1&ipt=38c9d625f84a7e54be3b7b2c9132d0d59aa3d1a2d229298ecffc0b7058a5ff62&ipo=images', url: 'https://colonia-assets.s3.us-west-2.amazonaws.com/models/shoes/runshoes-texturized.glb'),
    ];

    for (final item in avatarItems) {

    }
  }


  Future<List<AvatarItemModel>> getStoredItemModels() async {
    final avatarItemModels = await _localStorageService.getAvatarItemModels();
    return avatarItemModels;
  }

  Future<String> getStoredModelPath(int modelId) async {
    final avatarItemModels = await _localStorageService.getAvatarItemModels();
    final model = avatarItemModels.firstWhere((element) => element.id == modelId);
    return model.filePath;
  }
}