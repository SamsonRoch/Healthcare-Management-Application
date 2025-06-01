// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:patient_management_app/config/service_locator.dart';
// import 'package:patient_management_app/data/models/user_model.dart' as app_models;
// import 'package:patient_management_app/data/repositories/user_repository.dart';
// import 'package:patient_management_app/services/storage_service.dart';

// class AuthRepository {
//   final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
//   final UserRepository _userRepository = locator<UserRepository>();
//   final StorageService _storageService = locator<StorageService>();
  
//   // Get current Firebase user
//   firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;
  
//   // Get current user stream
//   Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
//   // Sign in with email and password
//   Future<firebase_auth.UserCredential> signInWithEmailAndPassword(String email, String password) async {
//     try {
//       final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
      
//       // Save credentials for offline login
//       await _storageService.saveUserCredentials(email, password);
      
//       return userCredential;
//     } catch (e) {
//       rethrow;
//     }
//   }
  
//   // Sign up with email and password
//   Future<firebase_auth.UserCredential> signUpWithEmailAndPassword(String email, String password) async {
//     try {
//       return await _firebaseAuth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//     } catch (e) {
//       rethrow;
//     }
//   }
  
//   // Sign out
//   Future<void> signOut() async {
//     await _firebaseAuth.signOut();
//   }
  
//   // Reset password
//   Future<void> resetPassword(String email) async {
//     await _firebaseAuth.sendPasswordResetEmail(email: email);
//   }
  
//   // Get current user
//   Future<app_models.User?> getCurrentUser() async {
//     final firebaseUser = _firebaseAuth.currentUser;
//     if (firebaseUser != null) {
//       return await _userRepository.getUserById(firebaseUser.uid);
//     }
//     return null;
//   }
  
//   // Update email
//   Future<void> updateEmail(String newEmail) async {
//     final firebaseUser = _firebaseAuth.currentUser;
//     if (firebaseUser != null) {
//       await firebaseUser.updateEmail(newEmail);
      
//       // Update user in repository
//       final user = await _userRepository.getUserById(firebaseUser.uid);
//       if (user != null) {
//         final updatedUser = user.copyWith(email: newEmail);
//         await _userRepository.updateUser(updatedUser);
//       }
//     } else {
//       throw Exception('User not authenticated');
//     }
//   }
  
//   // Update password
//   Future<void> updatePassword(String newPassword) async {
//     final firebaseUser = _firebaseAuth.currentUser;
//     if (firebaseUser != null) {
//       await firebaseUser.updatePassword(newPassword);
      
//       // Update stored credentials
//       final credentials = await _storageService.getUserCredentials();
//       if (credentials != null && credentials['email'] != null) {
//         await _storageService.saveUserCredentials(
//           credentials['email'],
//           newPassword,
//         );
//       }
//     } else {
//       throw Exception('User not authenticated');
//     }
//   }
  
//   // Verify email
//   Future<void> sendEmailVerification() async {
//     final firebaseUser = _firebaseAuth.currentUser;
//     if (firebaseUser != null && !firebaseUser.emailVerified) {
//       await firebaseUser.sendEmailVerification();
//     } else if (firebaseUser == null) {
//       throw Exception('User not authenticated');
//     }
//   }
  
//   // Reauthenticate user
//   Future<void> reauthenticateUser(String password) async {
//     final firebaseUser = _firebaseAuth.currentUser;
//     if (firebaseUser != null && firebaseUser.email != null) {
//       final credential = firebase_auth.EmailAuthProvider.credential(
//         email: firebaseUser.email!,
//         password: password,
//       );
//       await firebaseUser.reauthenticateWithCredential(credential);
//     } else {
//       throw Exception('User not authenticated or email not available');
//     }
//   }
  
//   // Delete account
//   Future<void> deleteAccount() async {
//     final firebaseUser = _firebaseAuth.currentUser;
//     if (firebaseUser != null) {
//       // Delete user data from repository
//       await _userRepository.deleteUser(firebaseUser.uid);
      
//       // Delete Firebase account
//       await firebaseUser.delete();
      
//       // Clear stored credentials
//       await _storageService.removeUserCredentials();
//     } else {
//       throw Exception('User not authenticated');
//     }
//   }
  
//   // Try offline login
//   Future<bool> tryOfflineLogin() async {
//     final credentials = await _storageService.getUserCredentials();
//     if (credentials != null && 
//         credentials['email'] != null && 
//         credentials['password'] != null) {
//       try {
//         await signInWithEmailAndPassword(
//           credentials['email'],
//           credentials['password'],
//         );
//         return true;
//       } catch (e) {
//         return false;
//       }
//     }
//     return false;
//   }
// }
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  AuthRepository({firebase_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<firebase_auth.UserCredential> signUpWithEmailAndPassword(
      String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    } else {
      throw firebase_auth.FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }
  }
}