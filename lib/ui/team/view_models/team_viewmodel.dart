import 'dart:async';
import 'package:colonia_front_app/utils/LoadingState.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/team_request_repository.dart';
import '../../../data/repositories/team_chat_repository.dart';
import '../../../domain/models/team.dart';
import '../../../domain/models/user.dart';
import '../../../domain/models/team_request.dart';
import '../../../domain/models/team_chat_message.dart';


class TeamViewModel extends ChangeNotifier {
  final TeamRepository _teamRepository;
  final AuthRepository _authRepository;
  final TeamRequestRepository _teamRequestRepository;
  final TeamChatRepository _teamChatRepository;
  LoadingState _state = LoadingState.idle;
  
  Future<void>? _initOperation;

  bool get isLoading => _state == LoadingState.loading;

  TeamViewModel(
    this._teamRepository,
    this._authRepository,
    this._teamRequestRepository,
    this._teamChatRepository,
  ) {
    _authRepository.addListener(_onAuthChanged);
    _teamRepository.addListener(_onRepoChanged);
    _teamRequestRepository.addListener(_onRepoChanged);
    _teamChatRepository.addListener(_onRepoChanged);
    _init();
  }

  Team? get currentTeam => _teamRepository.currentTeam;
  User? get currentUser => _authRepository.currentUser;
  List<TeamRequest> get userMadeRequests => _teamRequestRepository.userMadeRequests;
  List<TeamRequest> get teamReceivedRequests => _teamRequestRepository.teamReceivedRequests;

  // Chat
  List<TeamChatMessage> get chatMessages => _teamChatRepository.messagesReversed;
  bool get isChatLoading => _teamChatRepository.isLoading;

  Future<void> fetchChatMessages() => _teamChatRepository.fetchMessages();
  Future<bool> sendChatMessage(String message) => _teamChatRepository.sendMessage(message);
  Future<bool> deleteChatMessage(int id) => _teamChatRepository.deleteMessage(id);

  List<TeamMemberSummary> get teamMembers {
    final members = List<TeamMemberSummary>.from(_teamRepository.teamMembers);
    final user = currentUser;
    if (user != null && user.hasTeam && currentTeam != null && user.team?.id == currentTeam!.id) {
      if (!members.any((m) => m.userId == user.id)) {
        members.add(TeamMemberSummary(
          userId: user.id,
          userName: user.username,
          userThumbnail: user.avatar?.thumbnailUrl ?? "",
          role: user.team?.role ?? "member",
        ));
      }
    }
    return members;
  }

  void _onAuthChanged() {
    debugPrint('TeamViewModel: Auth changed, re-initializing...');
    _init();
  }

