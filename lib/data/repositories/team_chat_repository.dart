import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/data/services/api/team_chat_service.dart';
import 'package:colonia_front_app/domain/models/team_chat_message.dart';

class TeamChatRepository extends ChangeNotifier {
  final TeamChatService _teamChatService;

  List<TeamChatMessage> _messages = [];
  bool _isLoading = false;

  //List<TeamChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  List<TeamChatMessage> get messagesReversed => _messages.reversed.toList();

  TeamChatRepository(this._teamChatService);

  Future<void> fetchMessages() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _teamChatService.getAll();
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? []);
        _messages = data.map((json) => TeamChatMessage.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('TeamChatRepository: Error fetching messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String message) async {
    try {
      final response = await _teamChatService.send(message);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchMessages();
        return true;
      }
    } catch (e) {
      debugPrint('TeamChatRepository: Error sending message: $e');
    }
    return false;
  }

  Future<bool> deleteMessage(int id) async {
    try {
      final response = await _teamChatService.delete(id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _messages.removeWhere((m) => m.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('TeamChatRepository: Error deleting message: $e');
    }
    return false;
  }

  void clear() {
    _messages = [];
    notifyListeners();
  }
}
