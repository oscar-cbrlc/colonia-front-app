import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:colonia_front_app/data/services/api/challenge_service.dart';
import 'package:colonia_front_app/domain/models/active_challenge.dart';
import 'package:colonia_front_app/domain/models/started_challenge.dart';

class ChallengeRepository extends ChangeNotifier {
  final ChallengeService _challengeService;

  List<ActiveChallenge> _activeChallenges = [];
  List<StartedChallenge> _myStartedChallenges = [];
  bool _isLoading = false;

  List<ActiveChallenge> get activeChallenges => _activeChallenges;
  List<StartedChallenge> get myStartedChallenges => _myStartedChallenges;
  bool get isLoading => _isLoading;

  ChallengeRepository(this._challengeService);

  Future<List<ActiveChallenge>> fetchActiveChallenges() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _challengeService.listActiveChallenges();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _activeChallenges = data.map((json) => ActiveChallenge.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
        return _activeChallenges;
      }
    } catch (e) {
      debugPrint('ChallengeRepository: Error fetching active challenges: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _activeChallenges;
  }

  Future<List<StartedChallenge>> fetchMyChallengeProgress() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _challengeService.getMyChallengeProgress();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _myStartedChallenges = data.map((json) => StartedChallenge.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
        return _myStartedChallenges;
      }
    } catch (e) {
      debugPrint('ChallengeRepository: Error fetching challenge progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _myStartedChallenges;
  }

  void clearCache() {
    _activeChallenges.clear();
    _myStartedChallenges.clear();
    notifyListeners();
  }
}
