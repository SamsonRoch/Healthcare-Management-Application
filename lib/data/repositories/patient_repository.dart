// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:patient_management_app/config/service_locator.dart';
// import 'package:patient_management_app/data/models/patient_model.dart';
// import 'package:patient_management_app/services/database_service.dart';

// class PatientRepository {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final DatabaseService _databaseService = locator<DatabaseService>();
  
//   // Collection reference
//   CollectionReference<Map<String, dynamic>> get _patientsCollection => 
//       _firestore.collection('patients');
  
//   // Create a new patient
//   Future<String> createPatient(Patient patient) async {
//     try {
//       // Add to Firestore
//       await _patientsCollection.doc(patient.id).set(patient.toMap());
      
//       // Add to local database
//       await _databaseService.insert('patients', patient.toSqliteMap());
      
//       return patient.id;
//     } catch (e) {
//       // If Firestore fails, still try to save locally and track for sync
//       await _databaseService.insert('patients', patient.toSqliteMap());
//       await _databaseService.trackChange('patients', patient.id, 'insert');
//       rethrow;
//     }
//   }
  
//   // Get a patient by ID
//   Future<Patient?> getPatientById(String id) async {
//     try {
//       // Try to get from Firestore first
//       final docSnapshot = await _patientsCollection.doc(id).get();
//       if (docSnapshot.exists) {
//         return Patient.fromFirestore(docSnapshot);
//       }
//     } catch (e) {
//       // If Firestore fails, try local database
//       print('Firestore error: $e');
//     }
    
//     // Get from local database
//     final patientData = await _databaseService.queryById('patients', id);
//     if (patientData != null) {
//       return Patient.fromSqliteMap(patientData);
//     }
    
//     return null;
//   }
  
//   // Get all patients
//   Future<List<Patient>> getAllPatients() async {
//     try {
//       // Try to get from Firestore first
//       final querySnapshot = await _patientsCollection.get();
//       return querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
//     } catch (e) {
//       // If Firestore fails, get from local database
//       print('Firestore error: $e');
//       final patientsData = await _databaseService.query('patients');
//       return patientsData.map((data) => Patient.fromSqliteMap(data)).toList();
//     }
//   }
  
//   // Get all patients from Firestore (for sync)
//   Future<List<Patient>> getAllPatientsFromFirestore() async {
//     final querySnapshot = await _patientsCollection.get();
//     return querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
//   }
  
//   // Update a patient
//   Future<void> updatePatient(Patient patient) async {
//     try {
//       // Update in Firestore
//       await _patientsCollection.doc(patient.id).update(patient.toMap());
      
//       // Update in local database
//       await _databaseService.update(
//         'patients', 
//         patient.toSqliteMap(), 
//         'id = ?', 
//         [patient.id]
//       );
//     } catch (e) {
//       // If Firestore fails, still try to update locally and track for sync
//       await _databaseService.update(
//         'patients', 
//         patient.toSqliteMap(), 
//         'id = ?', 
//         [patient.id]
//       );
//       await _databaseService.trackChange('patients', patient.id, 'update');
//       rethrow;
//     }
//   }
  
//   // Update a patient in Firestore (for sync)
//   Future<void> updatePatientInFirestore(Map<String, dynamic> patientData) async {
//     await _patientsCollection.doc(patientData['id']).update(patientData);
//   }
  
//   // Delete a patient
//   Future<void> deletePatient(String id) async {
//     try {
//       // Delete from Firestore
//       await _patientsCollection.doc(id).delete();
      
//       // Delete from local database
//       await _databaseService.delete('patients', 'id = ?', [id]);
//     } catch (e) {
//       // If Firestore fails, still try to delete locally and track for sync
//       await _databaseService.delete('patients', 'id = ?', [id]);
//       await _databaseService.trackChange('patients', id, 'delete');
//       rethrow;
//     }
//   }
  
//   // Delete a patient from Firestore (for sync)
//   Future<void> deletePatientFromFirestore(String id) async {
//     await _patientsCollection.doc(id).delete();
//   }
  
//   // Search patients by name
//   Future<List<Patient>> searchPatientsByName(String query) async {
//     query = query.toLowerCase();
//     try {
//       // Try to get from Firestore first
//       // Note: Firestore doesn't support case-insensitive search directly
//       // For a real app, consider using Firebase extensions or a different approach
//       final querySnapshot = await _patientsCollection.get();
//       final patients = querySnapshot.docs
//           .map((doc) => Patient.fromFirestore(doc))
//           .where((patient) => patient.name.toLowerCase().contains(query))
//           .toList();
//       return patients;
//     } catch (e) {
//       // If Firestore fails, search in local database
//       print('Firestore error: $e');
//       final patientsData = await _databaseService.query('patients');
//       final patients = patientsData
//           .map((data) => Patient.fromSqliteMap(data))
//           .where((patient) => patient.name.toLowerCase().contains(query))
//           .toList();
//       return patients;
//     }
//   }
  
