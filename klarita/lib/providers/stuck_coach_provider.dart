import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class StuckCoachProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    // Add user message immediately
    _messages.add(ChatMessage(text: text, isUser: true));
    _isLoading = true;
    notifyListeners();

    try {
      // Get AI response
      final aiResponse = await ApiService.getStuckCoachResponse(text);
      _messages.add(ChatMessage(text: aiResponse, isUser: false));
    } catch (e) {
      _messages.add(ChatMessage(text: 'Sorry, I had trouble connecting. Please try again.', isUser: false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 