import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:colonia_front_app/data/services/api/notification_api_service.dart';
import 'package:colonia_front_app/domain/models/notification.dart';

class NotificationRepository extends ChangeNotifier {
  final NotificationApiService _apiService;

  List<Notification> _notifications = [];
  bool _isLoading = false;

  NotificationRepository(this._apiService);

  List<Notification> get notifications => _notifications;

  List<Notification> get globalNotifications =>
      _notifications.where((n) => n.isGlobal).toList();

  List<Notification> get personalNotifications =>
      _notifications.where((n) => n.isPersonal).toList();

  bool get isLoading => _isLoading;

  Future<List<Notification>> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getMyNotifications();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((json) => Notification.fromJson(json)).toList();
      } else {
        debugPrint('NotificationRepository: Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e, stack) {
      debugPrint('NotificationRepository: Error fetching notifications: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _notifications;
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await _apiService.deleteNotification(notificationId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
        return true;
      } else {
        debugPrint('NotificationRepository: Failed to delete notification $notificationId: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      debugPrint('NotificationRepository: Error deleting notification $notificationId: $e\n$stack');
      return false;
    }
  }
}
