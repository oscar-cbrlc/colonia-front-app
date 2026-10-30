import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/avatar_item_repository.dart';
import 'package:colonia_front_app/data/services/api/avatar_service.dart';
import 'package:colonia_front_app/domain/models/achievement.dart';
import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/domain/models/user.dart';
import 'package:flutter/foundation.dart';

class UserProfileViewModel extends ChangeNotifier {
  User _user;
  bool _isLoading = false;
  String? _errorMessage;
  final AvatarItemRepository _avatarItemRepository;

  bool _isDownloadingModels = false;
  double _downloadProgress = 0.0;
  List<AvatarItemModel> _downloadedItemModels = [];


  UserProfileViewModel(this._user, this._avatarItemRepository)
  {
    checkAndDownloadAvatarModels();
  }

  User get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get baseModelPath => GameConfig.baseModelPath;
  bool get isDownloadingModels => _isDownloadingModels;
  double get downloadProgress => _downloadProgress;
  List<AvatarItemModel> get downloadedItemModels => List.unmodifiable(_downloadedItemModels);
  List<AvatarItem> get availableAvatarItems => _avatarItemRepository.availableAvatarItems;

  AvatarItemRepository get avatarItemRepository => _avatarItemRepository;
  bool isItemDownloaded(int id) {
    return _downloadedItemModels.any((model) => model.id == id);
  }

  bool isItemUnlocked(int itemId) {
    final isEquipped = _user.avatar?.head == itemId ||
        _user.avatar?.neck == itemId ||
        _user.avatar?.body == itemId ||
        _user.avatar?.footwear == itemId;
    final inInventory = _avatarItemRepository.myInventory.any((inv) => inv.item.id == itemId);
    return isEquipped || inInventory;
  }

  List<Achievement> get achievements => _user.achievements;
  List<Achievement> get unlockedAchievements => _user.unlockedAchievements;
  int get unlockedCount => unlockedAchievements.length;
  int get totalAchievements => achievements.length;

  int get level => _user.stats?.level ?? 0;
  int get xp => _user.stats?.xp ?? 0;
  int get xpForNextLevel => _user.xpForNextLevel ?? 0;

  String get formattedDistance {
    final distInKm = ((_user.stats?.totalDistance ?? 0.0) / 1000.0);
    return '${distInKm.toStringAsFixed(1)} km';
  }

  String get formattedTime {
    final totalSeconds = (_user.stats?.totalTime ?? 0.0).toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  String get formattedAttack {
    final attack = _user.stats?.totalAttack ?? 0.0;
    return attack.toInt().toString();
  }

  String get formattedDefense {
    final defense = _user.stats?.totalDefense ?? 0.0;
    return defense.toInt().toString();
  }

  String get formattedTerritoriesCaptured {
    final count = _user.stats?.territoriesCaptured ?? 0;
    return count.toString();
  }

  Future<void> loadDownloadedItemModels() async {
    await _avatarItemRepository.fetchCatalogItems();
    await _avatarItemRepository.fetchMyInventory();
    _downloadedItemModels = await _avatarItemRepository.getStoredItemModels();
    notifyListeners();
  }

  Future<void> checkAndDownloadAvatarModels({List<AvatarItem>? items}) async {
    _isDownloadingModels = true;
    _downloadProgress = 0.0;
    notifyListeners();

    await _avatarItemRepository.checkAndDownloadModels(
      items: items,
      onProgress: (progress) {
        _downloadProgress = progress;
        notifyListeners();
      },
    );

    _downloadedItemModels = await _avatarItemRepository.getStoredItemModels();
    _isDownloadingModels = false;
    notifyListeners();
  }

  Future<bool> updateAccountInfo({required String newUsername, String? newPassword}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = _user.copyWith(username: newUsername);
      await AuthRepository.instance.updateCurrentUser(updatedUser);
      _user = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UserProfileViewModel: Failed to update account info: $e');
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAvatar(UserAvatar updatedAvatar) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _avatarItemRepository.updateAvatar(
        head: updatedAvatar.head,
        neck: updatedAvatar.neck,
        body: updatedAvatar.body,
        footwear: updatedAvatar.footwear,
        color: updatedAvatar.color,
      );

      final updatedUser = _user.copyWith(avatar: updatedAvatar);
      await AuthRepository.instance.updateCurrentUser(updatedUser);
      _user = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UserProfileViewModel: Failed to update avatar: $e');
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void updateUser(User newUser) {
    _user = newUser;
    notifyListeners();
  }
}
