// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:patient_management_app/data/models/user_model.dart';
// import 'package:patient_management_app/data/repositories/auth_repository.dart';
// import 'package:patient_management_app/data/repositories/user_repository.dart';
// import 'package:patient_management_app/config/service_locator.dart';
// import 'package:patient_management_app/config/routes/routes.dart';
// import 'package:patient_management_app/services/navigation_service.dart';
// import 'package:patient_management_app/services/rbac_service.dart';
// import 'package:provider/provider.dart';

// class AuthService extends ChangeNotifier {
//   final NavigationService _navigationService;
//   final firebase_auth.FirebaseAuth _firebaseAuth;
//   //final NavigationService _navigationService = locator<NavigationService>();
//   //final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
//   final AuthRepository _authRepository = locator<AuthRepository>();
//   final UserRepository _userRepository = locator<UserRepository>();
//   final RBACService _rbacService = locator<RBACService>();
  
//   User? _currentUser;
//   bool _isLoading = false;
//   String? _error;
//   String? _lastHandledUserId;
  
//   // Getters
//   User? get currentUser => _currentUser;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   bool get isAuthenticated => _currentUser != null;
//   Stream<firebase_auth.User?> get currentUserStream => _authRepository.authStateChanges;
  
//   // Constructor
//   AuthService()
//     : _navigationService = locator<NavigationService>(),
//       _firebaseAuth = firebase_auth.FirebaseAuth.instance {
//     // Constructor body
//     _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
//   }
  
//   // Handle auth state changes
//   // Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
//   //   if (firebaseUser == null) {
//   //     _currentUser = null;
//   //     _lastHandledUserId = null;
//   //     notifyListeners();
//   //     // Navigate to login screen when user is logged out
//   //     _navigationService.replaceWith(Routes.login);
//   //     return;
//   //   }
//   Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
//   if (firebaseUser == null) {
//     _currentUser = null;
//     _lastHandledUserId = null;
//     _error = null;
//     notifyListeners();
//     if (_navigationService.currentRoute != Routes.login) {
//       _navigationService.pushReplacementNamed(Routes.login);
//     }
//     return;
//   }

//   if (_lastHandledUserId == firebaseUser.uid) {
//     return;
//   }
//   _lastHandledUserId = firebaseUser.uid;

//   try {
//     _isLoading = true;
//     notifyListeners();

//     final user = await _userRepository.getUserById(firebaseUser.uid);
//     if (user == null) {
//       final newUser = User(
//         id: firebaseUser.uid,
//         email: firebaseUser.email ?? '',
//         name: firebaseUser.displayName ?? 'User',
//         role: UserRole.patient,
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//       );
//       await _userRepository.createUser(newUser);
//       _currentUser = newUser;
//       _error = null;
//       _navigationService.pushReplacementNamed(Routes.patientDashboard);
//       return;
//     }

//     _currentUser = user;
//     _error = null;

//     // Role-based navigation
//     final targetRoute = user.role == UserRole.admin
//         ? Routes.adminDashboard
//         : Routes.patientDashboard;
//     if (_navigationService.currentRoute != targetRoute) {
//       _navigationService.pushReplacementNamed(targetRoute);
//     }
//   } catch (e) {
//     print('Error in auth state change: $e');
//     _error = e.toString();
//     _currentUser = null;
//     _navigationService.pushReplacementNamed(Routes.login);
//   } finally {
//     _isLoading = false;
//     notifyListeners();
//   }
// }

//   // Simplified navigation - all authenticated users go to patient dashboard
//   String _getRouteForUser(User user) {
//     return Routes.patientDashboard;
//   }

//   // Sign in with email and password
//   Future<bool> signInWithEmailAndPassword(String email, String password) async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();
      
//       await _firebaseAuth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
      
//       return true;
//     } catch (e) {
//       _error = _handleAuthError(e);
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
  
//   // Register with email and password
//   Future<User?> registerWithEmailAndPassword(
//     String email,
//     String password,
//     String name,
//     UserRole role,
//     {Map<String, dynamic>? additionalData}
//   ) async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();
      
//       // Create user in Firebase Auth
//       final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
      
