import 'package:http/http.dart' as http;
import 'api_client.dart';


class TeamService {
  final ApiClient _apiClient;

  TeamService(this._apiClient);

  final String _route = '/teams';

  Future<http.Response> register({
    required String name,
    required String description,
    required bool isPublic,
    required int color,
  }) async {
    return await _apiClient.post('$_route/', body: {
      'team_name': name,
      'team_description': description,
      'is_public': isPublic,
      'team_color': color,
    });
  }

  Future<http.Response> getAll(int? limit) async {
    final queryParams = limit != null ? {'limit': limit.toString()} : null;
    return await _apiClient.get('$_route/', queryParameters: queryParams);
  }

  Future<http.Response> searchByName(String search, {int limit = 100}) async {
    return await _apiClient.get('$_route/search-name', queryParameters: {
      'team_name': search,
      'limit': limit.toString(),
    });
  }

  Future<http.Response> delete() async {
    return await _apiClient.delete('$_route/mine');
  }

  Future<http.Response> getById(int id) async {
    return await _apiClient.get('$_route/$id');
  }

  Future<http.Response> update({
    required String name,
    required String description,
    required bool isPublic,
    required int color,
  }) async {
    return await _apiClient.patch('$_route/', body: {
      'team_name': name,
      'team_description': description,
      'is_public': isPublic,
      'team_color': color,
    });
  }



  Future<http.Response> getTeamMembers(int teamId) async {
    return await _apiClient.get('$_route/$teamId/members');
  }

  Future<http.Response> joinTeam(int teamId) async {
    return await _apiClient.patch('$_route/$teamId/me/join');
  }

  Future<http.Response> leaveTeam() async {
    return await _apiClient.patch('$_route/me/leave');
  }

  Future<http.Response> kickMember(int userId) async {
    return await _apiClient.patch('$_route/members/$userId/kick');
  }

  Future<http.Response> promoteMember(int userId) async {
    return await _apiClient.patch('$_route/members/$userId/promote');
  }

  Future<http.Response> demoteMember(int userId) async {
    return await _apiClient.patch('$_route/members/$userId/demote');
  }
}
