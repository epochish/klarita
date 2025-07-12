import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _accessToken;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get accessToken => _accessToken;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final token = await _storage.read(key: 'access_token');
    final email = await _storage.read(key: 'user_email');
    
    if (token != null) {
      _isAuthenticated = true;
      _accessToken = token;
      _userEmail = email;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);
      final accessToken = response['access_token'];

      if (accessToken != null) {
        await _storage.write(key: 'access_token', value: accessToken);
        await _storage.write(key: 'user_email', value: email);
        
        _isAuthenticated = true;
        _accessToken = accessToken;
        _userEmail = email;
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      await ApiService.register(email, password);
      return await login(email, password);
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'user_email');
    
    _isAuthenticated = false;
    _accessToken = null;
    _userEmail = null;
    
    notifyListeners();
  }
} 