//       if (userCredential.user != null) {
//         // Create user in Firestore
//         final userData = {
//           'id': userCredential.user!.uid,
//           'email': email,
//           'name': name,
//           'role': role,
//           'createdAt': DateTime.now(),
//           'updatedAt': DateTime.now(),
//           if (additionalData != null) ...additionalData,
//         };
        
//         final newUser = User.fromMap(userData);
        
//         await _userRepository.createUser(newUser);
//         return newUser;
//       }
      
//       return null;
//     } catch (e) {
//       _error = _handleAuthError(e);
//       return null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
  
//   // Sign out
//   Future<void> signOut() async {
//     try {
//       await _firebaseAuth.signOut();
//       _currentUser = null;
//       _error = null;
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       notifyListeners();
//     }
//   }
  
//   // Reset password
//   Future<bool> resetPassword(String email) async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();
      
//       await _firebaseAuth.sendPasswordResetEmail(email: email);
//       return true;
//     } catch (e) {
//       _error = _handleAuthError(e);
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
  
//   // Update user profile
//   // Future<bool> updateUserProfile({
//   //   required String name,
//   //   String? phoneNumber,
//   //   String? photoUrl,
//   // }) async {
//   //   if (_currentUser == null) return false;
    
//   //   try {
//   //     _isLoading = true;
//   //     notifyListeners();
      
//   //     final updatedUser = _currentUser!.copyWith(
//   //       name: name,
//   //       phoneNumber: phoneNumber,
//   //       photoUrl: photoUrl,
//   //       updatedAt: DateTime.now(),
//   //     );
      
//   //     await _userRepository.updateUser(updatedUser);
//   //     _currentUser = updatedUser;
//   //     return true;
//   //   } catch (e) {
//   //     _error = e.toString();
//   //     return false;
//   //   } finally {
//   //     _isLoading = false;
//   //     notifyListeners();
//   //   }
//   // }
//   // Add this method to your AuthService class

// Future<bool> updateUserProfile({
//   required String name,
//   String? phoneNumber,
//   String? address,
//   String? photoUrl,
//   String? dateOfBirth,
//   String? gender,
//   String? bloodType,
//   String? emergencyContact,
//   List<String>? allergies,
//   Map<String, dynamic>? medicalHistory,
  

// }) async {
//   if (_currentUser == null) return false;
  
//   try {
//     _isLoading = true;
//     notifyListeners();
    
//     final updatedUser = _currentUser!.copyWith(
//       name: name,
//       phoneNumber: phoneNumber,
//       address: address,
//       photoUrl: photoUrl,
//       updatedAt: DateTime.now(),
//       dateOfBirth: dateOfBirth,
//       gender: gender,
//       bloodType: bloodType,
//       // emergencyContact: emergencyContact,
//       // allergies: allergies,
//       // medicalHistory: medicalHistory,
//     );
    
//     await _userRepository.updateUser(updatedUser);
//     _currentUser = updatedUser;
//     return true;
//   } catch (e) {
//     _error = e.toString();
//     return false;
//   } finally {
//     _isLoading = false;
//     notifyListeners();
//   }
// }

//   // // Handle auth redirection based on user role
//   // void handleAuthRedirect(User? user) {
//   // if (user == null) {
//   //   _navigationService.replaceWith(Routes.login);
//   //   return;
//   // }

//   // String targetRoute;
//   // switch (user.role) {
//   //   case UserRole.admin:
//   //     targetRoute = Routes.adminDashboard;
//   //     break;
//   //   case UserRole.doctor:
//   //     targetRoute = Routes.doctorDashboard;
//   //     break;
//   //   case UserRole.patient:
//   //     targetRoute = Routes.patientDashboard;
//   //     break;
//   //   default:
//   //     targetRoute = Routes.login;
//   // }

//   // // Skip navigation if already on the target route
//   // if (_navigationService.currentRoute == targetRoute) {
//   //   return;
//   // }

//   // _navigationService.replaceWith(targetRoute);
//   // }
//   // Check if user has specific role access
//   bool hasRoleAccess(UserRole requiredRole) {
//     return _currentUser?.role == requiredRole;
//   }

