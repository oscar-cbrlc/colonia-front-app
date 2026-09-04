import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class TeamChatService {
  final ApiClient _apiClient;

  TeamChatService(this._apiClient);

  final String _route = '/teamChat';

  Future<http.Response> send(String message) async {
    return await _apiClient.post('$_route/', body: {
      "chat_message": message,
    });
  }

  Future<http.Response> getAll() async {
    return await _apiClient.get('$_route/');
  }

  Future<http.Response> delete(int id) async {
    return await _apiClient.delete('$_route/?message_id=$id');
  }
}