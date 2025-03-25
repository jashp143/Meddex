import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../utils/patient_controller.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  bool _isLoading = true;
  List<Patient> _patients = [];
  String _sortBy = 'name'; // Default sort by name

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    final patientController =
        Provider.of<PatientController>(context, listen: false);

    // Wait for the patient controller to be initialized
    if (!patientController.isInitialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return !patientController.isInitialized;
      });
    }

    // Get all patients from controller
    List<Patient> patients = patientController.patients;

    // Sort patients based on selection
    patients = _sortPatients(patients);

    if (mounted) {
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    }
  }

  List<Patient> _sortPatients(List<Patient> patients) {
    List<Patient> sortedPatients = [
      ...patients
    ]; // Create a copy to avoid modifying the original

    switch (_sortBy) {
      case 'name':
        sortedPatients.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'date':
        sortedPatients
            .sort((a, b) => b.registrationDate.compareTo(a.registrationDate));
        break;
      case 'age':
        sortedPatients.sort((a, b) => a.age.compareTo(b.age));
        break;
    }

    return sortedPatients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search patients',
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort patients',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _patients = _sortPatients(_patients);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Registration Date'),
              ),
              const PopupMenuItem(
                value: 'age',
                child: Text('Sort by Age'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatients,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _patients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No patients registered yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first patient using the + button',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      final patient = _patients[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/patient/detail',
                              arguments: patient,
                            ).then((_) => _loadPatients()); // Refresh on return
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'patient-avatar-${patient.id}',
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      patient.name
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patient.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Age: ${patient.age} • Gender: ${patient.gender}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            patient.contactNumber,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.chevron_right,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/patient/detail',
                                      arguments: patient,
                                    ).then((_) =>
                                        _loadPatients()); // Refresh on return
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/patient/add')
              .then((_) => _loadPatients()); // Refresh on return
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
