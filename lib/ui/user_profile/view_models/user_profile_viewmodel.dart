import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/domain/models/achievement.dart';
import 'package:colonia_front_app/domain/models/user.dart';
import 'package:flutter/foundation.dart';

class UserProfileViewModel extends ChangeNotifier {
  User _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileViewModel(this._user);

  User get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Achievement> get achievements => _user.achievements;
  List<Achievement> get unlockedAchievements => _user.unlockedAchievements;
  int get unlockedCount => unlockedAchievements.length;
  int get totalAchievements => achievements.length;

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
