import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../utils/patient_controller.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  List<Visit> _visits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // We'll load visits in didChangeDependencies to get context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    final patient = ModalRoute.of(context)!.settings.arguments as Patient;
    final patientController =
        Provider.of<PatientController>(context, listen: false);

    final visits = await patientController.getVisitsForPatient(patient.id);

    if (mounted) {
      setState(() {
        _visits = visits;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the patient from route arguments
    final patient = ModalRoute.of(context)!.settings.arguments as Patient;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          patient.name,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Visits',
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadVisits();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen
              Navigator.pushNamed(
                context,
                '/patient/edit',
                arguments: patient,
              ).then((_) => _loadVisits());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVisits,
        child: Column(
          children: [
            _buildPatientInfo(context, patient),
            const SizedBox(height: 16),
            _buildVisitListHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _visits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No visits recorded yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a new visit using the button below',
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
                      : _buildVisitsList(_visits),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add visit screen and refresh when returning
          Navigator.pushNamed(
            context,
            '/visit/add',
            arguments: patient,
          ).then((_) => _loadVisits());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Visit'),
        tooltip: 'Add New Visit',
      ),
    );
  }

  Widget _buildPatientInfo(BuildContext context, Patient patient) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'patient-avatar-${patient.id}',
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      patient.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${patient.age} years, ${patient.gender}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.phone, 'Contact', patient.contactNumber),
            if (patient.email != null)
              _buildInfoRow(Icons.email, 'Email', patient.email!),
            if (patient.address != null)
              _buildInfoRow(Icons.home, 'Address', patient.address!),
            _buildInfoRow(
              Icons.calendar_today,
              'Registered',
              '${patient.registrationDate.day}/${patient.registrationDate.month}/${patient.registrationDate.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildVisitListHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Visit History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextButton.icon(
            icon: const Icon(Icons.filter_list),
            label: const Text('Filter'),
            onPressed: () {
              // Implement filter functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsList(List<Visit> visits) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.medical_services,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              'Visit on ${visit.visitDate.day}/${visit.visitDate.month}/${visit.visitDate.year}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Treatment: ${visit.currentTreatmentPlan}'),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVisitDetail('Prescription', visit.prescription),
              _buildVisitDetail('Tests', visit.recommendedTests.join(', ')),
              const SizedBox(height: 8),

              // Medications section
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medication,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Medications',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...visit.medicines.map((medicine) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(
                                child: Text(
                                  '${medicine.name}: ${medicine.dosage} - ${medicine.duration}',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (visit.medicines.isEmpty)
                        Text(
                          'No medications prescribed',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Instructions
              if (visit.instructions.isNotEmpty) ...[
                _buildVisitDetail('Instructions', visit.instructions),
                const SizedBox(height: 8),
              ],

              if (visit.followUpDate != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Follow-up on ${visit.followUpDate!.day}/${visit.followUpDate!.month}/${visit.followUpDate!.year}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              const Divider(),
              const SizedBox(height: 8),

              // Payment details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        visit.paymentMode,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${visit.totalBill.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (visit.pendingAmount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Pending: ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${visit.pendingAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print'),
                    onPressed: () {
                      // Implement print functionality
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Visit'),
                    onPressed: () {
                      // Implement edit functionality
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisitDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
