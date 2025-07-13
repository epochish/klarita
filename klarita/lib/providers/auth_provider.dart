import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _accessToken;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    _setLoading(true);
    _clearError();
    
    try {
      final response = await ApiService.login(email, password);
      final accessToken = response['access_token'];

      if (accessToken != null) {
        await _storage.write(key: 'access_token', value: accessToken);
        await _storage.write(key: 'user_email', value: email);
        
        _isAuthenticated = true;
        _accessToken = accessToken;
        _userEmail = email;
        
        _setLoading(false);
        notifyListeners();
        return true;
      }
      _setError('Invalid credentials');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      await ApiService.register(email, password);
      // If registration succeeds, automatically log in
      return await login(email, password);
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
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
    _isLoading = false;
    _error = null;
    
    notifyListeners();
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 