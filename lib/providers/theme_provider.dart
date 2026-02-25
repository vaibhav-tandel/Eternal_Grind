import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class ThemeProvider with ChangeNotifier {
  final LocalStorageService _localStorageService = LocalStorageService();
  final FirestoreService _firestoreService = FirestoreService();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    bool? isDark = _localStorageService.isDarkMode;
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    await _localStorageService.setThemeMode(isDark);
    
    // Sync with Firestore if logged in
    final uid = _localStorageService.uid;
    if (uid != null) {
      await _firestoreService.updateTheme(uid, isDark);
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    
    // Save to local storage
    final isDark = mode == ThemeMode.dark;
    _localStorageService.setThemeMode(isDark);
    
    // Sync with Firestore if logged in
    final uid = _localStorageService.uid;
    if (uid != null) {
      _firestoreService.updateTheme(uid, isDark);
    }
  }
}
