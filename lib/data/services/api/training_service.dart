import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

// TODO(training): check with endpoints
class TrainingService {
  final ApiClient _apiClient;

  TrainingService(this._apiClient);

  Future<http.Response> getTrainingById(int id) async {
    return await _apiClient.get('/trainings/$id');
  }

  Future<http.Response> getAllTrainings() async {
    return await _apiClient.get('/trainings');
  }
}