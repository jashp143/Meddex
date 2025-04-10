import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:ui';
import '../models/patient.dart';
import '../models/visit.dart';
import '../utils/patient_controller.dart';
import '../utils/storage_helper.dart';
import '../widgets/custom_text_field.dart';
import 'package:flutter/rendering.dart';

class AddVisitScreen extends StatefulWidget {
  const AddVisitScreen({super.key});

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _testsController = TextEditingController();
  final _feeController = TextEditingController();
  final _pendingController = TextEditingController();
  final _totalController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _currentTreatmentController = TextEditingController();
  final _medicineController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _pendingAmountController = TextEditingController();
  final _totalBillController = TextEditingController();

  DateTime _visitDate = DateTime.now();
  DateTime _followUpDate = DateTime.now();
  String _selectedPaymentMode = 'Cash';
  final List<Medicine> _medicines = [];
  final List<TestResult> _testResults = [];
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
    _testsController.dispose();
    _feeController.dispose();
    _pendingController.dispose();
    _totalController.dispose();
    _doctorNameController.dispose();
    _prescriptionController.dispose();
    _currentTreatmentController.dispose();
    _medicineController.dispose();
    _instructionsController.dispose();
    _consultationFeeController.dispose();
    _pendingAmountController.dispose();
    _totalBillController.dispose();
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

