// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:patient_management_app/config/service_locator.dart';
// import 'package:patient_management_app/data/models/medical_record_model.dart';
// import 'package:patient_management_app/services/database_service.dart';

// class MedicalRecordRepository {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final DatabaseService _databaseService = locator<DatabaseService>();
  
//   // Collection reference
//   CollectionReference<Map<String, dynamic>> get _medicalRecordsCollection => 
//       _firestore.collection('medical_records');
  
//   // Create a new medical record
//   Future<String> createMedicalRecord(MedicalRecord record) async {
//     try {
//       // Add to Firestore
//       await _medicalRecordsCollection.doc(record.id).set(record.toMap());
      
//       // Add to local database
//       await _databaseService.insert('medical_records', record.toSqliteMap());
      
//       return record.id;
//     } catch (e) {
//       // If Firestore fails, still try to save locally and track for sync
//       await _databaseService.insert('medical_records', record.toSqliteMap());
//       await _databaseService.trackChange('medical_records', record.id, 'insert');
//       rethrow;
//     }
//   }
  
//   // Get a medical record by ID
//   Future<MedicalRecord?> getMedicalRecordById(String id) async {
//     try {
//       // Try to get from Firestore first
//       final docSnapshot = await _medicalRecordsCollection.doc(id).get();
//       if (docSnapshot.exists) {
//         return MedicalRecord.fromFirestore(docSnapshot);
//       }
//     } catch (e) {
//       // If Firestore fails, try local database
//       print('Firestore error: $e');
//     }
    
//     // Get from local database
//     final recordData = await _databaseService.queryById('medical_records', id);
//     if (recordData != null) {
//       return MedicalRecord.fromSqliteMap(recordData);
//     }
    
//     return null;
//   }
  
//   // Get all medical records for a patient
//   Future<List<MedicalRecord>> getMedicalRecordsForPatient(String patientId) async {
//     try {
//       // Try to get from Firestore first
//       final querySnapshot = await _medicalRecordsCollection
//           .where('patientId', isEqualTo: patientId)
//           .where('isActive', isEqualTo: true)
//           .orderBy('visitDate', descending: true)
//           .get();
      
//       return querySnapshot.docs.map((doc) => MedicalRecord.fromFirestore(doc)).toList();
//     } catch (e) {
//       // If Firestore fails, get from local database
//       print('Firestore error: $e');
//       final recordsData = await _databaseService.query(
//         'medical_records',
//         where: 'patientId = ? AND isActive = ?',
//         whereArgs: [patientId, 1],
//         orderBy: 'visitDate DESC',
//       );
      
//       return recordsData.map((data) => MedicalRecord.fromSqliteMap(data)).toList();
//     }
//   }
  
//   // Get all medical records for a doctor
//   Future<List<MedicalRecord>> getMedicalRecordsForDoctor(String doctorId) async {
//     try {
//       // Try to get from Firestore first
//       final querySnapshot = await _medicalRecordsCollection
//           .where('doctorId', isEqualTo: doctorId)
//           .where('isActive', isEqualTo: true)
//           .orderBy('visitDate', descending: true)
//           .get();
      
//       return querySnapshot.docs.map((doc) => MedicalRecord.fromFirestore(doc)).toList();
//     } catch (e) {
//       // If Firestore fails, get from local database
//       print('Firestore error: $e');
//       final recordsData = await _databaseService.query(
//         'medical_records',
//         where: 'doctorId = ? AND isActive = ?',
//         whereArgs: [doctorId, 1],
//         orderBy: 'visitDate DESC',
//       );
      
//       return recordsData.map((data) => MedicalRecord.fromSqliteMap(data)).toList();
//     }
//   }
  
//   // Get all medical records
//   Future<List<MedicalRecord>> getAllMedicalRecords() async {
//     try {
//       // Try to get from Firestore first
//       final querySnapshot = await _medicalRecordsCollection
//           .where('isActive', isEqualTo: true)
//           .orderBy('visitDate', descending: true)
//           .get();
      
//       return querySnapshot.docs.map((doc) => MedicalRecord.fromFirestore(doc)).toList();
//     } catch (e) {
//       // If Firestore fails, get from local database
//       print('Firestore error: $e');
//       final recordsData = await _databaseService.query(
//         'medical_records',
//         where: 'isActive = ?',
//         whereArgs: [1],
//         orderBy: 'visitDate DESC',
//       );
      
//       return recordsData.map((data) => MedicalRecord.fromSqliteMap(data)).toList();
//     }
//   }
  
//   // Update a medical record
//   Future<void> updateMedicalRecord(MedicalRecord record) async {
//     try {
//       // Update in Firestore
//       await _medicalRecordsCollection.doc(record.id).update(record.toMap());
      
//       // Update in local database
//       await _databaseService.update(
//         'medical_records', 
//         record.toSqliteMap(), 
//         'id = ?', 
//         [record.id]
//       );
//     } catch (e) {
//       // If Firestore fails, still try to update locally and track for sync
//       await _databaseService.update(
//         'medical_records', 
//         record.toSqliteMap(), 
//         'id = ?', 
//         [record.id]
//       );
//       await _databaseService.trackChange('medical_records', record.id, 'update');
//       rethrow;
//     }
//   }
  
