import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        debugPrint("AuthWrapper state: ${snapshot.connectionState}");
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          debugPrint("AuthWrapper error: ${snapshot.error}");
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Authentication Error'),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry by rebuilding
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          debugPrint("User authenticated: ${user != null}");
          if (user == null) {
            return const LoginScreen();
          } else {
            return const HomeScreen();
          }
        }
        
        // Fallback
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing...'),
              ],
            ),
          ),
        );
      },
    );
  }
}