//   // Get patients by blood group
//   Future<List<Patient>> getPatientsByBloodGroup(String bloodGroup) async {
//     try {
//       // Try to get from Firestore first
//       final querySnapshot = await _patientsCollection
//           .where('bloodGroup', isEqualTo: bloodGroup)
//           .get();
//       return querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
//     } catch (e) {
//       // If Firestore fails, get from local database
//       print('Firestore error: $e');
//       final patientsData = await _databaseService.query(
//         'patients',
//         where: 'bloodGroup = ?',
//         whereArgs: [bloodGroup],
//       );
//       return patientsData.map((data) => Patient.fromSqliteMap(data)).toList();
//     }
//   }
  
//   // Get patients by age range
//   Future<List<Patient>> getPatientsByAgeRange(int minAge, int maxAge) async {
//     final now = DateTime.now();
//     final maxDob = DateTime(now.year - minAge, now.month, now.day);
//     final minDob = DateTime(now.year - maxAge, now.month, now.day);
    
//     try {
//       // Try to get from Firestore first
//       final querySnapshot = await _patientsCollection
//           .where('dateOfBirth', isLessThanOrEqualTo: maxDob.millisecondsSinceEpoch)
//           .where('dateOfBirth', isGreaterThanOrEqualTo: minDob.millisecondsSinceEpoch)
//           .get();
//       return querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
//     } catch (e) {
//       // If Firestore fails, get from local database
//       print('Firestore error: $e');
//       // For SQLite, we'll need to get all patients and filter in memory
//       // since SQLite doesn't support complex date calculations easily
//       final patientsData = await _databaseService.query('patients');
//       final patients = patientsData
//           .map((data) => Patient.fromSqliteMap(data))
//           .where((patient) => 
//               patient.age >= minAge && patient.age <= maxAge)
//           .toList();
//       return patients;
//     }
//   }
  
//   // Get patients with specific chronic conditions
//   Future<List<Patient>> getPatientsWithChronicCondition(String condition) async {
//     try {
//       // Try to get from Firestore first
//       // Note: This is a simplistic approach. In a real app, you might need
//       // to use array-contains or a different data structure
//       final querySnapshot = await _patientsCollection
//           .where('chronicConditions', arrayContains: condition)
//           .get();
//       return querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
//     } catch (e) {
//       // If Firestore fails, get from local database
//       print('Firestore error: $e');
//       // For SQLite, we need to get all and filter in memory since SQLite
//       // doesn't support array operations directly
//       final patientsData = await _databaseService.query('patients');
//       final patients = patientsData
//           .map((data) => Patient.fromSqliteMap(data))
//           .where((patient) => 
//               patient.chronicConditions != null &&
//               patient.chronicConditions!.contains(condition))
//           .toList();
//       return patients;
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/patient_model.dart';
import 'package:patient_management_app/services/database_service.dart';

class PatientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = locator<DatabaseService>();

  CollectionReference<Map<String, dynamic>> get _patientsCollection =>
      _firestore.collection('patients');

  Future<String> createPatient(Patient patient) async {
    try {
      final patientData = patient.toMap();
      await _patientsCollection.doc(patient.id).set(patientData);
      await _databaseService.insert('patients', patient.toSqliteMap());
      await _databaseService.trackChange('set', 'patients', patient.id, patientData);
      return patient.id;
    } catch (e) {
      final patientData = patient.toMap();
      await _databaseService.insert('patients', patient.toSqliteMap());
      await _databaseService.trackChange('set', 'patients', patient.id, patientData);
      rethrow;
    }
  }

  Future<Patient?> getPatientById(String id) async {
    try {
      final docSnapshot = await _patientsCollection.doc(id).get();
      if (docSnapshot.exists) {
        return Patient.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print('Firestore error: $e');
    }
    final patientData = await _databaseService.queryById('patients', id);
    if (patientData != null) {
      return Patient.fromSqliteMap(patientData);
    }
    return null;
  }

  Future<List<Patient>> getAllPatients() async {
    try {
      print('Fetching patients from Firebase...');
      final querySnapshot = await _patientsCollection.get();
      final patients = querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
      print('Found ${patients.length} patients in Firebase');
      
      // If no patients in Firebase, try to create a sample patient
      if (patients.isEmpty) {
        print('No patients found in Firebase, creating a sample patient...');
        try {
          final samplePatient = Patient(
            name: 'John Doe',
            dateOfBirth: DateTime(1980, 1, 1),
            gender: 'Male',
            bloodGroup: 'O+',
            phoneNumber: '555-123-4567',
            email: 'john.doe@example.com',
            address: '123 Main St, Anytown, USA',
          );
          await createPatient(samplePatient);
          print('Sample patient created successfully');
          // Fetch again after creating sample
          final updatedSnapshot = await _patientsCollection.get();
          return updatedSnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
        } catch (createError) {
          print('Error creating sample patient: $createError');
        }
      }
      
      return patients;
    } catch (e) {
      print('Firestore error: $e');
      // Try local database as fallback
      print('Trying to fetch from local database...');
      final patientsData = await _databaseService.query('patients');
      final localPatients = patientsData.map((data) => Patient.fromSqliteMap(data)).toList();
      print('Found ${localPatients.length} patients in local database');
      return localPatients;
    }
  }

  Future<List<Patient>> getAllPatientsFromFirestore() async {
    final querySnapshot = await _patientsCollection.get();
    return querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
  }

  Future<void> updatePatient(Patient patient) async {
    try {
      final patientData = patient.toMap();
      await _patientsCollection.doc(patient.id).update(patientData);
      await _databaseService.update(
        'patients',
        patient.toSqliteMap(),
        'id = ?',
        [patient.id],
      );
      await _databaseService.trackChange('update', 'patients', patient.id, patientData);
    } catch (e) {
      final patientData = patient.toMap();
      await _databaseService.update(
        'patients',
        patient.toSqliteMap(),
        'id = ?',
        [patient.id],
      );
      await _databaseService.trackChange('update', 'patients', patient.id, patientData);
      rethrow;
    }
  }

  Future<void> updatePatientInFirestore(Map<String, dynamic> patientData) async {
    await _patientsCollection.doc(patientData['id']).update(patientData);
  }

  Future<void> deletePatient(String id) async {
    try {
      await _patientsCollection.doc(id).delete();
      await _databaseService.delete('patients', 'id = ?', [id]);
      await _databaseService.trackChange('delete', 'patients', id, {});
    } catch (e) {
      await _databaseService.delete('patients', 'id = ?', [id]);
      await _databaseService.trackChange('delete', 'patients', id, {});
      rethrow;
    }
  }

  Future<void> deletePatientFromFirestore(String id) async {
    await _patientsCollection.doc(id).delete();
  }

  Future<List<Patient>> searchPatientsByName(String query) async {
    query = query.toLowerCase();
    try {
      final querySnapshot = await _patientsCollection.get();
      final patients = querySnapshot.docs
          .map((doc) => Patient.fromFirestore(doc))
          .where((patient) => patient.name.toLowerCase().contains(query))
          .toList();
      return patients;
    } catch (e) {
      print('Firestore error: $e');
      final patientsData = await _databaseService.query('patients');
      final patients = patientsData
          .map((data) => Patient.fromSqliteMap(data))
          .where((patient) => patient.name.toLowerCase().contains(query))
          .toList();
      return patients;
    }
  }

  Future<List<Patient>> getPatientsByBloodGroup(String bloodGroup) async {
    try {
      final querySnapshot = await _patientsCollection
          .where('bloodGroup', isEqualTo: bloodGroup)
          .get();
      return querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final patientsData = await _databaseService.query(
        'patients',
        where: 'bloodGroup = ?',
        whereArgs: [bloodGroup],
      );
      return patientsData.map((data) => Patient.fromSqliteMap(data)).toList();
    }
  }

  Future<List<Patient>> getPatientsByAgeRange(int minAge, int maxAge) async {
    final now = DateTime.now();
    final maxDob = DateTime(now.year - minAge, now.month, now.day);
    final minDob = DateTime(now.year - maxAge, now.month, now.day);
    try {
      final querySnapshot = await _patientsCollection
          .where('dateOfBirth', isLessThanOrEqualTo: maxDob.millisecondsSinceEpoch)
          .where('dateOfBirth', isGreaterThanOrEqualTo: minDob.millisecondsSinceEpoch)
          .get();
      return querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final patientsData = await _databaseService.query('patients');
      final patients = patientsData
          .map((data) => Patient.fromSqliteMap(data))
          .where((patient) => patient.age >= minAge && patient.age <= maxAge)
          .toList();
      return patients;
    }
  }

  Future<List<Patient>> getPatientsWithChronicCondition(String condition) async {
    try {
      final querySnapshot = await _patientsCollection
          .where('chronicConditions', arrayContains: condition)
          .get();
      return querySnapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final patientsData = await _databaseService.query('patients');
      final patients = patientsData
          .map((data) => Patient.fromSqliteMap(data))
          .where((patient) =>
              patient.chronicConditions != null && patient.chronicConditions!.contains(condition))
          .toList();
      return patients;
    }
  }
}