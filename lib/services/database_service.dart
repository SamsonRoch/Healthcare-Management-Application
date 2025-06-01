import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const _databaseName = 'patient_management.db';
  static const _databaseVersion = 8;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT,
        role TEXT NOT NULL,
        phoneNumber TEXT,
        photoUrl TEXT,
        dateOfBirth INTEGER,
        gender TEXT,
        bloodType TEXT,
        address TEXT,
        emergencyContact TEXT,
        allergies TEXT,
        medicalHistory TEXT,
        prescriptions TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dateOfBirth INTEGER NOT NULL,
        gender TEXT,
        bloodGroup TEXT,
        address TEXT,
        phoneNumber TEXT,
        email TEXT,
        chronicConditions TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        doctorId TEXT NOT NULL,
        appointmentDate INTEGER NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE medical_records (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        doctorId TEXT NOT NULL,
        visitDate INTEGER NOT NULL,
        diagnosis TEXT,
        symptoms TEXT,
        treatment TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        lastSyncedAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 8) {
      // Check and update appointments table to add startTime and endTime columns
      final existingAppointmentsColumns = await db.rawQuery('PRAGMA table_info(appointments)');
      final appointmentColumnNames = existingAppointmentsColumns.map((col) => col['name'] as String).toList();
      
      final appointmentColumns = [
        {'name': 'startTime', 'type': 'INTEGER'},
        {'name': 'endTime', 'type': 'INTEGER'},
        {'name': 'reason', 'type': 'TEXT'},
        {'name': 'metadata', 'type': 'TEXT'},
        {'name': 'isActive', 'type': 'INTEGER', 'default': 'DEFAULT 1'}
      ];
      
      for (var col in appointmentColumns) {
        if (!appointmentColumnNames.contains(col['name'])) {
          String query = 'ALTER TABLE appointments ADD COLUMN ${col["name"]} ${col["type"]}';
          if (col.containsKey('default')) {
            query += ' ${col["default"]}';
          }
          await db.execute(query);
        }
      }
    }
    
    if (oldVersion < 7) {
      // Check and update patients table
      final existingPatientsColumns = await db.rawQuery('PRAGMA table_info(patients)');
      final patientColumnNames = existingPatientsColumns.map((col) => col['name'] as String).toList();
      
      final patientColumns = [
        {'name': 'emergencyContact', 'type': 'TEXT'},
        {'name': 'emergencyContactPhone', 'type': 'TEXT'},
        {'name': 'allergies', 'type': 'TEXT'},
        {'name': 'medicalHistory', 'type': 'TEXT'},
        {'name': 'metadata', 'type': 'TEXT'},
        {'name': 'isActive', 'type': 'INTEGER', 'default': 'DEFAULT 1'}
      ];
      
      for (var col in patientColumns) {
        if (!patientColumnNames.contains(col['name'])) {
          String query = 'ALTER TABLE patients ADD COLUMN ${col["name"]} ${col["type"]}';
          if (col.containsKey('default')) {
            query += ' ${col["default"]}';
          }
          await db.execute(query);
        }
      }
    }
    
    if (oldVersion < 6) {
      final existingColumns = await db.rawQuery('PRAGMA table_info(users)');
      final columnNames = existingColumns.map((col) => col['name'] as String).toList();

      final columns = [
        {'name': 'phoneNumber', 'type': 'TEXT'},
        {'name': 'photoUrl', 'type': 'TEXT'},
        {'name': 'dateOfBirth', 'type': 'INTEGER'},
        {'name': 'gender', 'type': 'TEXT'},
        {'name': 'bloodType', 'type': 'TEXT'},
        {'name': 'address', 'type': 'TEXT'},
        {'name': 'emergencyContact', 'type': 'TEXT'},
        {'name': 'allergies', 'type': 'TEXT'},
        {'name': 'medicalHistory', 'type': 'TEXT'},
        {'name': 'prescriptions', 'type': 'TEXT'},
        {'name': 'isActive', 'type': 'INTEGER', 'default': 'DEFAULT 1'},
      ];

      for (var col in columns) {
        if (!columnNames.contains(col['name'])) {
          String query = 'ALTER TABLE users ADD COLUMN ${col['name']} ${col['type']}';
          if (col.containsKey('default')) {
            query += ' ${col['default']}';
          }
          await db.execute(query);
        }
      }

      if (columnNames.contains('dateOfBirth') && oldVersion <= 5) {
        final columnsInfo = existingColumns.firstWhere((col) => col['name'] == 'dateOfBirth');
        if (columnsInfo['type'] == 'TEXT') {
          await db.execute('''
            CREATE TABLE users_temp (
              id TEXT PRIMARY KEY,
              email TEXT NOT NULL,
              name TEXT,
              role TEXT NOT NULL,
              phoneNumber TEXT,
              photoUrl TEXT,
              dateOfBirth INTEGER,
              gender TEXT,
              bloodType TEXT,
              address TEXT,
              emergencyContact TEXT,
              allergies TEXT,
              medicalHistory TEXT,
              prescriptions TEXT,
              createdAt INTEGER NOT NULL,
              updatedAt INTEGER NOT NULL,
              isActive INTEGER NOT NULL DEFAULT 1
            )
          ''');
          await db.execute('''
            INSERT INTO users_temp (
              id, email, name, role, phoneNumber, photoUrl, dateOfBirth, gender,
              bloodType, address, emergencyContact, allergies, medicalHistory,
              prescriptions, createdAt, updatedAt, isActive
            )
            SELECT
              id, email, name, role, phoneNumber, photoUrl,
              CASE
                WHEN dateOfBirth IS NOT NULL THEN CAST(dateOfBirth AS INTEGER)
                ELSE NULL
              END,
              gender, bloodType, address, emergencyContact, allergies, medicalHistory,
              prescriptions, createdAt, updatedAt, isActive
            FROM users
          ''');
          await db.execute('DROP TABLE users');
          await db.execute('ALTER TABLE users_temp RENAME TO users');
        }
      }
    }
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    final sanitizedData = Map<String, dynamic>.from(data);
    if (table == 'users' && sanitizedData['allergies'] != null && sanitizedData['allergies'] is List) {
      sanitizedData['allergies'] = jsonEncode(sanitizedData['allergies']);
    }
    await db.insert(table, sanitizedData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    final db = await database;
    final sanitizedData = Map<String, dynamic>.from(data);
    if (table == 'users' && sanitizedData['allergies'] != null && sanitizedData['allergies'] is List) {
      sanitizedData['allergies'] = jsonEncode(sanitizedData['allergies']);
    }
    await db.update(table, sanitizedData, where: where, whereArgs: whereArgs);
  }

  Future<void> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<Map<String, dynamic>?> queryById(String table, String id) async {
    final db = await database;
    final result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty && table == 'users' && result.first['allergies'] != null) {
      try {
        result.first['allergies'] = jsonDecode(result.first['allergies'] as String);
      } catch (e) {
        result.first['allergies'] = [];
      }
    }
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final db = await database;
    final result = await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
    if (table == 'users') {
      return result.map((row) {
        final rowCopy = Map<String, dynamic>.from(row);
        if (rowCopy['allergies'] != null) {
          try {
            rowCopy['allergies'] = jsonDecode(rowCopy['allergies'] as String);
          } catch (e) {
            rowCopy['allergies'] = [];
          }
        }
        return rowCopy;
      }).toList();
    }
    return result;
  }

  Future<void> trackChange(String operation, String collection, String docId, Map<String, dynamic> data) async {
    final db = await database;
    final sanitizedData = Map<String, dynamic>.from(data);
    if (collection == 'users' && sanitizedData['allergies'] != null && sanitizedData['allergies'] is List) {
      sanitizedData['allergies'] = jsonEncode(sanitizedData['allergies']);
    }
    await db.insert(
      'pending_changes',
      {
        'operation': operation,
        'tableName': collection,
        'recordId': docId,
        'data': jsonEncode(sanitizedData),
        'synced': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncChanges() async {
    final db = await database;
    final result = await db.query('pending_changes', where: 'synced = ?', whereArgs: [0], orderBy: 'createdAt ASC');
    return result.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      if (row['tableName'] == 'users' && data['allergies'] != null) {
        try {
          data['allergies'] = jsonDecode(data['allergies'] as String);
        } catch (e) {
          data['allergies'] = [];
        }
      }
      return {
        ...row,
        'data': data,
      };
    }).toList();
  }

  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update('pending_changes', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);
    await deleteDatabase(path);
    _database = null;
  }
}