      // Parse recommended tests
      final recommendedTests = _testsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Create a new visit
      final visit = Visit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: patient.id,
        visitDate: _visitDate,
        prescription: '', // Empty as requested
        recommendedTests: recommendedTests,
        testResults: _testResults,
        followUpDate: _followUpDate,
        currentTreatmentPlan: '', // Empty as requested
        medicines: medicines,
        instructions: '', // Empty as requested
        consultationFee: double.parse(_feeController.text),
        pendingAmount: double.parse(_pendingController.text),
        totalBill: double.parse(_totalController.text),
        paymentMode: _selectedPaymentMode,
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
        title: const Text('Add Visit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: FadeTransition(
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
                            Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
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
                    _buildGlassCard(
                      child: CustomTextField(
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
                    ),

                    const SizedBox(height: 24),

                    // Follow Up Date
                    _buildGlassCard(
                      child: CustomTextField(
                        controller: TextEditingController(
                          text: formatDate(_followUpDate),
                        ),
                        label: 'Follow-up Date',
                        prefixIcon: Icons.event,
                        readOnly: true,
                        isDateField: true,
                        selectedDate: _followUpDate,
                        onDateSelected: (date) {
                          setState(() {
                            _followUpDate = date;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Medicines section
                    _buildGlassCard(
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
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
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
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 200,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: _medicines.length,
                                itemBuilder: (context, index) {
                                  final medicine = _medicines[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${medicine.dosage} - ${medicine.duration}',
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
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
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Test Results Section
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tests',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Common tests section
                          Text(
                            'Common Tests:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Chips for quick selection of common tests
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTestChip('CBC'),
                              _buildTestChip('Blood Glucose'),
                              _buildTestChip('Lipid Panel'),
                              _buildTestChip('HbA1c'),
                              _buildTestChip('Liver Function'),
                              _buildTestChip('Kidney Function'),
                              _buildTestChip('Thyroid Panel'),
                              _buildTestChip('Urine Analysis'),
                              _buildTestChip('ECG'),
                              _buildTestChip('X-Ray'),
                              _buildTestChip('USG'),
                              _buildTestChip('CT Scan'),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Recommended Tests
                          CustomTextField(
                            controller: _testsController,
                            label: 'Recommended Tests (comma separated)',
                            prefixIcon: Icons.science,
                          ),
                          const SizedBox(height: 16),

                          // Show current results
                          if (_testResults.isNotEmpty) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_turned_in,
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Recorded Results',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _testResults.length,
                                  itemBuilder: (context, index) {
                                    final result = _testResults[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          if (result.filePath != null) {
                                            _viewPdf(result.filePath!);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: result.filePath != null
                                                      ? Colors.blue
                                                          .withOpacity(0.1)
                                                      : Colors.green
                                                          .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  result.filePath != null
                                                      ? Icons.picture_as_pdf
                                                      : Icons.science,
                                                  color: result.filePath != null
                                                      ? Colors.blue
                                                      : Colors.green,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      result.testName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      result.result,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.5),
                                                ),
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.edit,
                                                            size: 20),
                                                        const SizedBox(
                                                            width: 8),
                                                        const Text(
                                                            'Edit Result'),
                                                      ],
                                                    ),
                                                  ),
                                                  if (result.filePath == null)
                                                    PopupMenuItem(
                                                      value: 'upload',
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.upload_file,
                                                              size: 20),
                                                          const SizedBox(
                                                              width: 8),
                                                          const Text(
                                                              'Upload PDF'),
                                                        ],
                                                      ),
                                                    ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete,
                                                          size: 20,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .error,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                onSelected: (value) {
                                                  switch (value) {
                                                    case 'edit':
                                                      _addTestResult(
                                                          result.testName);
                                                      break;
                                                    case 'upload':
                                                      _pickResultFile(
                                                          result.testName,
                                                          _testResults
                                                              .indexOf(result));
                                                      break;
                                                    case 'delete':
                                                      setState(() {
                                                        _testResults
                                                            .removeAt(index);
                                                      });
                                                      break;
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(),
                          ],

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Add Results Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Results for Selected Tests',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Builder(builder: (context) {
                                // Get list of recommended tests from text field
                                final recommendedTests = _testsController.text
                                    .split(',')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();

                                if (recommendedTests.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Select tests from the list above to add their results. You can either enter results manually or upload PDF reports.',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select a test to add its result:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: recommendedTests.map((test) {
                                        final hasResult = _testResults
                                            .any((r) => r.testName == test);
                                        final hasPdf = _testResults.any((r) =>
                                            r.testName == test &&
                                            r.filePath != null);

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: hasResult
                                                ? (hasPdf
                                                    ? Colors.blue
                                                        .withOpacity(0.1)
                                                    : Colors.green
                                                        .withOpacity(0.1))
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceVariant
                                                    .withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: hasResult
                                                  ? (hasPdf
                                                      ? Colors.blue
                                                          .withOpacity(0.3)
                                                      : Colors.green
                                                          .withOpacity(0.3))
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .outline
                                                      .withOpacity(0.2),
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                      top: Radius.circular(16),
                                                    ),
                                                  ),
                                                  builder: (context) => Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.science,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text(
                                                              test,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const Divider(),
                                                      ListTile(
                                                        leading: const Icon(
                                                            Icons.note_add),
                                                        title: const Text(
                                                            'Enter Result Manually'),
                                                        subtitle: const Text(
                                                            'Add test result values'),
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                          _addTestResult(test);
                                                        },
                                                      ),
                                                      ListTile(
                                                        leading: const Icon(
                                                            Icons.upload_file),
                                                        title: const Text(
                                                            'Upload PDF Report'),
                                                        subtitle: const Text(
                                                            'Attach test report document'),
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                          _pickResultFile(
                                                              test, -1);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      hasResult
                                                          ? (hasPdf
                                                              ? Icons
                                                                  .picture_as_pdf
                                                              : Icons
                                                                  .check_circle)
                                                          : Icons
                                                              .add_circle_outline,
                                                      size: 16,
                                                      color: hasResult
                                                          ? (hasPdf
                                                              ? Colors.blue
                                                              : Colors.green)
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      test,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: hasResult
                                                            ? (hasPdf
                                                                ? Colors.blue
                                                                : Colors.green)
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Add custom test and result
                          ElevatedButton.icon(
                            onPressed: () {
                              // Show dialog to add custom test and result
                              showDialog(
                                context: context,
                                builder: (context) {
                                  final testNameController =
                                      TextEditingController();
                                  final resultController =
                                      TextEditingController();

                                  return AlertDialog(
                                    title: const Text('Add Custom Test Result'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: testNameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Test Name',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: resultController,
                                            decoration: const InputDecoration(
                                              labelText: 'Result Value',
                                              border: OutlineInputBorder(),
                                            ),
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (testNameController
                                              .text.isNotEmpty) {
                                            // Add to recommended tests if not already there
                                            final currentTests =
                                                _testsController.text.trim();
                                            final testsList = currentTests
                                                    .isEmpty
                                                ? []
                                                : currentTests
                                                    .split(',')
                                                    .map((e) => e.trim())
                                                    .where((e) => e.isNotEmpty)
                                                    .toList();

                                            if (!testsList.contains(
                                                testNameController.text)) {
                                              if (currentTests.isEmpty) {
                                                _testsController.text =
                                                    testNameController.text;
                                              } else {
                                                _testsController.text =
                                                    '$currentTests, ${testNameController.text}';
                                              }
                                            }

                                            // Add the result
                                            setState(() {
                                              _testResults.add(TestResult(
                                                testName:
                                                    testNameController.text,
                                                result: resultController
                                                        .text.isNotEmpty
                                                    ? resultController.text
                                                    : 'No value entered',
                                                filePath: null,
                                              ));
                                            });

                                            Navigator.pop(context);
                                          }
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.add_chart),
                            label: const Text('Add Custom Test Result'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Financial Information
                    _buildGlassCard(
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
                                  value: _selectedPaymentMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment Mode',
                                    prefixIcon: Icon(Icons.payment),
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                  items: [
                                    'Cash',
                                    'UPI',
                                  ].map((mode) {
                                    return DropdownMenuItem(
                                      value: mode,
                                      child: Text(mode),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedPaymentMode = value;
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
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTestChip(String label) {
    final hasResult = _testResults.any((r) => r.testName == label);
    final hasPdf =
        _testResults.any((r) => r.testName == label && r.filePath != null);

    return Container(
      decoration: BoxDecoration(
        color: hasResult
            ? (hasPdf
                ? Colors.blue.withOpacity(0.1)
                : Colors.green.withOpacity(0.1))
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasResult
              ? (hasPdf
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3))
              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // First add the test to the recommended tests list
            final currentTests = _testsController.text.trim();
            if (currentTests.isEmpty) {
              _testsController.text = label;
            } else {
              final testsList = currentTests
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              if (!testsList.contains(label)) {
                _testsController.text = '$currentTests, $label';
              }
            }

            // Then show the bottom sheet to add results
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.science,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.note_add),
                    title: const Text('Enter Result Manually'),
                    subtitle: const Text('Add test result values'),
                    onTap: () {
                      Navigator.pop(context);
                      _addTestResult(label);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Upload PDF Report'),
                    subtitle: const Text('Attach test report document'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickResultFile(label, -1);
                    },
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasResult
                      ? (hasPdf ? Icons.picture_as_pdf : Icons.check_circle)
                      : Icons.science,
                  size: 16,
                  color: hasResult
                      ? (hasPdf ? Colors.blue : Colors.green)
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasResult
                        ? (hasPdf ? Colors.blue : Colors.green)
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pick a PDF file from the filesystem
  Future<void> _pickResultFile(String testName, int existingIndex) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final newResult = TestResult(
        testName: testName,
        result: '', // Empty string instead of null
        filePath: result.files.single.path!,
        resultDate: DateTime.now(),
      );

      if (!newResult.isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a valid PDF file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        if (existingIndex >= 0) {
          // Update existing result
          _testResults[existingIndex] = newResult;
        } else {
          // Add new result
          _testResults.add(newResult);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF report for $testName uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // View a PDF file
  Future<void> _viewPdf(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add or update test result manually
  void _addTestResult(String testName) {
    // Check if test already has a result
    final existingIndex =
        _testResults.indexWhere((r) => r.testName == testName);
    if (existingIndex >= 0) {
      // Show confirmation dialog
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace Existing Result?'),
          content: Text(
            'This test already has a result. Do you want to replace it with a new value?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      ).then((shouldReplace) {
        if (shouldReplace == true) {
          _showResultInputDialog(testName, existingIndex);
        }
      });
    } else {
      _showResultInputDialog(testName, -1);
    }
  }

  void _showResultInputDialog(String testName, int existingIndex) {
    final resultController = TextEditingController();
    if (existingIndex >= 0) {
      resultController.text = _testResults[existingIndex].result;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Result for $testName'),
        content: TextField(
          controller: resultController,
          decoration: const InputDecoration(
            hintText: 'Enter test result value',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _saveTestResult(testName, value, existingIndex);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (resultController.text.isNotEmpty) {
                _saveTestResult(testName, resultController.text, existingIndex);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveTestResult(String testName, String result, int existingIndex) {
    final newResult = TestResult(
      testName: testName,
      result: result,
      filePath: null, // Clear any existing PDF
      resultDate: DateTime.now(),
    );

    if (!newResult.isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid test result'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      if (existingIndex >= 0) {
        // Update existing result
        _testResults[existingIndex] = newResult;
      } else {
        // Add new result
        _testResults.add(newResult);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Result for $testName saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Helper method to format date as DD/MM/YYYY with padding for single digit days/months
  String formatDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
