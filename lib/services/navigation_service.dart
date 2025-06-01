// Corrected NavigationService implementation
import 'package:flutter/material.dart';
import 'package:patient_management_app/config/routes/routes.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Fixed currentRoute getter
  String get currentRoute {
    final context = navigatorKey.currentState?.context;
    if (context == null) return Routes.login;
    
    final modalRoute = ModalRoute.of(context);
    return modalRoute?.settings.name ?? Routes.login;
  }

  Future<void> pushReplacementNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  Future<void> pushNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  void pop() => navigatorKey.currentState!.pop();

  void popUntil(String routeName) {
    navigatorKey.currentState!.popUntil((route) {
      return route.settings.name == routeName;
    });
  }
}