//   // Delete a medical record (soft delete)
//   Future<void> deleteMedicalRecord(String id) async {
//     try {
//       // Soft delete in Firestore
//       await _medicalRecordsCollection.doc(id).update({'isActive': false});
      
//       // Soft delete in local database
//       await _databaseService.update(
//         'medical_records', 
//         {'isActive': 0}, 
//         'id = ?', 
//         [id]
//       );
//     } catch (e) {
//       // If Firestore fails, still try to update locally and track for sync
//       await _databaseService.update(
//         'medical_records', 
//         {'isActive': 0}, 
//         'id = ?', 
//         [id]
//       );
//       await _databaseService.trackChange('medical_records', id, 'update');
//       rethrow;
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/medical_record_model.dart';
import 'package:patient_management_app/services/database_service.dart';

class MedicalRecordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = locator<DatabaseService>();

  CollectionReference<Map<String, dynamic>> get _medicalRecordsCollection =>
      _firestore.collection('medical_records');

  Future<String> createMedicalRecord(MedicalRecord record) async {
    try {
      final recordData = record.toMap();
      await _medicalRecordsCollection.doc(record.id).set(recordData);
      await _databaseService.insert('medical_records', record.toSqliteMap());
      await _databaseService.trackChange('set', 'medical_records', record.id, recordData);
      return record.id;
    } catch (e) {
      final recordData = record.toMap();
      await _databaseService.insert('medical_records', record.toSqliteMap());
      await _databaseService.trackChange('set', 'medical_records', record.id, recordData);
      rethrow;
    }
  }

  Future<MedicalRecord?> getMedicalRecordById(String id) async {
    try {
      final docSnapshot = await _medicalRecordsCollection.doc(id).get();
      if (docSnapshot.exists) {
        return MedicalRecord.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print('Firestore error: $e');
    }
    final recordData = await _databaseService.queryById('medical_records', id);
    if (recordData != null) {
      return MedicalRecord.fromSqliteMap(recordData);
    }
    return null;
  }

  Future<List<MedicalRecord>> getMedicalRecordsForPatient(String patientId) async {
    try {
      final querySnapshot = await _medicalRecordsCollection
          .where('patientId', isEqualTo: patientId)
          .where('isActive', isEqualTo: true)
          .orderBy('visitDate', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => MedicalRecord.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final recordsData = await _databaseService.query(
        'medical_records',
        where: 'patientId = ? AND isActive = ?',
        whereArgs: [patientId, 1],
        orderBy: 'visitDate DESC',
      );
      return recordsData.map((data) => MedicalRecord.fromSqliteMap(data)).toList();
    }
  }

  Future<List<MedicalRecord>> getMedicalRecordsForDoctor(String doctorId) async {
    try {
      final querySnapshot = await _medicalRecordsCollection
          .where('doctorId', isEqualTo: doctorId)
          .where('isActive', isEqualTo: true)
          .orderBy('visitDate', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => MedicalRecord.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final recordsData = await _databaseService.query(
        'medical_records',
        where: 'doctorId = ? AND isActive = ?',
        whereArgs: [doctorId, 1],
        orderBy: 'visitDate DESC',
      );
      return recordsData.map((data) => MedicalRecord.fromSqliteMap(data)).toList();
    }
  }

  Future<List<MedicalRecord>> getAllMedicalRecords() async {
    try {
      final querySnapshot = await _medicalRecordsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('visitDate', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => MedicalRecord.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final recordsData = await _databaseService.query(
        'medical_records',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'visitDate DESC',
      );
      return recordsData.map((data) => MedicalRecord.fromSqliteMap(data)).toList();
    }
  }

  Future<void> updateMedicalRecord(MedicalRecord record) async {
    try {
      final recordData = record.toMap();
      await _medicalRecordsCollection.doc(record.id).update(recordData);
      await _databaseService.update(
        'medical_records',
        record.toSqliteMap(),
        'id = ?',
        [record.id],
      );
      await _databaseService.trackChange('update', 'medical_records', record.id, recordData);
    } catch (e) {
      final recordData = record.toMap();
      await _databaseService.update(
        'medical_records',
        record.toSqliteMap(),
        'id = ?',
        [record.id],
      );
      await _databaseService.trackChange('update', 'medical_records', record.id, recordData);
      rethrow;
    }
  }

  Future<void> deleteMedicalRecord(String id) async {
    try {
      final recordData = {'isActive': false};
      await _medicalRecordsCollection.doc(id).update(recordData);
      await _databaseService.update(
        'medical_records',
        {'isActive': 0},
        'id = ?',
        [id],
      );
      await _databaseService.trackChange('update', 'medical_records', id, recordData);
    } catch (e) {
      final recordData = {'isActive': 0};
      await _databaseService.update(
        'medical_records',
        {'isActive': 0},
        'id = ?',
        [id],
      );
      await _databaseService.trackChange('update', 'medical_records', id, recordData);
      rethrow;
    }
  }
}