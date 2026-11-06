import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class NotificationApiService {
  final ApiClient _apiClient;

  NotificationApiService(this._apiClient);

  Future<http.Response> getMyNotifications() async {
    return await _apiClient.get('/notification/mine');
  }

  Future<http.Response> deleteNotification(int notificationId) async {
    return await _apiClient.delete('/notification/$notificationId');
  }
}
