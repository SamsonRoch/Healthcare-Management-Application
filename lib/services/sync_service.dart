import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/data/repositories/patient_repository.dart';
import 'package:patient_management_app/services/database_service.dart';

class SyncService {
  final PatientRepository _patientRepository;
  final DatabaseService _databaseService;

  SyncService({
    PatientRepository? patientRepository,
    DatabaseService? databaseService,
  })  : _patientRepository =
      patientRepository ?? locator<PatientRepository>(),
        _databaseService = databaseService ?? locator<DatabaseService>();

  Future<void> initialize() async {
    await syncUsers();
  }

  Future<void> forceSync() async {
    await syncUsers();
  }

  Future<void> syncUsers() async {
    try {
      final db = await _databaseService.database;
      final localUsers = await db.query('users');

      final firestore = FirebaseFirestore.instance;
      final remoteUsers = await firestore.collection('users').get();

      for (var localUser in localUsers) {
        final userId = localUser['id'] as String;
        final existsRemotely = remoteUsers.docs.any((doc) => doc.id == userId);

        if (!existsRemotely) {
          await firestore.collection('users').doc(userId).set({
            'email': localUser['email'],
            'name': localUser['name'],
            'role': localUser['role'],
            'phoneNumber': localUser['phoneNumber'],
            'createdAt': localUser['createdAt'] != null
                ? Timestamp.fromMillisecondsSinceEpoch(localUser['createdAt'] as int)
                : null,
            'updatedAt': localUser['updatedAt'] != null
                ? Timestamp.fromMillisecondsSinceEpoch(localUser['updatedAt'] as int)
                : null,
            'isActive': localUser['isActive'] == 1,
          });
        }
      }

      for (var remoteUser in remoteUsers.docs) {
        final existsLocally = localUsers.any((u) => u['id'] == remoteUser.id);
        if (!existsLocally) {
          await db.insert('users', {
            'id': remoteUser.id,
            'email': remoteUser.data()['email'],
            'name': remoteUser.data()['name'],
            'role': remoteUser.data()['role'],
            'phoneNumber': remoteUser.data()['phoneNumber'],
            'createdAt': (remoteUser.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch,
            'updatedAt': (remoteUser.data()['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch,
            'isActive': remoteUser.data()['isActive'] == true ? 1 : 0,
          });
        }
      }

      final pendingChanges = await _databaseService.getPendingSyncChanges();
      for (var change in pendingChanges) {
        final data = Map<String, dynamic>.from(change['data'] as Map);
        final operation = change['operation'] as String;
        final tableName = change['tableName'] as String;
        final recordId = change['recordId'] as String;

        if (tableName == 'users') {
          if (operation == 'insert' || operation == 'update') {
            await firestore.collection('users').doc(recordId).set(data);
          } else if (operation == 'delete') {
            await firestore.collection('users').doc(recordId).delete();
          }
          await _databaseService.markAsSynced(change['id'] as int);
        }
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }
}