//   // Role-restricted widget wrapper
//   static Widget roleRestricted({
//     required Widget child,
//     required UserRole requiredRole,
//     Widget? fallback,
//   }) {
//     return Consumer<AuthService>(
//       builder: (context, auth, _) {
//         if (auth.currentUser?.role == requiredRole) {
//           return child;
//         }
//         return fallback ?? const SizedBox.shrink();
//       },
//     );
//   }
  
//   // Handle Firebase Auth errors
//   String _handleAuthError(dynamic error) {
//     if (error is firebase_auth.FirebaseAuthException) {
//       switch (error.code) {
//         case 'user-not-found':
//           return 'No user found with this email.';
//         case 'wrong-password':
//           return 'Wrong password provided.';
//         case 'email-already-in-use':
//           return 'The email address is already in use.';
//         case 'weak-password':
//           return 'The password is too weak.';
//         case 'invalid-email':
//           return 'The email address is invalid.';
//         case 'user-disabled':
//           return 'This user account has been disabled.';
//         case 'too-many-requests':
//           return 'Too many requests. Try again later.';
//         case 'operation-not-allowed':
//           return 'Operation not allowed.';
//         case 'CONFIGURATION_NOT_FOUND':
//           return 'Firebase configuration error. Please contact support.';
//         default:
//           return 'An error occurred: ${error.message}';
//       }
//     }
//     return error.toString();
//   }
//   // Simplified redirection - all users go to patient dashboard
//   void handleAuthRedirect(User? user) {
//     if (user == null) {
//       _navigationService.pushReplacementNamed(Routes.login);
//       return;
//     }
    
//     // All authenticated users go to patient dashboard
//     _navigationService.pushReplacementNamed(Routes.patientDashboard);
//   }

// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:patient_management_app/config/routes/routes.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/data/repositories/auth_repository.dart';
import 'package:patient_management_app/data/repositories/user_repository.dart';
import 'package:patient_management_app/services/api_service.dart';
import 'package:patient_management_app/services/navigation_service.dart';
import 'package:provider/provider.dart';