  void _onRepoChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _authRepository.removeListener(_onAuthChanged);
    _teamRepository.removeListener(_onRepoChanged);
    _teamRequestRepository.removeListener(_onRepoChanged);
    _teamChatRepository.removeListener(_onRepoChanged);
    super.dispose();
  }

  Future<void> _init() async {
    if (_initOperation != null) {
      debugPrint('TeamViewModel: _init already in progress, awaiting...');
      return _initOperation;
    }
    
    _initOperation = _doInit();
    try {
      await _initOperation;
    } finally {
      _initOperation = null;
    }
  }

  Future<void> _doInit() async {
    final user = _authRepository.currentUser;
    debugPrint('TeamViewModel: _doInit() - User: ${user?.username}, hasTeam: ${user?.hasTeam}, TeamID: ${user?.team?.id}');

    unawaited(_teamRequestRepository.fetchUserMadeRequests());

    if (user != null && user.hasTeam) {
      _state = LoadingState.loading;
      notifyListeners();
      try {
        debugPrint('TeamViewModel: Fetching details for team ${user.team!.id}');
        await _teamRepository.fetchTeamDetails(user.team!.id).timeout(const Duration(seconds: 10));

        if (user.canModerateTeam) {
          unawaited(_teamRequestRepository.fetchTeamReceivedRequests());
        }

        _state = LoadingState.success;
      } catch (e) {
        debugPrint('TeamViewModel: _doInit() error fetching team details: $e');
        _state = LoadingState.error;
      }
    } else {
      debugPrint('TeamViewModel: No team detected for user, clearing repository.');
      _teamRepository.clear();
      _teamRequestRepository.clear();
      _teamChatRepository.clear();
      _state = LoadingState.idle;
    }
    notifyListeners();
  }


  Future<bool> createTeam({
    required String name,
    required String description,
    required bool isPublic,
    required int color,
  }) async {
    _state = LoadingState.loading;
    notifyListeners();

    try {
      final team = await _teamRepository.createTeam(
        name: name,
        description: description,
        isPublic: isPublic,
        color: color,
      ).timeout(const Duration(seconds: 15));

      if (team != null) {
        await _authRepository.fetchCurrentUser();
        return true;
      }
      _state = LoadingState.error;
      return false;
    } catch (e) {
      debugPrint('TeamViewModel: createTeam error: $e');
      _state = LoadingState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> updateTeam({
    required String name,
    required String description,
    required bool isPublic,
    required int color,
  }) async {
    _state = LoadingState.loading;
    notifyListeners();

    try {
      final success = await _teamRepository.updateTeam(
        name: name,
        description: description,
        isPublic: isPublic,
        color: color,
      ).timeout(const Duration(seconds: 15));

      if (success) {
        _state = LoadingState.success;
        return true;
      }
      _state = LoadingState.error;
      return false;
    } catch (e) {
      debugPrint('TeamViewModel: updateTeam error: $e');
      _state = LoadingState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> deleteTeam() async {
    _state = LoadingState.loading;
    notifyListeners();

    try {
      final success = await _teamRepository.deleteTeam().timeout(const Duration(seconds: 15));
      if (success) {
        await _authRepository.fetchCurrentUser();
        return true;
      }
      _state = LoadingState.error;
      return false;
    } catch (e) {
      debugPrint('TeamViewModel: deleteTeam error: $e');
      _state = LoadingState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> joinTeam(int teamId) async {
    _state = LoadingState.loading;
    notifyListeners();

    try {
      debugPrint('TeamViewModel: joining team $teamId...');
      final updatedUser = await _teamRepository.joinTeam(teamId).timeout(const Duration(seconds: 15));
      
      if (updatedUser != null) {
        debugPrint('TeamViewModel: Join success, updating local user state...');
        _authRepository.updateCurrentUser(updatedUser);
        await _init();
        return true;
      }
      _state = LoadingState.error;
      return false;
    } catch (e) {
      debugPrint('TeamViewModel: Error joining team: $e');
      _state = LoadingState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> leaveTeam() async {
    _state = LoadingState.loading;
    notifyListeners();

    try {
      debugPrint('TeamViewModel: leaving team...');
      final updatedUser = await _teamRepository.leaveTeam().timeout(const Duration(seconds: 15));
      
      if (updatedUser != null) {
        debugPrint('TeamViewModel: Leave success, updating local user state...');
        _authRepository.updateCurrentUser(updatedUser);
        await _init();
        return true;
      }
      _state = LoadingState.error;
      return false;
    } catch (e) {
      debugPrint('TeamViewModel: Error leaving team: $e');
      _state = LoadingState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> kickMember(int userId) async {
    try {
      return await _teamRepository.kickMember(userId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> promoteMember(int userId) async {
    try {
      return await _teamRepository.promoteMember(userId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> demoteMember(int userId) async {
    try {
      return await _teamRepository.demoteMember(userId);
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestJoin(int teamId) async {
    return await _teamRequestRepository.requestJoin(teamId);
  }

  Future<bool> acceptRequest(int userId) async {
    final success = await _teamRequestRepository.accept(userId);
    if (success) {
      if (currentTeam != null) {
        await _teamRepository.fetchTeamDetails(currentTeam!.id);
      }
    }
    return success;
  }

  Future<bool> rejectRequest(int userId) async {
    return await _teamRequestRepository.reject(userId);
  }

  Future<bool> cancelRequest(int teamId) async {
    return await _teamRequestRepository.cancel(teamId);
  }

  Future<List<Team>> searchTeams(String query) async {
    return await _teamRepository.searchTeams(query);
  }

  Future<List<Team>> loadAllTeams() async {
    return await _teamRepository.getAllTeams();
  }

  Future<Team?> getTeamById(int teamId) async {
    return await _teamRepository.getTeamById(teamId);
  }

  Future<void> refresh() async {
    _state = LoadingState.loading;
    notifyListeners();
    try {
      await _authRepository.fetchCurrentUser();
      await _init();
    } catch (e) {
      _state = LoadingState.error;
      notifyListeners();
    }
  }
}
