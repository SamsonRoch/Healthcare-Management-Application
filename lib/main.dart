import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:patient_management_app/config/routes/routes.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/services/database_service.dart';
import 'package:patient_management_app/services/navigation_service.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await locator<DatabaseService>().resetDatabase();
  // Initialize Firebase only once
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await setupServiceLocator();
  // Initialize the auth service
  final authService = locator<AuthService>();
  
  // The AuthService._onAuthStateChanged method will handle navigation
  // after the user data is properly loaded from Firestore

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locator<AuthService>()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Management',
      theme: AppTheme.lightTheme,
      initialRoute: Routes.splash,
      onGenerateRoute: Routes.getRoutes(context),
      navigatorKey: locator<NavigationService>().navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}