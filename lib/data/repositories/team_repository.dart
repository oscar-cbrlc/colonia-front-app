import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api/team_service.dart';
import '../../domain/models/team.dart';
import '../../domain/models/user.dart';

class TeamRepository extends ChangeNotifier {
  final TeamService _teamService;

  Team? _currentTeam;
  List<User> _teamMembers = [];
  bool _isLoading = false;

  Team? get currentTeam => _currentTeam;
  List<TeamMemberSummary> get teamMembers => _currentTeam?.members ?? [];
  bool get isLoading => _isLoading;

  TeamRepository(this._teamService);

  Future<void> fetchTeamDetails(int teamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _teamService.getById(teamId);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> teamJson;
        
        if (decoded is Map<String, dynamic>) {
          teamJson = decoded.containsKey('data') ? decoded['data'] : decoded;
        } else {
          throw Exception('Unexpected response format for team details: $decoded');
        }
        
        try {
          _currentTeam = Team.fromJson(teamJson);
          debugPrint('TeamRepository: Successfully loaded team: ${_currentTeam?.name}');
        } catch (parseError) {
          debugPrint('TeamRepository: JSON parsing failed for Team object: $parseError');
          debugPrint('JSON was: $teamJson');
          rethrow;
        }
      } else {
        throw Exception('Failed to fetch team details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('TeamRepository: Error fetching team details: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Team?> createTeam({
    required String name,
    required String description,
    required bool isPublic,
    required int color,
  }) async {
    try {
      final response = await _teamService.register(
        name: name,
        description: description,
        isPublic: isPublic,
        color: color,
      );

      if (response.statusCode == 201) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> teamJson = decoded is Map<String, dynamic> && decoded.containsKey('data') 
            ? decoded['data'] 
            : decoded;
            
        final team = Team.fromJson(teamJson);
        _currentTeam = team;
        notifyListeners();
        return team;
      }
    } catch (e) {
      debugPrint('Error creating team: $e');
    }
    return null;
  }

  Future<User?> joinTeam(int teamId) async {
    try {
      final response = await _teamService.joinTeam(teamId);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final userJson = body.containsKey('data') ? body['data'] : body;
        final user = User.fromJson(userJson);
        
        await fetchTeamDetails(teamId);
        return user;
      }
    } catch (e) {
      debugPrint('TeamRepository: Error joining team: $e');
    }
    return null;
  }

  Future<bool> updateTeam({
    required String name,
    required String description,
    required bool isPublic,
    required int color,
  }) async {
    try {
      final response = await _teamService.update(
        name: name,
        description: description,
        isPublic: isPublic,
        color: color,
      );
      if (response.statusCode == 200) {
        if (_currentTeam != null) {
          await fetchTeamDetails(_currentTeam!.id);
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating team: $e');
    }
    return false;
  }

  Future<bool> deleteTeam() async {
    try {
      final response = await _teamService.delete();
      if (response.statusCode == 204 || response.statusCode == 200) {
        clear();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting team: $e');
    }
    return false;
  }

  Future<User?> leaveTeam() async {
    try {
      final response = await _teamService.leaveTeam();
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final userJson = body.containsKey('data') ? body['data'] : body;
        final user = User.fromJson(userJson);
        
        clear();
        return user;
      }
    } catch (e) {
      debugPrint('TeamRepository: Error leaving team: $e');
    }
    return null;
  }

  Future<bool> kickMember(int userId) async {
    try {
      final response = await _teamService.kickMember(userId);
      if (response.statusCode == 200) {
        if (_currentTeam != null) {
          await fetchTeamDetails(_currentTeam!.id);
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error kicking member: $e');
    }
    return false;
  }

  Future<bool> promoteMember(int userId) async {
    try {
      final response = await _teamService.promoteMember(userId);
      if (response.statusCode == 200) {
        if (_currentTeam != null) {
          await fetchTeamDetails(_currentTeam!.id);
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error promoting member: $e');
    }
    return false;
  }

  Future<bool> demoteMember(int userId) async {
    try {
      final response = await _teamService.demoteMember(userId);
      if (response.statusCode == 200) {
        if (_currentTeam != null) {
          await fetchTeamDetails(_currentTeam!.id);
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error demoting member: $e');
    }
    return false;
  }

  Future<List<Team>> getAllTeams({int? limit}) async {
    try {
      final response = await _teamService.getAll(limit);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data;
        
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          data = decoded['data'] as List<dynamic>;
        } else {
          debugPrint('TeamRepository: Unexpected response format for all teams: $decoded');
          data = [];
        }
        
        return data.map((json) {
          try {
            return Team.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            debugPrint('TeamRepository: Error parsing team json: $e');
            debugPrint('JSON was: $json');
            return null;
          }
        }).whereType<Team>().toList();
      }
    } catch (e) {
      debugPrint('TeamRepository: Error fetching all teams: $e');
    }
    return [];
  }

  Future<List<Team>> searchTeams(String query) async {
    try {
      final response = await _teamService.searchByName(query);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data;
        
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          data = decoded['data'] as List<dynamic>;
        } else {
          data = [];
        }
        
        return data.map((json) => Team.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error searching teams: $e');
    }
    return [];
  }

  Future<Team?> getTeamById(int teamId) async {
    try {
      final response = await _teamService.getById(teamId).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> teamJson;
        
        if (decoded is Map<String, dynamic>) {
          teamJson = decoded.containsKey('data') ? decoded['data'] : decoded;
        } else {
          return null;
        }

        return Team.fromJson(teamJson);
      }
    } catch (e) {
      debugPrint('Error getting team by id: $e');
    }
    return null;
  }

  void clear() {
    _currentTeam = null;
    _teamMembers = [];
    notifyListeners();
  }
}
