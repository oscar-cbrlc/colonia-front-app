import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/data/services/api/avatar_service.dart';
import 'package:colonia_front_app/data/services/local_storage_service.dart';
import 'package:colonia_front_app/domain/models/avatar_item.dart';

class AvatarItemRepository extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final AvatarService _avatarService;

  List<AvatarItem> _catalogItems = [];
  List<AvatarInventoryItem> _myInventory = [];
  bool _isLoading = false;

  AvatarItemRepository({
    LocalStorageService? localStorageService,
    required this._avatarService,
  }) : _localStorageService = localStorageService ?? LocalStorageService();

  String get baseModelPath => GameConfig.baseModelPath;

  List<AvatarItem> get availableAvatarItems => List.unmodifiable(_catalogItems);

  List<AvatarInventoryItem> get myInventory => List.unmodifiable(_myInventory);
  bool get isLoading => _isLoading;

  Future<List<AvatarItem>> fetchCatalogItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _avatarService.listAvatarItems();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _catalogItems = data
            .where((json) => json != null && json is Map<String, dynamic>)
            .map((json) => AvatarItem.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _catalogItems;
      }
    } catch (e, stack) {
      debugPrint('AvatarItemRepository: Error fetching catalog items: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return availableAvatarItems;
  }

  Future<List<AvatarInventoryItem>> fetchMyInventory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _avatarService.getMyAvatarInventory();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _myInventory = data
            .where((json) => json != null && json is Map<String, dynamic>)
            .map((json) => AvatarInventoryItem.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _myInventory;
      }
    } catch (e, stack) {
      debugPrint('AvatarItemRepository: Error fetching inventory: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _myInventory;
  }

  Future<AvatarUpdateResponse?> updateAvatar({
    int? head,
    int? neck,
    int? body,
    int? footwear,
    int? color,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updateData = <String, dynamic>{};
      if (head != null) updateData['avatar_head'] = head;
      if (neck != null) updateData['avatar_neck'] = neck;
      if (body != null) updateData['avatar_body'] = body;
      if (footwear != null) updateData['avatar_footwear'] = footwear;
      if (color != null) updateData['avatar_color'] = color;

      final response = await _avatarService.updateAvatar(updateData);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final updateResponse = AvatarUpdateResponse.fromJson(data);
        notifyListeners();
        return updateResponse;
      } else {
        debugPrint('AvatarItemRepository: Error updating avatar: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('AvatarItemRepository: Error updating avatar: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> isModelDownloaded(int modelId) async {
    final path = await getStoredModelPath(modelId);
    if (path == null) return false;
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 0;
  }

  Future<void> checkAndDownloadModels({
    List<AvatarItem>? items,
    required void Function(double progress) onProgress,
  }) async {
    try {
      await fetchCatalogItems();
      final targetItems = items ?? availableAvatarItems;
      final dir = await getApplicationDocumentsDirectory();

      final List<AvatarItem> missingItems = [];
      for (final item in targetItems) {
        final isDownloaded = await isModelDownloaded(item.id);
        if (!isDownloaded) {
          missingItems.add(item);
        }
      }

      if (missingItems.isEmpty) {
        onProgress(1.0);
        return;
      }

      final existingStored = await _localStorageService.getAvatarItemModels();
      final List<AvatarItemModel> updatedStored = List.from(existingStored);

      double completedCount = 0;
      for (int i = 0; i < missingItems.length; i++) {
        final item = missingItems[i];
        final fileName = '${item.name}.glb';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);

        http.Request request;
        http.StreamedResponse response;

        try {
          request = http.Request('GET', Uri.parse(item.url));
          response = await http.Client().send(request);

        } catch (e) {
          debugPrint('AvatarItemRepository: Error checking/downloading models: $e');
          continue;
        }


        if (response.statusCode == 200) {
          final contentLength = response.contentLength ?? 0;
          int received = 0;
          final sink = file.openWrite();

          await response.stream.forEach((chunk) {
            received += chunk.length;
            sink.add(chunk);
            if (contentLength > 0) {
              final itemProgress = received / contentLength;
              final totalProgress = (completedCount + itemProgress) / missingItems.length;
              onProgress(totalProgress.clamp(0.0, 1.0));
            }
          });

          await sink.close();

          updatedStored.removeWhere((m) => m.id == item.id);
          updatedStored.add(AvatarItemModel(id: item.id, filePath: filePath));
        }

        completedCount += 1.0;
        onProgress((completedCount / missingItems.length).clamp(0.0, 1.0));
      }

      await _localStorageService.saveAvatarItemModels(updatedStored);
      onProgress(1.0);
    } catch (e) {
      debugPrint('AvatarItemRepository: Error checking/downloading models: $e');
    }
  }

  Future<List<AvatarItemModel>> getStoredItemModels() async {
    return await _localStorageService.getAvatarItemModels();
  }

  Future<String?> getStoredModelPath(int modelId) async {
    final models = await _localStorageService.getAvatarItemModels();
    for (final element in models) {
      if (element.id == modelId) return element.filePath;
    }
    return null;
  }

  Future<String> getApplicationDocDirectory() async {
    return await getApplicationDocumentsDirectory().then((dir) => dir.path);
  }
}
