import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:patient_management_app/config/routes/routes.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Simulate a delay for splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    // Check authentication status
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Navigate to the appropriate screen
    if (!mounted) return;
    
    if (authService.isAuthenticated) {
      // Use the user's role to determine which dashboard to show
      if (authService.currentUser != null) {
        // Let the AuthService handle the navigation based on user role
        authService.handleAuthRedirect(authService.currentUser);
      }
    } else {
      // Use named route navigation instead of MaterialPageRoute
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorDark,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Icon(
              Icons.local_hospital_rounded,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            // App name
            Text(
              'Patient Management',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Healthcare at your fingertips',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 50),
            // Loading indicator
            const SpinKitDoubleBounce(
              color: Colors.white,
              size: 50.0,
            ),
          ],
        ),
      ),
    );
  }
}