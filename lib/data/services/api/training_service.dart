import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class TrainingService {
  final ApiClient _apiClient;

  TrainingService(this._apiClient);

  Future<http.Response> getTrainingById(int id) async {
    return await _apiClient.get('/trainings/$id');
  }

  Future<http.Response> getAllTrainings() async {
    return await _apiClient.get('/trainings');
  }

  Future<http.Response> processUserTraining(Map<String, dynamic> body) async {
    return await _apiClient.post('/userTraining/', body: body);
  }

  Future<http.Response> getAllMyUserTrainings() async {
    return await _apiClient.get('/userTraining/mine');
  }

  Future<http.Response> getUserTraining(int userId, String trainingUuid) async {
    final cleanUuid = trainingUuid.startsWith('/') ? trainingUuid : '/$trainingUuid';
    return await _apiClient.get('/userTraining/users/$userId/userTraining$cleanUuid');
  }
}
