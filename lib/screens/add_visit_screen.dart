import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../utils/patient_controller.dart';
import '../widgets/custom_text_field.dart';

class AddVisitScreen extends StatefulWidget {
  const AddVisitScreen({super.key});

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _prescriptionController = TextEditingController();
  final _testsController = TextEditingController();
  final _treatmentPlanController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _feeController = TextEditingController();
  final _pendingController = TextEditingController();
  final _totalController = TextEditingController();

  DateTime _visitDate = DateTime.now();
  DateTime? _followUpDate;
  String _paymentMode = 'Cash';
  final List<Medicine> _medicines = [];
  bool _isSubmitting = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _prescriptionController.dispose();
    _testsController.dispose();
    _treatmentPlanController.dispose();
    _instructionsController.dispose();
    _feeController.dispose();
    _pendingController.dispose();
    _totalController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addMedicine() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final dosageController = TextEditingController();
        final durationController = TextEditingController();

        return AlertDialog(
          title: const Text(
            'Add Medicine',
            style: TextStyle(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  labelStyle: TextStyle(fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  labelStyle: TextStyle(fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  labelStyle: TextStyle(fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    dosageController.text.isNotEmpty &&
                    durationController.text.isNotEmpty) {
                  setState(() {
                    _medicines.add(
                      Medicine(
                        name: nameController.text,
                        dosage: dosageController.text,
                        duration: durationController.text,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveVisit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Get the patient from arguments
      final patient = ModalRoute.of(context)!.settings.arguments as Patient;

      // Format the medicines list
      final medicines = _medicines.asMap().entries.map((entry) {
        final medicine = entry.value;

        return Medicine(
          name: medicine.name,
          dosage: medicine.dosage,
          duration: medicine.duration,
        );
      }).toList();

      // Debug: Print tests input
      print('Tests input: ${_testsController.text}');

      // Parse recommended tests
      final recommendedTests = _testsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Debug: Print parsed tests
      print('Parsed tests: $recommendedTests');

      // Create a new visit
      final visit = Visit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: patient.id,
        visitDate: _visitDate,
        prescription: _prescriptionController.text,
        recommendedTests: recommendedTests,
        testResults: {},
        followUpDate: _followUpDate,
        currentTreatmentPlan: _treatmentPlanController.text,
        medicines: medicines,
        instructions: _instructionsController.text,
        consultationFee: double.parse(_feeController.text),
        pendingAmount: double.parse(_pendingController.text),
        totalBill: double.parse(_totalController.text),
        paymentMode: _paymentMode,
      );

      // Save the visit using PatientController
      final patientController =
          Provider.of<PatientController>(context, listen: false);
      patientController.addVisit(patient.id, visit);

      // Close the screen and return true to indicate a successful addition
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Visit',
          style: TextStyle(fontSize: 18),
        ),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.7),
                          Theme.of(context).colorScheme.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Visit Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record patient consultation information',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Visit Date
                  CustomTextField(
                    controller: TextEditingController(
                      text:
                          '${_visitDate.day}/${_visitDate.month}/${_visitDate.year}',
                    ),
                    label: 'Visit Date',
                    prefixIcon: Icons.calendar_today,
                    readOnly: true,
                    isDateField: true,
                    selectedDate: _visitDate,
                    onDateSelected: (date) {
                      setState(() {
                        _visitDate = date;
                      });
                    },
                  ),

                  // Prescription
                  CustomTextField(
                    controller: _prescriptionController,
                    label: 'Prescription',
                    prefixIcon: Icons.description,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter prescription details';
                      }
                      return null;
                    },
                  ),

                  // Recommended Tests
                  CustomTextField(
                    controller: _testsController,
                    label: 'Recommended Tests (comma separated)',
                    prefixIcon: Icons.science,
                  ),

                  // Treatment Plan
                  CustomTextField(
                    controller: _treatmentPlanController,
                    label: 'Current Treatment Plan',
                    prefixIcon: Icons.medical_services,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter treatment plan';
                      }
                      return null;
                    },
                  ),

                  // Follow Up Date
                  CustomTextField(
                    controller: TextEditingController(
                      text: _followUpDate != null
                          ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                          : '',
                    ),
                    label: 'Follow-up Date (Optional)',
                    prefixIcon: Icons.event,
                    readOnly: true,
                    isDateField: true,
                    selectedDate: _followUpDate ?? DateTime.now(),
                    onDateSelected: (date) {
                      setState(() {
                        _followUpDate = date;
                      });
                    },
                  ),

                  // Medicines section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Medicines',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addMedicine,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Add Medicine',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_medicines.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'No medicines added yet. Click the button above to add medicine details.',
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _medicines.length,
                              itemBuilder: (context, index) {
                                final medicine = _medicines[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      child: Icon(
                                        Icons.medication,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    title: Text(
                                      medicine.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${medicine.dosage} - ${medicine.duration}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        size: 20,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _medicines.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 16),

                          // Instructions
                          CustomTextField(
                            controller: _instructionsController,
                            label: 'Instructions for Medicine Usage',
                            prefixIcon: Icons.info,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Financial Information
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _feeController,
                                  label: 'Consultation Fee',
                                  prefixIcon: Icons.attach_money,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  controller: _pendingController,
                                  label: 'Pending Amount',
                                  prefixIcon: Icons.payment,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _totalController,
                                  label: 'Total Bill',
                                  prefixIcon: Icons.receipt,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter total bill';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _paymentMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Mode',
                                    prefixIcon: Icon(Icons.payment),
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                  items: [
                                    'Cash',
                                    'Credit Card',
                                    'Debit Card',
                                    'UPI',
                                    'Insurance'
                                  ].map((mode) {
                                    return DropdownMenuItem(
                                      value: mode,
                                      child: Text(mode),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _paymentMode = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveVisit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text('Save Visit'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
