import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class ChallengeService {
  final ApiClient _apiClient;

  ChallengeService(this._apiClient);

  Future<http.Response> listChallenges() async {
    return await _apiClient.get('/challenge/');
  }

  Future<http.Response> getChallengeById(int challengeId) async {
    return await _apiClient.get('/challenge/$challengeId');
  }

  Future<http.Response> listActiveChallenges() async {
    return await _apiClient.get('/activeChallenge/');
  }

  Future<http.Response> getActiveChallengeById(int activeChallengeId) async {
    return await _apiClient.get(
      '/activeChallenge/$activeChallengeId',
      queryParameters: {
        'active_challenge_id': activeChallengeId.toString(),
      },
    );
  }

  Future<http.Response> getMyChallengeProgress() async {
    return await _apiClient.get('/activeChallenge/mine/progress');
  }
}
