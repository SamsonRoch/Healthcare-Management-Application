import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum AppointmentStatus {
  scheduled,
  confirmed,
  completed,
  cancelled,
  noShow,
  rescheduled
}

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime appointmentDate;
  final DateTime startTime;
  final DateTime endTime;
  final String? reason;
  final String? notes;
  final AppointmentStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Appointment({
    String? id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    this.reason,
    this.notes,
    this.status = AppointmentStatus.scheduled,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  Appointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    DateTime? appointmentDate,
    DateTime? startTime,
    DateTime? endTime,
    String? reason,
    String? notes,
    AppointmentStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentDate': appointmentDate.millisecondsSinceEpoch,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'reason': reason,
      'notes': notes,
      'status': status.toString().split('.').last,
      'metadata': metadata,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      appointmentDate: map['appointmentDate'] is Timestamp
          ? (map['appointmentDate'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['appointmentDate'] ?? 0),
      startTime: map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['endTime'] ?? 0),
      reason: map['reason'],
      notes: map['notes'],
      status: _statusFromString(map['status'] ?? 'scheduled'),
      metadata: map['metadata'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isActive: map['isActive'] ?? true,
    );
  }

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  static AppointmentStatus _statusFromString(String statusStr) {
    switch (statusStr) {
      case 'scheduled':
        return AppointmentStatus.scheduled;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'noShow':
        return AppointmentStatus.noShow;
      case 'rescheduled':
        return AppointmentStatus.rescheduled;
      default:
        return AppointmentStatus.scheduled;
    }
  }

  // For SQLite database
  Map<String, dynamic> toSqliteMap() {
    final map = toMap();
    // Convert status enum to string
    map['status'] = status.toString().split('.').last;
    // Convert metadata to string for SQLite storage
    if (metadata != null) {
      map['metadata'] = metadata.toString();
    }
    // Convert boolean values to integers for SQLite compatibility
    map['isActive'] = isActive ? 1 : 0;
    return map;
  }

  factory Appointment.fromSqliteMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      appointmentDate: DateTime.fromMillisecondsSinceEpoch(map['appointmentDate'] ?? 0),
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime'] ?? 0),
      reason: map['reason'],
      notes: map['notes'],
      status: _statusFromString(map['status'] ?? 'scheduled'),
      // This would need proper parsing in a real app
      metadata: map['metadata'] != null ? {} : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isActive: map['isActive'] == 1,
    );
  }

  // Check if appointment is upcoming
  bool get isUpcoming => DateTime.now().isBefore(startTime);

  // Check if appointment is in progress
  bool get isInProgress => 
      DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);

  // Check if appointment is past
  bool get isPast => DateTime.now().isAfter(endTime);

  // Duration of appointment in minutes
  int get durationInMinutes => 
      endTime.difference(startTime).inMinutes;
}