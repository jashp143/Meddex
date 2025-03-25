import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../utils/patient_controller.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _isLoading = true;
  List<Appointment> _appointments = [];
  List<Patient> _patients = [];
  List<Visit> _visitsWithFollowUp = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final patientController =
        Provider.of<PatientController>(context, listen: false);
    _patients = patientController.patients;

    // Get all visits with follow-up dates
    _visitsWithFollowUp = [];
    for (var patient in _patients) {
      final visits = await patientController.getVisitsForPatient(patient.id);
      _visitsWithFollowUp.addAll(
        visits.where((visit) =>
            visit.followUpDate != null &&
            visit.followUpDate!.isAfter(DateTime.now())),
      );
    }

    // Create appointments from follow-up dates if they don't exist
    for (var visit in _visitsWithFollowUp) {
      if (visit.followUpDate != null) {
        // Get existing appointments for this patient
        final patientAppointments =
            await patientController.getAppointmentsForPatient(visit.patientId);

        // Check if an appointment already exists for this follow-up date
        final hasExistingAppointment = patientAppointments.any((appointment) =>
            appointment.appointmentDate.day == visit.followUpDate!.day &&
            appointment.appointmentDate.month == visit.followUpDate!.month &&
            appointment.appointmentDate.year == visit.followUpDate!.year);

        if (!hasExistingAppointment) {
          final appointment = Appointment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            patientId: visit.patientId,
            appointmentDate: visit.followUpDate!,
            purpose: 'Follow-up visit',
            status: 'scheduled',
            notes:
                'Follow-up for visit on ${visit.visitDate.day}/${visit.visitDate.month}/${visit.visitDate.year}',
            isFollowUp: true,
          );

          await patientController.addAppointment(appointment);
        }
      }
    }

    // Load all appointments for all patients
    List<Appointment> allAppointments = [];
    for (var patient in _patients) {
      final appointments =
          await patientController.getAppointmentsForPatient(patient.id);
      allAppointments.addAll(appointments);
    }

    // Filter to show only upcoming appointments
    final now = DateTime.now();
    _appointments = allAppointments
        .where((appointment) => appointment.appointmentDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up Appointments'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No follow-up appointments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Follow-up appointments will appear here\nwhen scheduled during visits',
                        textAlign: TextAlign.center,
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
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    final patient = _patients.firstWhere(
                      (p) => p.id == appointment.patientId,
                      orElse: () => Patient(
                        id: '',
                        name: 'Unknown Patient',
                        age: 0,
                        gender: '',
                        contactNumber: '',
                        registrationDate: DateTime.now(),
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: appointment.isFollowUp
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                          child: Icon(
                            appointment.isFollowUp
                                ? Icons.repeat
                                : Icons.calendar_today,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        title: Text(patient.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(appointment.purpose),
                            if (appointment.notes != null &&
                                appointment.notes!.isNotEmpty)
                              Text(
                                appointment.notes!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.check_circle_outline,
                            color: appointment.status == 'completed'
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () async {
                            final controller = Provider.of<PatientController>(
                                context,
                                listen: false);
                            await controller.updateAppointmentStatus(
                                appointment.id, 'completed');
                            _loadData();
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
