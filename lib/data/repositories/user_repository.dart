import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final DatabaseService _databaseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? locator<DatabaseService>();

  // Firestore collection references
  CollectionReference<Map<String, dynamic>> get usersCollection => 
      _firestore.collection('users');

  // Create user in Firestore
  Future<void> createUser(User user) async {
    await usersCollection.doc(user.id).set(user.toMap());
  }

  // Get user by ID from Firestore
  Future<User?> getUserById(String id) async {
    final doc = await usersCollection.doc(id).get();
    return doc.exists ? User.fromMap(doc.data()!) : null;
  }

  // Get all users from SQLite and Firestore
  Future<List<User>> getAllUsers() async {
    try {
      // Try to get from Firestore first
      final users = await getAllUsersFirestore();
      if (users.isNotEmpty) {
        return users;
      }
      
      // Fall back to SQLite if Firestore fails or returns empty
      final result = await _databaseService.query('users');
      return result.map((map) => User.fromMap(_convertFromSqliteMap(map))).toList();
    } catch (e) {
      print('Error in getAllUsers: $e');
      // If both fail, create a sample patient for testing
      await _createSamplePatientIfNeeded();
      // Try again from Firestore
      return await getAllUsersFirestore();
    }
  }

  // Get all users from Firestore
  Future<List<User>> getAllUsersFirestore() async {
    final snapshot = await usersCollection.get();
    return snapshot.docs
        .map((doc) => User.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Get users by role from SQLite (existing method)
  Future<List<User>> getUsersByRole(String role) async {
    final result = await _databaseService.query(
      'users',
      where: 'role = ?',
      whereArgs: [role],
    );
    return result.map((map) => User.fromMap(_convertFromSqliteMap(map))).toList();
  }

  // Get users by role from Firestore with pagination support
  Future<List<User>> getUsersByRoleFirestore(String role, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? orderBy = 'name',
  }) async {
    try {
      print('Fetching users with role: $role from Firestore');
      Query query = usersCollection
          .where('role', isEqualTo: role)
          .limit(limit);
      
      if (orderBy != null) {
        query = query.orderBy(orderBy);
      }
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final snapshot = await query.get();
      print('Found ${snapshot.docs.length} users with role: $role');
      
      return snapshot.docs
          .map((doc) => User.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error in getUsersByRoleFirestore: $e');
      return [];
    }
  }

  // Get users with optional role filter (existing method)
  Future<List<User>> getUsers({String? role}) async {
    final result = await _databaseService.query(
      'users',
      where: role != null ? 'role = ?' : null,
      whereArgs: role != null ? [role] : null,
    );
    return result.map((map) => User.fromMap(_convertFromSqliteMap(map))).toList();
  }

  // Update user in Firestore
  Future<void> updateUser(User user) async {
    await usersCollection.doc(user.id).update(user.toMap());
  }

  // Delete user (existing method)
  Future<void> deleteUser(String id) async {
    await _databaseService.delete('users', 'id = ?', [id]);
    // Also delete from Firestore if needed
    await usersCollection.doc(id).delete();
  }
  
  // Get staff counts for analytics
  Future<Map<String, int>> getStaffCounts() async {
  final result = <String, int>{};
  
  // Get count of doctors
  final doctorSnapshot = await usersCollection
      .where('role', isEqualTo: UserRole.doctor.name)
      .count()
      .get();
  result['doctors'] = doctorSnapshot.count ?? 0;
  
  // Get count of nurses
  final nurseSnapshot = await usersCollection
      .where('role', isEqualTo: UserRole.nurse.name)
      .count()
      .get();
  result['nurses'] = nurseSnapshot.count ?? 0;
  
  // Get count of receptionists
  final receptionistSnapshot = await usersCollection
      .where('role', isEqualTo: UserRole.receptionist.name)
      .count()
      .get();
  result['receptionists'] = receptionistSnapshot.count ?? 0;
  
  return result;
}
  // Get users by department
  Future<List<User>> getUsersByDepartment(String department) async {
    final snapshot = await usersCollection
        .where('departments', arrayContains: department)
        .get();
    
    return snapshot.docs
        .map((doc) => User.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Helper method to convert Firestore data types to SQLite-compatible types
  Map<String, dynamic> _convertToSqliteMap(Map<String, dynamic> map) {
    final result = Map<String, dynamic>.from(map);

    // Convert Timestamp to millisecondsSinceEpoch (int)
    if (map['createdAt'] is Timestamp) {
      result['createdAt'] = map['createdAt'].toDate().millisecondsSinceEpoch;
    }

    if (map['updatedAt'] is Timestamp) {
      result['updatedAt'] = map['updatedAt'].toDate().millisecondsSinceEpoch;
    }

    // Convert boolean to int (0 or 1)
    if (map['isActive'] is bool) {
      result['isActive'] = map['isActive'] ? 1 : 0;
    }

    // Handle any other non-SQLite compatible types here
    // For example, convert lists to JSON strings if needed
    if (map['allergies'] is List) {
      result['allergies'] = map['allergies'].join(',');
    }
    
    // Handle departments
    if (map['departments'] is List) {
      result['departments'] = map['departments'].join(',');
    }

    return result;
  }

  // Helper method to convert SQLite data back to Firestore-compatible types
  Map<String, dynamic> _convertFromSqliteMap(Map<String, dynamic> map) {
    final result = Map<String, dynamic>.from(map);

    // Convert millisecondsSinceEpoch back to Timestamp
    if (map['createdAt'] is int) {
      result['createdAt'] = Timestamp.fromDate(
          DateTime.fromMillisecondsSinceEpoch(map['createdAt']));
    }

    if (map['updatedAt'] is int) {
      result['updatedAt'] = Timestamp.fromDate(
          DateTime.fromMillisecondsSinceEpoch(map['updatedAt']));
    }

    // Convert int back to boolean
    if (map['isActive'] is int) {
      result['isActive'] = map['isActive'] == 1;
    }

    // Handle any other converted types
    if (map['allergies'] is String && map['allergies'].isNotEmpty) {
      result['allergies'] = map['allergies'].split(',');
    }
    
    // Handle departments
    if (map['departments'] is String && map['departments'].isNotEmpty) {
      result['departments'] = map['departments'].split(',');
    }

    return result;
  }
  
  // Create a sample patient for testing if no patients exist
  Future<void> _createSamplePatientIfNeeded() async {
    try {
      // Check if any patients exist
      final patients = await getUsersByRoleFirestore(UserRole.patient.name);
      if (patients.isEmpty) {
        print('No patients found, creating a sample patient');
        // Create a sample patient
        final samplePatient = User(
          id: 'sample_patient_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Sample Patient',
          email: 'sample.patient@example.com',
          role: UserRole.patient,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          phoneNumber: '+1234567890',
        );
        
        await createUser(samplePatient);
        print('Created sample patient with ID: ${samplePatient.id}');
      }
    } catch (e) {
      print('Error creating sample patient: $e');
    }
  }
}