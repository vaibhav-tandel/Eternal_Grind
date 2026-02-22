import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService; // Injected
  final FirestoreService _firestoreService = FirestoreService();

  AuthProvider(this._authService);

  // Get current user from Firebase Auth
  User? get currentUser => _authService.currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      _errorMessage = e.toString();
      // Simplify error message
      if (e is FirebaseAuthException) {
        _errorMessage = e.message;
      }
      notifyListeners();
      rethrow; 
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      UserCredential cred = await _authService.signUp(email, password);
      // Create user document immediately
      if (cred.user != null) {
        await _firestoreService.createUser(cred.user!.uid, email);
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (e is FirebaseAuthException) {
         _errorMessage = e.message;
      }
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
