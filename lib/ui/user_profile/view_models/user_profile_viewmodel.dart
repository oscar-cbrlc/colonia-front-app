import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/avatar_item_repository.dart';
import 'package:colonia_front_app/domain/models/achievement.dart';
import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/domain/models/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    loadDownloadedItemModels();
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

  bool hasLockedItemSelected(Iterable<int?> itemIds) {
    for (final id in itemIds) {
      if (id != null && !isItemUnlocked(id)) {
        return true;
      }
    }
    return false;
  }

  bool areAllSelectedItemsUnlocked(Iterable<int?> itemIds) {
    return !hasLockedItemSelected(itemIds);
  }

  List<Achievement> get achievements => _user.achievements;
  List<Achievement> get unlockedAchievements => _user.unlockedAchievements;
  int get unlockedCount => unlockedAchievements.length;
  int get totalAchievements => achievements.length;

  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalFormat = NumberFormat('#,##0.0', 'en_US');

  int get level => _user.stats?.level ?? 0;
  int get xp => _user.stats?.xp ?? 0;
  int get xpForNextLevel => _user.xpForNextLevel ?? 0;

  String get formattedLevel => _numberFormat.format(level);
  String get formattedXp => _numberFormat.format(xp);
  String get formattedXpForNextLevel => _numberFormat.format(xpForNextLevel);

  String get formattedDistance {
    final distInKm = ((_user.stats?.totalDistance ?? 0.0) / 1000.0);
    return '${_decimalFormat.format(distInKm)} km';
  }

  String get formattedTime {
    final totalSeconds = (_user.stats?.totalTime ?? 0.0).toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return hours > 0
        ? '${_numberFormat.format(hours)}h ${minutes}m'
        : '${minutes}m';
  }

  String get formattedAttack {
    final attack = (_user.stats?.totalAttack ?? 0.0).toInt();
    return _numberFormat.format(attack);
  }

  String get formattedDefense {
    final defense = (_user.stats?.totalDefense ?? 0.0).toInt();
    return _numberFormat.format(defense);
  }

  String get formattedTerritoriesCaptured {
    final count = _user.stats?.territoriesCaptured ?? 0;
    return _numberFormat.format(count);
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

    await loadDownloadedItemModels();
    
    _isDownloadingModels = false;
    notifyListeners();
  }

  Future<bool> updateAccountInfo({required String newUsername}) async {
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

  Future<bool> updateUserThumbnail(String thumbnailUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _avatarItemRepository.updateAvatar(thumbnailUrl: thumbnailUrl);
      final updatedUser = await AuthRepository.instance.fetchCurrentUser();
      _user = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UserProfileViewModel: Failed to update user thumbnail: $e');
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

      await saveMergedModelLocally(baseColor: updatedAvatar.color != null ? Color(updatedAvatar.color!) : null);

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

  Future<void> saveMergedModelLocally({Color? baseColor}) async {
    final paths = await _avatarItemRepository.getEquippedModelPaths();
    final color = baseColor ?? (_user.avatar?.color != null ? Color(_user.avatar!.color!) : null);
    await _avatarItemRepository.saveMergedModelLocally(paths, baseColor: color);
  }
}