class AuthService with ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final NavigationService _navigationService;
  User? _currentUser;
  String? _error;
  bool _isLoading = false;
  String? _lastHandledUserId;
  //final FirebaseFunctions _functions = FirebaseFunctions.instance;

  AuthService({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    NavigationService? navigationService,
  })  : _authRepository = authRepository ?? locator<AuthRepository>(),
        _userRepository = userRepository ?? locator<UserRepository>(),
        _navigationService = navigationService ?? locator<NavigationService>() {
    _authRepository.authStateChanges.listen(_onAuthStateChanged);
  }

  User? get currentUser => _currentUser;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  // Fixed recursive getter that was causing stack overflow
  List<User> _cachedUsers = [];
  List<User> get users => _cachedUsers;
  
  // Method to fetch and update users list
  Future<List<User>> fetchUsers() async {
    try {
      _cachedUsers = await _userRepository.getAllUsers();
      notifyListeners();
      return _cachedUsers;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Stream<firebase_auth.User?> get authStateChanges => _authRepository.authStateChanges;
  

  // Use the backend API service for staff account creation
  final ApiService _apiService = locator<ApiService>();
  
  
  Future<bool> registerStaffAccount({
  required String email,
  required String password,
  required String name,
  required UserRole role,
  String? phoneNumber,
  String? specialty,
  String? licenseNumber,
  Map<String, dynamic>? additionalData,
}) async {
  try {
    // Verify admin permissions
    if (_currentUser == null || 
        !_currentUser!.hasPermission(Permission.createStaff)) {
      _error = 'Permission denied';
      notifyListeners();
      return false;
    }

    // Use the backend API to create staff member
    final response = await _apiService.createStaffMember(
      email: email,
      password: password,
      name: name,
      role: role,
      phoneNumber: phoneNumber,
      specialty: specialty,
      licenseNumber: licenseNumber
    );

    if (response['success'] == true) {
      _error = null;
      return true;
    }
    
    _error = response['message'] ?? 'Failed to create staff member';
    return false;
  } catch (e) {
    _error = e.toString();
    return false;
  } finally {
    notifyListeners();
  }
}

Future<bool> registerWithEmailAndPassword(
  String email,
  String password,
  String name,
  UserRole role, {
  Map<String, dynamic>? additionalData,
  bool isStaffRegistration = false,
}) async {
  try {
    // Add staff registration check
    if (isStaffRegistration && 
        (_currentUser == null || !_currentUser!.hasPermission(Permission.createStaff))) {
      _error = 'Permission denied: Only admins can create staff accounts';
      notifyListeners();
      return false;
    }

    // Existing registration logic
    final userCredential = await _authRepository.signUpWithEmailAndPassword(email, password);
    final firebaseUser = userCredential.user;

    if (firebaseUser != null) {
      // Combine isActive handling into a single parameter
      final bool isActive = additionalData?['isActive'] as bool? ?? 
                           (isStaffRegistration ? false : true);

      final user = User(
        id: firebaseUser.uid,
        email: email,
        name: name,
        role: role,
        isActive: isActive,  // Single source of truth
        phoneNumber: additionalData?['phoneNumber'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('Creating user: ${user.toMap()}');
      await _userRepository.createUser(user);
      
      if (!isStaffRegistration) {
        await _authRepository.signInWithEmailAndPassword(email, password);
      }
      
      return true;
    }
    return false;
  } catch (e) {
    _error = _handleAuthError(e);
    return false;
  } finally {
    notifyListeners();
  }
}

  // Future<bool> signInWithEmailAndPassword(String email, String password) async {
  //   try {
  //     await _authRepository.signInWithEmailAndPassword(email, password);
  //     // Role-based navigation after successful login
  //   final targetRoute = _currentUser?.role == UserRole.admin
  //       ? Routes.adminDashboard
  //       : Routes.patientDashboard;
    
  //   if (_navigationService.currentRoute != targetRoute) {
  //     _navigationService.pushReplacementNamed(targetRoute);
  //   }
    
  //     _error = null;
  //     notifyListeners();
  //     return true;
  //   } catch (e) {
  //     _error = _handleAuthError(e);
  //     notifyListeners();
  //     return false;
  //   }
  // }
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
  try {
    final userCredential = await _authRepository.signInWithEmailAndPassword(email, password);
    final firebaseUser = userCredential.user;
    
    if (firebaseUser != null) {
      final user = await _userRepository.getUserById(firebaseUser.uid);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        handleAuthRedirect(user);
      }
    }
    return true;
  } catch (e) {
    _error = _handleAuthError(e);
    notifyListeners();
    return false;
  }
}

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _currentUser = null;
      _error = null;
      notifyListeners();
      _navigationService.pushReplacementNamed(Routes.login);
    } catch (e) {
      _error = _handleAuthError(e);
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? photoUrl,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    String? address,
    String? emergencyContact,
    List<String>? allergies,
    String? medicalHistory,
    String? prescriptions,
  }) async {
    try {
      if (_currentUser == null) {
        _error = 'No user logged in';
        notifyListeners();
        return false;
      }

      final updatedUser = _currentUser!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
        dateOfBirth: dateOfBirth != null
            ? DateTime.tryParse(dateOfBirth) ?? _currentUser!.dateOfBirth
            : _currentUser!.dateOfBirth,
        gender: gender,
        bloodType: bloodType,
        address: address,
        emergencyContact: emergencyContact,
        allergies: allergies,
        medicalHistory: medicalHistory,
        prescriptions: prescriptions,
        updatedAt: DateTime.now(),
      );

      await _userRepository.updateUser(updatedUser);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.id)
          .update(updatedUser.toMap());
      _currentUser = updatedUser;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        _error = 'User not found';
        notifyListeners();
        return false;
      }

      final updatedUser = user.copyWith(
        role: newRole,
        updatedAt: DateTime.now(),
      );

      await _userRepository.updateUser(updatedUser);
      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.resetPassword(email);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _handleAuthError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount(String userId) async {
    try {
      await _userRepository.deleteUser(userId);
      await _authRepository.deleteUser();
      _currentUser = null;
      _error = null;
      notifyListeners();
      _navigationService.pushReplacementNamed(Routes.login);
    } catch (e) {
      _error = _handleAuthError(e);
      notifyListeners();
      rethrow;
    }
  }

  bool hasRoleAccess(UserRole requiredRole) {
    return _currentUser?.role == requiredRole;
  }

