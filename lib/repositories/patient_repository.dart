import '../models/patient.dart';
import '../services/database_service.dart';
import 'base_repository.dart';
import 'package:sqflite/sqflite.dart';

class PatientRepository implements BaseRepository<Patient> {
  final DatabaseService<Patient> _databaseService;

  PatientRepository(Database database)
      : _databaseService = DatabaseService<Patient>(
          database: database,
          tableName: 'patients',
          fromMap: Patient.fromMap,
        );

  @override
  Future<void> insert(Patient patient) => _databaseService.insert(patient);

  @override
  Future<void> update(Patient patient) => _databaseService.update(patient);

  @override
  Future<void> delete(String id) => _databaseService.delete(id);

  @override
  Future<Patient?> getById(String id) => _databaseService.getById(id);

  @override
  Future<List<Patient>> getAll() => _databaseService.getAll();

  @override
  Future<void> deleteAll() => _databaseService.deleteAll();

  Future<List<Patient>> searchPatients(String query) async {
    final searchTerm = '%$query%';
    return _databaseService.query(
      where: 'name LIKE ? OR contactNumber LIKE ? OR email LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm],
    );
  }

  Future<int> getTotalPatients() => _databaseService.count();

  Future<List<Patient>> getPatientsWithAppointments() async {
    return _databaseService.query(
      where: 'id IN (SELECT DISTINCT patientId FROM appointments)',
    );
  }
}
