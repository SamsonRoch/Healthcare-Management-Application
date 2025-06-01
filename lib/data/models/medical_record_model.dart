import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime visitDate;
  final String diagnosis;
  final String symptoms;
  final String treatment;
  final List<Prescription>? prescriptions;
  final List<String>? attachments;
  final Map<String, dynamic>? vitalSigns;
  final Map<String, dynamic>? labResults;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  MedicalRecord({
    String? id,
    required this.patientId,
    required this.doctorId,
    required this.visitDate,
    required this.diagnosis,
    required this.symptoms,
    required this.treatment,
    this.prescriptions,
    this.attachments,
    this.vitalSigns,
    this.labResults,
    this.notes,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  MedicalRecord copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    DateTime? visitDate,
    String? diagnosis,
    String? symptoms,
    String? treatment,
    List<Prescription>? prescriptions,
    List<String>? attachments,
    Map<String, dynamic>? vitalSigns,
    Map<String, dynamic>? labResults,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      visitDate: visitDate ?? this.visitDate,
      diagnosis: diagnosis ?? this.diagnosis,
      symptoms: symptoms ?? this.symptoms,
      treatment: treatment ?? this.treatment,
      prescriptions: prescriptions ?? this.prescriptions,
      attachments: attachments ?? this.attachments,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      labResults: labResults ?? this.labResults,
      notes: notes ?? this.notes,
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
      'visitDate': visitDate.millisecondsSinceEpoch,
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'treatment': treatment,
      'prescriptions': prescriptions?.map((p) => p.toMap()).toList(),
      'attachments': attachments,
      'vitalSigns': vitalSigns,
      'labResults': labResults,
      'notes': notes,
      'metadata': metadata,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'visitDate': visitDate.millisecondsSinceEpoch,
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'treatment': treatment,
      'prescriptions': prescriptions != null ? _encodePrescriptions(prescriptions!) : null,
      'attachments': attachments != null ? attachments!.join(',') : null,
      'vitalSigns': vitalSigns != null ? _encodeMap(vitalSigns!) : null,
      'labResults': labResults != null ? _encodeMap(labResults!) : null,
      'notes': notes,
      'metadata': metadata != null ? _encodeMap(metadata!) : null,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'],
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      visitDate: map['visitDate'] is Timestamp
          ? (map['visitDate'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['visitDate'] ?? 0),
      diagnosis: map['diagnosis'] ?? '',
      symptoms: map['symptoms'] ?? '',
      treatment: map['treatment'] ?? '',
      prescriptions: map['prescriptions'] != null
          ? List<Prescription>.from(
              (map['prescriptions'] as List).map((p) => Prescription.fromMap(p)))
          : null,
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      vitalSigns: map['vitalSigns'],
      labResults: map['labResults'],
      notes: map['notes'],
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

  factory MedicalRecord.fromSqliteMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'],
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      visitDate: DateTime.fromMillisecondsSinceEpoch(map['visitDate'] ?? 0),
      diagnosis: map['diagnosis'] ?? '',
      symptoms: map['symptoms'] ?? '',
      treatment: map['treatment'] ?? '',
      prescriptions: map['prescriptions'] != null
          ? _decodePrescriptions(map['prescriptions'])
          : null,
      attachments: map['attachments'] != null
          ? map['attachments'].split(',')
          : null,
      vitalSigns: map['vitalSigns'] != null
          ? _decodeMap(map['vitalSigns'])
          : null,
      labResults: map['labResults'] != null
          ? _decodeMap(map['labResults'])
          : null,
      notes: map['notes'],
      metadata: map['metadata'] != null
          ? _decodeMap(map['metadata'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isActive: map['isActive'] == 1,
    );
  }

  factory MedicalRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalRecord.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  // Helper methods for encoding/decoding complex data for SQLite
  static String _encodePrescriptions(List<Prescription> prescriptions) {
    return prescriptions.map((p) => p.toString()).join('|');
  }

  static List<Prescription> _decodePrescriptions(String encoded) {
    return encoded.split('|').map((p) => Prescription.fromString(p)).toList();
  }

  static String _encodeMap(Map<String, dynamic> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  static Map<String, dynamic> _decodeMap(String encoded) {
    final map = <String, dynamic>{};
    encoded.split(',').forEach((item) {
      final parts = item.split(':');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    });
    return map;
  }
}

class Prescription {
  final String medication;
  final String dosage;
  final String frequency;
  final int duration; // in days
  final String? instructions;

  Prescription({
    required this.medication,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'medication': medication,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      medication: map['medication'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? 0,
      instructions: map['instructions'],
    );
  }

  @override
  String toString() {
    return '$medication,$dosage,$frequency,$duration,${instructions ?? ""}';
  }

  factory Prescription.fromString(String str) {
    final parts = str.split(',');
    return Prescription(
      medication: parts[0],
      dosage: parts[1],
      frequency: parts[2],
      duration: int.parse(parts[3]),
      instructions: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
    );
  }
}