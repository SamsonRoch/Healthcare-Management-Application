import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/appointment_model.dart';
import 'package:patient_management_app/services/database_service.dart';

class AppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = locator<DatabaseService>();

  CollectionReference<Map<String, dynamic>> get _appointmentsCollection =>
      _firestore.collection('appointments');

  Future<String> createAppointment(Appointment appointment) async {
    try {
      final appointmentData = appointment.toMap();
      await _appointmentsCollection.doc(appointment.id).set(appointmentData);
      await _databaseService.insert('appointments', appointment.toSqliteMap());
      await _databaseService.trackChange('set', 'appointments', appointment.id, appointmentData);
      return appointment.id;
    } catch (e) {
      final appointmentData = appointment.toMap();
      await _databaseService.insert('appointments', appointment.toSqliteMap());
      await _databaseService.trackChange('set', 'appointments', appointment.id, appointmentData);
      rethrow;
    }
  }

  Future<Appointment?> getAppointmentById(String id) async {
    try {
      final docSnapshot = await _appointmentsCollection.doc(id).get();
      if (docSnapshot.exists) {
        return Appointment.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print('Firestore error: $e');
    }
    final appointmentData = await _databaseService.queryById('appointments', id);
    if (appointmentData != null) {
      return Appointment.fromSqliteMap(appointmentData);
    }
    return null;
  }

  Future<List<Appointment>> getAllAppointments() async {
    try {
      final querySnapshot = await _appointmentsCollection.get();
      final appointments = querySnapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
      // Filter out inactive appointments
      return appointments.where((appointment) => appointment.isActive).toList();
    } catch (e) {
      print('Firestore error: $e');
      final appointmentsData = await _databaseService.query('appointments', where: 'isActive = ?', whereArgs: [1]);
      return appointmentsData.map((data) => Appointment.fromSqliteMap(data)).toList();
    }
  }

  Future<List<Appointment>> getAllAppointmentsFromFirestore() async {
    final querySnapshot = await _appointmentsCollection.get();
    return querySnapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      final appointmentData = appointment.toMap();
      await _appointmentsCollection.doc(appointment.id).update(appointmentData);
      await _databaseService.update(
        'appointments',
        appointment.toSqliteMap(),
        'id = ?',
        [appointment.id],
      );
      await _databaseService.trackChange('update', 'appointments', appointment.id, appointmentData);
    } catch (e) {
      final appointmentData = appointment.toMap();
      await _databaseService.update(
        'appointments',
        appointment.toSqliteMap(),
        'id = ?',
        [appointment.id],
      );
      await _databaseService.trackChange('update', 'appointments', appointment.id, appointmentData);
      rethrow;
    }
  }

  Future<void> updateAppointmentInFirestore(Map<String, dynamic> appointmentData) async {
    await _appointmentsCollection.doc(appointmentData['id']).update(appointmentData);
  }

  Future<void> deleteAppointment(String id) async {
    try {
      // Get the appointment first
      final appointment = await getAppointmentById(id);
      if (appointment != null) {
        // Mark as inactive instead of deleting
        final updatedAppointment = appointment.copyWith(isActive: false);
        final appointmentData = updatedAppointment.toMap();
        
        // Update in Firestore
        await _appointmentsCollection.doc(id).update(appointmentData);
        
        // Update in SQLite
        await _databaseService.update(
          'appointments',
          updatedAppointment.toSqliteMap(),
          'id = ?',
          [id],
        );
        
        // Track the change
        await _databaseService.trackChange('update', 'appointments', id, appointmentData);
      } else {
        throw Exception('Appointment not found');
      }
    } catch (e) {
      print('Error deleting appointment: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointmentFromFirestore(String id) async {
    await _appointmentsCollection.doc(id).delete();
  }

  Future<List<Appointment>> getAppointmentsByPatient(String patientId) async {
    try {
      final querySnapshot = await _appointmentsCollection
          .where('patientId', isEqualTo: patientId)
          .get();
      return querySnapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final appointmentsData = await _databaseService.query(
        'appointments',
        where: 'patientId = ?',
        whereArgs: [patientId],
      );
      return appointmentsData.map((data) => Appointment.fromSqliteMap(data)).toList();
    }
  }

  Future<List<Appointment>> getAppointmentsByDoctor(String doctorId) async {
    try {
      final querySnapshot = await _appointmentsCollection
          .where('doctorId', isEqualTo: doctorId)
          .get();
      return querySnapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final appointmentsData = await _databaseService.query(
        'appointments',
        where: 'doctorId = ?',
        whereArgs: [doctorId],
      );
      return appointmentsData.map((data) => Appointment.fromSqliteMap(data)).toList();
    }
  }

  Future<List<Appointment>> getAppointmentsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _appointmentsCollection
          .where('appointmentDate', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('appointmentDate', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .get();
      return querySnapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final appointmentsData = await _databaseService.query(
        'appointments',
        where: 'appointmentDate >= ? AND appointmentDate <= ?',
        whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      );
      return appointmentsData.map((data) => Appointment.fromSqliteMap(data)).toList();
    }
  }

  Future<List<Appointment>> getAppointmentsByStatus(AppointmentStatus status) async {
    final statusStr = status.toString().split('.').last;
    try {
      final querySnapshot = await _appointmentsCollection
          .where('status', isEqualTo: statusStr)
          .get();
      return querySnapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final appointmentsData = await _databaseService.query(
        'appointments',
        where: 'status = ?',
        whereArgs: [statusStr],
      );
      return appointmentsData.map((data) => Appointment.fromSqliteMap(data)).toList();
    }
  }

  Future<bool> hasAppointmentConflict(DateTime startTime, DateTime endTime, String doctorId,
      {String? excludeAppointmentId}) async {
    try {
      final querySnapshot = await _appointmentsCollection
          .where('doctorId', isEqualTo: doctorId)
          .where('startTime', isLessThan: endTime.millisecondsSinceEpoch)
          .where('endTime', isGreaterThan: startTime.millisecondsSinceEpoch)
          .get();
      if (excludeAppointmentId != null) {
        return querySnapshot.docs.where((doc) => doc.id != excludeAppointmentId).isNotEmpty;
      }
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Firestore error: $e');
      String whereClause = 'doctorId = ? AND startTime < ? AND endTime > ?';
      List<dynamic> whereArgs = [
        doctorId,
        endTime.millisecondsSinceEpoch,
        startTime.millisecondsSinceEpoch,
      ];
      if (excludeAppointmentId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeAppointmentId);
      }
      final appointmentsData = await _databaseService.query(
        'appointments',
        where: whereClause,
        whereArgs: whereArgs,
      );
      return appointmentsData.isNotEmpty;
    }
  }

  Future<List<Appointment>> getUpcomingAppointments() async {
    final now = DateTime.now();
    try {
      final querySnapshot = await _appointmentsCollection
          .where('startTime', isGreaterThan: now.millisecondsSinceEpoch)
          .orderBy('startTime')
          .get();
      return querySnapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
    } catch (e) {
      print('Firestore error: $e');
      final appointmentsData = await _databaseService.query(
        'appointments',
        where: 'startTime > ?',
        whereArgs: [now.millisecondsSinceEpoch],
        orderBy: 'startTime ASC',
      );
      return appointmentsData.map((data) => Appointment.fromSqliteMap(data)).toList();
    }
  }

  Future<List<Appointment>> getTodayAppointments() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getAppointmentsByDateRange(startOfDay, endOfDay);
  }
  
}