import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'widgets/auth_wrapper.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    if (kIsWeb) {
      // For web, try to load from assets, but don't fail if not found
      await dotenv.load(fileName: ".env", isOptional: true);
      debugPrint("Environment variables loaded for web");
    } else {
      // For mobile/desktop, require the .env file
      await dotenv.load(fileName: ".env");
      debugPrint("Environment variables loaded for mobile/desktop");
    }
    
    // Debug: Print environment variables (remove in production)
    debugPrint("Firebase Project ID: ${dotenv.env['FIREBASE_PROJECT_ID']}");
    debugPrint("Firebase Web API Key: ${dotenv.env['FIREBASE_WEB_API_KEY']?.substring(0, 10)}...");
  } catch (e) {
    debugPrint("Environment loading error: $e");
    // Continue without environment variables for web demo
  }
  
  // Initialize local storage first
  try {
    await LocalStorageService().init();
    debugPrint("Local storage initialized");
  } catch (e) {
    debugPrint("Local storage init error: $e");
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase init error: $e");
    // For web demo, continue without Firebase
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if Firebase is initialized
    bool firebaseInitialized = false;
    try {
      Firebase.initializeApp();
      firebaseInitialized = true;
    } catch (e) {
      debugPrint("Firebase not available: $e");
    }

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            Provider.of<AuthService>(context, listen: false),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Eternal Grind',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: firebaseInitialized ? const AuthWrapper() : const FirebaseErrorScreen(),
            routes: {
               '/login': (context) => const LoginScreen(),
               '/home': (context) => const HomeScreen(),
               '/calendar': (context) => const CalendarScreen(),
            },
          );
        },
      ),
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  const FirebaseErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Firebase Not Available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your environment configuration',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Restart the app
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      ),
    );
  }
}

