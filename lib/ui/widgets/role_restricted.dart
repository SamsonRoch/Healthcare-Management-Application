// import 'package:flutter/material.dart';
// import 'package:patient_management_app/data/models/user_model.dart';
// import 'package:patient_management_app/services/auth_service.dart';
// import 'package:provider/provider.dart';

// /// Restricts widget visibility based on user roles
// class RoleRestricted extends StatelessWidget {
//   final Widget child;
//   final UserRole requiredRole;
//   final Widget? fallback;

//   const RoleRestricted({
//     super.key,
//     required this.child,
//     required this.requiredRole,
//     this.fallback,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);
    
//     return authService.hasRoleAccess(requiredRole)
//         ? child
//         : fallback ?? const SizedBox.shrink();
//   }
// }

// /// Documentation for developers
// /// Usage example:
// /// RoleRestricted(
// ///   requiredRole: UserRole.admin,
// ///   child: EditButton(),
// ///   fallback: AccessDeniedMessage(),
// /// )
import 'package:flutter/material.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class RoleRestricted extends StatelessWidget {
  final Widget child;
  final UserRole requiredRole;
  final Widget? fallback;

  const RoleRestricted({
    super.key,
    required this.child,
    required this.requiredRole,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return authService.hasRoleAccess(requiredRole)
        ? child
        : fallback ?? const SizedBox.shrink();
  }
}