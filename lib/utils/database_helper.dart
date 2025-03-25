import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/patient.dart';
import '../models/visit.dart';
import '../models/appointment.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'meddex.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create patients table
    await db.execute('''
      CREATE TABLE patients(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        contactNumber TEXT NOT NULL,
        email TEXT,
        address TEXT,
        registrationDate TEXT NOT NULL
      )
    ''');

    // Create visits table
    await db.execute('''
      CREATE TABLE visits(
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        visitDate TEXT NOT NULL,
        prescription TEXT NOT NULL,
        recommendedTests TEXT NOT NULL,
        testResults TEXT NOT NULL,
        followUpDate TEXT,
        currentTreatmentPlan TEXT NOT NULL,
        medicines TEXT NOT NULL,
        instructions TEXT NOT NULL,
        consultationFee REAL NOT NULL,
        pendingAmount REAL NOT NULL,
        totalBill REAL NOT NULL,
        paymentMode TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES patients (id)
      )
    ''');

    // Create appointments table
    await db.execute('''
      CREATE TABLE appointments(
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        appointmentDate TEXT NOT NULL,
        purpose TEXT NOT NULL,
        notes TEXT,
        isFollowUp INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'scheduled',
        FOREIGN KEY (patientId) REFERENCES patients (id)
      )
    ''');
  }

  // Patient methods
  Future<void> insertPatient(Patient patient) async {
    final Database db = await database;
    await db.insert(
      'patients',
      patient.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Patient>> getPatients() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('patients');
    return List.generate(maps.length, (i) => Patient.fromJson(maps[i]));
  }

  Future<Patient?> getPatient(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Patient.fromJson(maps.first);
  }

  // Visit methods
  Future<void> insertVisit(Visit visit) async {
    final Database db = await database;
    final visitMap = visit.toJson();
    // Convert lists and maps to JSON strings
    visitMap['recommendedTests'] = jsonEncode(visitMap['recommendedTests']);
    visitMap['testResults'] = jsonEncode(visitMap['testResults']);
    visitMap['medicines'] = jsonEncode(visitMap['medicines']);
    await db.insert(
      'visits',
      visitMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Visit>> getVisits(String patientId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );
    return List.generate(maps.length, (i) {
      final visitMap = Map<String, dynamic>.from(maps[i]);
      // Parse JSON strings back to lists and maps
      visitMap['recommendedTests'] = jsonDecode(visitMap['recommendedTests']);
      visitMap['testResults'] = jsonDecode(visitMap['testResults']);
      visitMap['medicines'] = jsonDecode(visitMap['medicines']);
      return Visit.fromJson(visitMap);
    });
  }

  Future<List<Visit>> getTodayVisits() async {
    final Database db = await database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59)
        .toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'visitDate BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
    );

    return List.generate(maps.length, (i) {
      final visitMap = Map<String, dynamic>.from(maps[i]);
      visitMap['recommendedTests'] = jsonDecode(visitMap['recommendedTests']);
      visitMap['testResults'] = jsonDecode(visitMap['testResults']);
      visitMap['medicines'] = jsonDecode(visitMap['medicines']);
      return Visit.fromJson(visitMap);
    });
  }

  // Appointment methods
  Future<void> insertAppointment(Appointment appointment) async {
    final Database db = await database;
    await db.insert(
      'appointments',
      appointment.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Appointment>> getAppointments(String patientId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );
    return List.generate(maps.length, (i) => Appointment.fromJson(maps[i]));
  }

  Future<List<Appointment>> getTodayAppointments() async {
    final Database db = await database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59)
        .toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'appointmentDate BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
    );

    return List.generate(maps.length, (i) => Appointment.fromJson(maps[i]));
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    final Database db = await database;
    await db.update(
      'appointments',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Statistics methods
  Future<Map<String, int>> getQuickStats() async {
    final Database db = await database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59)
        .toIso8601String();

    // Get total patients count
    final patientsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM patients'),
        ) ??
        0;

    // Get today's visits count
    final visitsCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM visits WHERE visitDate BETWEEN ? AND ?',
            [startOfDay, endOfDay],
          ),
        ) ??
        0;

    // Get today's appointments count
    final appointmentsCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM appointments WHERE appointmentDate BETWEEN ? AND ?',
            [startOfDay, endOfDay],
          ),
        ) ??
        0;

    return {
      'patients': patientsCount,
      'todayVisits': visitsCount,
      'todayAppointments': appointmentsCount,
    };
  }

  // Delete methods
  Future<void> deletePatient(String id) async {
    final Database db = await database;
    await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteVisit(String id) async {
    final Database db = await database;
    await db.delete(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update methods
  Future<void> updatePatient(Patient patient) async {
    final Database db = await database;
    await db.update(
      'patients',
      patient.toJson(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<void> updateAppointment(Appointment appointment) async {
    final Database db = await database;
    await db.update(
      'appointments',
      appointment.toJson(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  // Get methods
  Future<List<Visit>> getVisitsForPatient(String patientId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );
    return List.generate(maps.length, (i) {
      final visitMap = Map<String, dynamic>.from(maps[i]);
      visitMap['recommendedTests'] = jsonDecode(visitMap['recommendedTests']);
      visitMap['testResults'] = jsonDecode(visitMap['testResults']);
      visitMap['medicines'] = jsonDecode(visitMap['medicines']);
      return Visit.fromJson(visitMap);
    });
  }

  Future<List<Appointment>> getAppointmentsForPatient(String patientId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'appointments',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );
    return List.generate(maps.length, (i) => Appointment.fromJson(maps[i]));
  }
}
