import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../models/appointment.dart';
import 'database_helper.dart';

class PatientController extends ChangeNotifier {
  List<Patient> _patients = [];
  List<Appointment> _appointments = [];
  Map<String, List<Visit>> _patientVisits =
      {}; // Map to store visits by patient ID
  bool _isInitialized = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  PatientController() {
    _initializeController();
  }

  // Getter for patients list
  List<Patient> get patients => _patients;

  // Getter for appointments list
  List<Appointment> get appointments => _appointments;

  // Getter for initialization status
  bool get isInitialized => _isInitialized;

  // Initialize the controller
  Future<void> _initializeController() async {
    try {
      await _loadPatients();
      await _loadAppointments();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing PatientController: $e');
      _patients = [];
      _appointments = [];
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Add a new patient to the list
  Future<void> addPatient(Patient patient) async {
    try {
      await _dbHelper.insertPatient(patient);
      await _loadPatients();
    } catch (e) {
      debugPrint('Error adding patient: $e');
      rethrow;
    }
  }

  // Add a visit for a patient
  Future<void> addVisit(String patientId, Visit visit) async {
    try {
      await _dbHelper.insertVisit(visit);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding visit: $e');
      rethrow;
    }
  }

  // Get a patient by ID
  Patient? getPatientById(String id) {
    try {
      return _patients.firstWhere((patient) => patient.id == id);
    } catch (e) {
      debugPrint('Error getting patient by ID: $e');
      return null;
    }
  }

  // Load patients from database
  Future<void> _loadPatients() async {
    try {
      _patients = await _dbHelper.getPatients();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading patients: $e');
      _patients = [];
      notifyListeners();
    }
  }

  // Load appointments from database
  Future<void> _loadAppointments() async {
    try {
      _appointments = await _dbHelper.getTodayAppointments();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      _appointments = [];
      notifyListeners();
    }
  }

  // Get stats
  Future<Map<String, int>> getStats() async {
    try {
      return await _dbHelper.getQuickStats();
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return {'patients': 0, 'todayVisits': 0, 'todayAppointments': 0};
    }
  }

  Future<List<Appointment>> getTodayAppointments() async {
    try {
      return await _dbHelper.getTodayAppointments();
    } catch (e) {
      debugPrint('Error getting today\'s appointments: $e');
      return [];
    }
  }

  // Delete a patient
  Future<bool> deletePatient(String patientId) async {
    try {
      await _dbHelper.deletePatient(patientId);
      _patients.removeWhere((patient) => patient.id == patientId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting patient: $e');
      return false;
    }
  }

  // Delete a visit
  Future<bool> deleteVisit(String visitId) async {
    try {
      await _dbHelper.deleteVisit(visitId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting visit: $e');
      return false;
    }
  }

  // Update patient in database
  Future<void> updatePatient(Patient patient) async {
    try {
      await _dbHelper.updatePatient(patient);
      await _loadPatients();
    } catch (e) {
      debugPrint('Error updating patient: $e');
      rethrow;
    }
  }

  // Add an appointment
  Future<void> addAppointment(Appointment appointment) async {
    try {
      await _dbHelper.insertAppointment(appointment);
      await _loadAppointments();
    } catch (e) {
      debugPrint('Error adding appointment: $e');
      rethrow;
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(String id, String status) async {
    try {
      await _dbHelper.updateAppointmentStatus(id, status);
      await _loadAppointments();
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      rethrow;
    }
  }

  // Update appointment
  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _dbHelper.updateAppointment(appointment);
      await _loadAppointments();
    } catch (e) {
      debugPrint('Error updating appointment: $e');
      rethrow;
    }
  }

  // Get visits for a specific patient
  Future<List<Visit>> getVisitsForPatient(String patientId) async {
    try {
      return await _dbHelper.getVisitsForPatient(patientId);
    } catch (e) {
      debugPrint('Error getting visits for patient: $e');
      return [];
    }
  }

  // Get appointments for a specific patient
  Future<List<Appointment>> getAppointmentsForPatient(String patientId) async {
    try {
      return await _dbHelper.getAppointmentsForPatient(patientId);
    } catch (e) {
      debugPrint('Error getting appointments for patient: $e');
      return [];
    }
  }

  // Load visits for a specific patient
  Future<void> loadVisits(String patientId) async {
    try {
      final visits = await _dbHelper.getVisitsForPatient(patientId);
      _patientVisits[patientId] = visits;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading visits: $e');
      _patientVisits[patientId] = [];
      notifyListeners();
    }
  }

  // Get visits for a specific patient
  List<Visit> getVisits(String patientId) {
    return _patientVisits[patientId] ?? [];
  }
}