Future<void> handleAuthRedirect(User? user) async {
  if (user == null) {
    _navigationService.pushReplacementNamed(Routes.login);
    return;
  }

  // Force fresh data from Firestore
  final freshUser = await _userRepository.getUserById(user.id);
  if (freshUser == null) return;

  String targetRoute;
  switch (freshUser.role) {
    case UserRole.admin:
      targetRoute = Routes.adminDashboard;
      break;
    case UserRole.doctor:
      targetRoute = Routes.doctorDashboard;
      break;
    case UserRole.nurse:
      targetRoute = Routes.nurseDashboard;
      break;
    case UserRole.receptionist:
      targetRoute = Routes.receptionistDashboard;
      break;
    case UserRole.patient:
    default:
      targetRoute = Routes.patientDashboard;
  }

  if (_navigationService.currentRoute != targetRoute) {
    _navigationService.pushReplacementNamed(targetRoute);
  }
}

  String _handleAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'The email address is already in use.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Invalid email or password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        default:
          return 'An error occurred: ${error.message}';
      }
    }
    return 'An error occurred: $error';
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
   print('Auth state changed: ${firebaseUser?.uid}');
  if (firebaseUser == null) {
    _currentUser = null;
    _lastHandledUserId = null;
    _error = null;
    notifyListeners();
    if (_navigationService.currentRoute != Routes.login) {
      _navigationService.pushReplacementNamed(Routes.login);
    }
    return;
  }

  if (_lastHandledUserId == firebaseUser.uid) return;
  _lastHandledUserId = firebaseUser.uid;

  try {
    _isLoading = true;
    notifyListeners();

    var user = await _userRepository.getUserById(firebaseUser.uid);
    print('Fetched user: ${user?.toMap()}');
    if (user == null) {
      print('Creating new user with default role');
      // Create new user with determined role
      final role = await _determineUserRole(firebaseUser);
      user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'User',
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
      await _userRepository.createUser(user);
    } else {
      // Check if existing user's role needs update
      final isAdmin = await _isActualAdmin(firebaseUser);
      if (user.role != UserRole.admin && isAdmin) {
        user = user.copyWith(role: UserRole.admin);
        await _userRepository.updateUser(user);
      }
    }

    _currentUser = user;
    print('Current user role: ${user?.role}');
    handleAuthRedirect(user);
  } catch (e) {
    print('Error in auth state change: $e');
    _error = e.toString();
    _currentUser = null;
    _navigationService.pushReplacementNamed(Routes.login);
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
Future<UserRole> _determineUserRole(firebase_auth.User firebaseUser) async {
  final token = await firebaseUser.getIdTokenResult();
  if (token.claims?['admin'] == true) {
    return UserRole.admin;
  }
  // Fallback logic (adjust as needed)
  if (firebaseUser.email?.contains('@admin.com') ?? false) {
    return UserRole.admin;
  }
  return UserRole.patient;
}

Future<bool> _isActualAdmin(firebase_auth.User firebaseUser) async {
  final token = await firebaseUser.getIdTokenResult(true);
  return token.claims?['admin'] == true;
}

  String _getRouteForUser(User user) {
    switch (user.role) {
      case UserRole.admin:
        return Routes.adminDashboard;
      case UserRole.doctor:
        return Routes.doctorDashboard;
      case UserRole.nurse:
        return Routes.nurseDashboard;
      case UserRole.receptionist:
        return Routes.receptionistDashboard;
      case UserRole.patient:
        return Routes.patientDashboard;
      default:
        return Routes.login;
    }
  }
  

  static Widget roleRestricted({
    required UserRole requiredRole,
    required Widget child,
    Widget? fallback,
  }) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.hasRoleAccess(requiredRole)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}