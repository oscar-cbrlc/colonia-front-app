import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api/team_request_service.dart';
import '../../domain/models/team_request.dart';

class TeamRequestRepository extends ChangeNotifier {
  final TeamRequestService _teamRequestService;

  List<TeamRequest> _userMadeRequests = [];
  List<TeamRequest> _teamReceivedRequests = [];
  bool _isLoading = false;

  List<TeamRequest> get userMadeRequests => _userMadeRequests;
  List<TeamRequest> get teamReceivedRequests => _teamReceivedRequests;
  bool get isLoading => _isLoading;

  TeamRequestRepository(this._teamRequestService);

  Future<void> fetchUserMadeRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _teamRequestService.getAllUserMade();
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? []);
        _userMadeRequests = data.map((json) => TeamRequest.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('TeamRequestRepository: Error fetching user made requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeamReceivedRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _teamRequestService.getAllFromUserTeam();
      debugPrint('TeamRequestRepository: Received requests response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? []);
        
        _teamReceivedRequests = data.map((json) {
          try {
            return TeamRequest.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            debugPrint('TeamRequestRepository: Error parsing TeamRequest JSON: $e');
            debugPrint('JSON was: $json');
            return null;
          }
        }).whereType<TeamRequest>().toList();
        
        debugPrint('TeamRequestRepository: Parsed ${_teamReceivedRequests.length} received requests');
      }
    } catch (e) {
      debugPrint('TeamRequestRepository: Error fetching team received requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestJoin(int teamId) async {
    try {
      final response = await _teamRequestService.requestJoin(teamId);
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchUserMadeRequests();
        return true;
      }
    } catch (e) {
      debugPrint('TeamRequestRepository: Error requesting join: $e');
    }
    return false;
  }

  Future<bool> accept(int userId) async {
    try {
      final response = await _teamRequestService.accept(userId);
      if (response.statusCode == 200) {
        _teamReceivedRequests.removeWhere((r) => r.user?.id == userId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('TeamRequestRepository: Error accepting request: $e');
    }
    return false;
  }

  Future<bool> reject(int userId) async {
    try {
      final response = await _teamRequestService.reject(userId);
      if (response.statusCode == 200) {
        _teamReceivedRequests.removeWhere((r) => r.user?.id == userId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('TeamRequestRepository: Error rejecting request: $e');
    }
    return false;
  }

  Future<bool> cancel(int teamId) async {
    try {
      final response = await _teamRequestService.cancel(teamId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _userMadeRequests.removeWhere((r) => r.team?.id == teamId);
        notifyListeners();
        await fetchUserMadeRequests();
        return true;
      }
    } catch (e) {
      debugPrint('TeamRequestRepository: Error cancelling request: $e');
    }
    return false;
  }

  void clear() {
    _userMadeRequests = [];
    _teamReceivedRequests = [];
    notifyListeners();
  }
}
