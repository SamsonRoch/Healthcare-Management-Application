import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Patient {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String? bloodGroup;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? emergencyContact;
  final String? emergencyContactPhone;
  final List<String>? allergies;
  final List<String>? chronicConditions;
  final Map<String, dynamic>? medicalHistory;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Patient({
    String? id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.bloodGroup,
    this.address,
    this.phoneNumber,
    this.email,
    this.emergencyContact,
    this.emergencyContactPhone,
    this.allergies,
    this.chronicConditions,
    this.medicalHistory,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  Patient copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? phoneNumber,
    String? email,
    String? emergencyContact,
    String? emergencyContactPhone,
    List<String>? allergies,
    List<String>? chronicConditions,
    Map<String, dynamic>? medicalHistory,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth.millisecondsSinceEpoch,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'emergencyContact': emergencyContact,
      'emergencyContactPhone': emergencyContactPhone,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'medicalHistory': medicalHistory,
      'metadata': metadata,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'] ?? '',
      dateOfBirth: map['dateOfBirth'] is Timestamp
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'] ?? 0),
      gender: map['gender'] ?? '',
      bloodGroup: map['bloodGroup'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      emergencyContact: map['emergencyContact'],
      emergencyContactPhone: map['emergencyContactPhone'],
      allergies: map['allergies'] != null
          ? List<String>.from(map['allergies'])
          : null,
      chronicConditions: map['chronicConditions'] != null
          ? List<String>.from(map['chronicConditions'])
          : null,
      medicalHistory: map['medicalHistory'],
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

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Patient.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  // For SQLite database
  Map<String, dynamic> toSqliteMap() {
    final map = toMap();
    // Convert lists to strings for SQLite storage
    if (allergies != null) {
      map['allergies'] = allergies!.join(',');
    }
    if (chronicConditions != null) {
      map['chronicConditions'] = chronicConditions!.join(',');
    }
    // Convert maps to JSON strings for SQLite storage
    if (medicalHistory != null) {
      map['medicalHistory'] = medicalHistory.toString();
    }
    if (metadata != null) {
      map['metadata'] = metadata.toString();
    }
    return map;
  }

  factory Patient.fromSqliteMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'] ?? '',
      dateOfBirth: DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'] ?? 0),
      gender: map['gender'] ?? '',
      bloodGroup: map['bloodGroup'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      emergencyContact: map['emergencyContact'],
      emergencyContactPhone: map['emergencyContactPhone'],
      allergies: map['allergies'] != null
          ? map['allergies'].toString().split(',')
          : null,
      chronicConditions: map['chronicConditions'] != null
          ? map['chronicConditions'].toString().split(',')
          : null,
      // These would need proper parsing in a real app
      medicalHistory: map['medicalHistory'] != null
          ? {}
          : null,
      metadata: map['metadata'] != null
          ? {}
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isActive: map['isActive'] == 1,
    );
  }

  // Calculate age based on date of birth
  int get age {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}