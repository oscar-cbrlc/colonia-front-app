import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class TerritoryService {
  final ApiClient _apiClient;

  final _route = '/territory';

  TerritoryService(this._apiClient);

  Future<http.Response> getTerritoryById(String id) async {
    return await _apiClient.get('$_route/$id');
  }

  Future<http.Response> getAllTerritories() async {
    return await _apiClient.get(_route);
  }

  Future<http.Response> applyPoints({
    required String trainingUuid,
    required double totalDistance,
    required int totalTime,
    required String timestamp,
    required int secondsWalk,
    required int secondsRun,
    required int secondsBike,
    required double distanceWalk,
    required double distanceRun,
    required double distanceBike,
    required List<Map<String, dynamic>> territories,
    int? boostId,
  }) async {
    return await _apiClient.post('/userTraining/', body: {
      'training_uuid': trainingUuid,
      'training_distance': totalDistance.round(),
      'training_time': totalTime,
      'territories': territories,
      'started_at': timestamp,
      'boost_id': boostId,
      'seconds_walk': secondsWalk,
      'seconds_run': secondsRun,
      'seconds_bike': secondsBike,
      'meters_walk': distanceWalk.round(),
      'meters_run': distanceRun.round(),
      'meters_bike': distanceBike.round(),
    });
  }
}
