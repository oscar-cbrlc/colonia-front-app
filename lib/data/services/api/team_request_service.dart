import 'package:http/http.dart' as http;
import 'api_client.dart';

class TeamRequestService {
  final ApiClient _apiClient;

  TeamRequestService(this._apiClient);

  final String _route = '/teamRequest';


  Future<http.Response> getAllUserMade() async {
    return await _apiClient.get('$_route/me');
  }

  Future<http.Response> getAllFromUserTeam() async {
    return await _apiClient.get('$_route/team/me');
  }

  Future<http.Response> requestJoin(int teamId) async {
    return await _apiClient.post('$_route/', body: {'team_id': teamId});
  }

  Future<http.Response> accept(int userId) async {
    return await _apiClient.patch('$_route/$userId/accept');
  }

  Future<http.Response> reject(int userId) async {
    return await _apiClient.patch('$_route/$userId/reject');
  }

  Future<http.Response> cancel(int teamId) async {
    return await _apiClient.delete('$_route/?team_id=$teamId');
  }

}