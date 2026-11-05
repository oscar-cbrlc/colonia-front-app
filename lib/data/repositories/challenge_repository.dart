import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:colonia_front_app/data/services/api/challenge_service.dart';
import 'package:colonia_front_app/domain/models/active_challenge.dart';
import 'package:colonia_front_app/domain/models/started_challenge.dart';

class ChallengeRepository extends ChangeNotifier {
  final ChallengeService _challengeService;

  List<ActiveChallenge> _activeChallenges = [];
  List<StartedChallenge> _myStartedChallenges = [];
  List<ActiveChallenge> _events = [];
  List<StartedChallenge> _myStartedEvents = [];
  bool _isLoading = false;

  List<ActiveChallenge> get activeChallenges => _activeChallenges;
  List<StartedChallenge> get myStartedChallenges => _myStartedChallenges;
  List<StartedChallenge> get myStartedEvents => _myStartedEvents;
  List<ActiveChallenge> get events => _events;
  bool get isLoading => _isLoading;

  ChallengeRepository(this._challengeService);

  Future<List<ActiveChallenge>> fetchActiveChallenges() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _challengeService.listActiveChallenges();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _activeChallenges = data
            .where((json) => json != null && json is Map<String, dynamic>)
            .map((json) => ActiveChallenge.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _activeChallenges;
      }
    } catch (e, stack) {
      debugPrint('ChallengeRepository: Error fetching active challenges: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _activeChallenges;
  }

  Future<List<ActiveChallenge>> fetchEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _challengeService.listEvents();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _events = data
            .where((json) => json != null && json is Map<String, dynamic>)
            .map((json) => ActiveChallenge.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _events;
      }
    } catch (e, stack) {
      debugPrint('ChallengeRepository: Error fetching events: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _events;
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _challengeService.createEvent(eventData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final newEvent = ActiveChallenge.fromJson(data);
        _events.insert(0, newEvent);
        notifyListeners();
        return true;
      } else {
        debugPrint('ChallengeRepository: Failed to create event: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stack) {
      debugPrint('ChallengeRepository: Error creating event: $e\n$stack');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<StartedChallenge>> fetchMyChallengeProgress() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _challengeService.getMyChallengeProgress();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _myStartedChallenges = data
            .where((json) => json != null && json is Map<String, dynamic>)
            .map((json) => StartedChallenge.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _myStartedChallenges;
      }
    } catch (e, stack) {
      debugPrint('ChallengeRepository: Error fetching challenge progress: $e\n$stack');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _myStartedChallenges;
  }

  Future<List<StartedChallenge>> fetchMyEventProgress() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _challengeService.getMyEventProgress();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _myStartedEvents = data
            .where((json) => json != null && json is Map<String, dynamic>)
            .map((json) => StartedChallenge.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _myStartedEvents;
      }
    } catch (e, stack) {
      debugPrint('ChallengeRepository: Error fetching event progress: $e\n$stack');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _myStartedEvents;
  }

  void clearCache() {
    _activeChallenges.clear();
    _myStartedChallenges.clear();
    _events.clear();
    notifyListeners();
  }
}
