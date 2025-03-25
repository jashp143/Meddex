import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';
import '../services/import_service.dart';
import '../utils/patient_controller.dart';

class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> {
  final ImportService _importService = ImportService();
  bool _isLoading = false;
  String? _selectedFilePath;
  String _fileName = '';
  ImportResult? _importResult;
  bool _showPreview = false;

  Future<void> _pickFile(String type) async {
    try {
      final XTypeGroup typeGroup = XTypeGroup(
        label: type == 'excel' ? 'Excel files' : 'CSV files',
        extensions: type == 'excel' ? ['xlsx', 'xls'] : ['csv'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: [typeGroup],
      );

      if (file == null) return;

      setState(() {
        _selectedFilePath = file.path;
        _fileName = file.name;
        _importResult = null;
        _showPreview = false;
      });

      await _previewImport();
    } catch (e) {
      _showError('Error selecting file: $e');
    }
  }

  Future<void> _previewImport() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isLoading = true;
      _importResult = null;
    });

    try {
      final result = _fileName.toLowerCase().endsWith('.csv')
          ? await _importService.importFromCSV(_selectedFilePath!)
          : await _importService.importFromExcel(_selectedFilePath!);

      setState(() {
        _importResult = result;
        _showPreview = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error processing file: $e');
    }
  }

  Future<void> _confirmImport() async {
    if (_importResult == null || _importResult!.validPatients.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final patientController =
          Provider.of<PatientController>(context, listen: false);

      for (var patient in _importResult!.validPatients) {
        await patientController.addPatient(patient);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully imported ${_importResult!.successfulRows} patients'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error importing patients: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Patients'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Selection Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select File',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickFile('excel'),
                                  icon: const Icon(Icons.table_chart),
                                  label: const Text('Select Excel File'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickFile('csv'),
                                  icon: const Icon(Icons.description),
                                  label: const Text('Select CSV File'),
                                ),
                              ),
                            ],
                          ),
                          if (_fileName.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text('Selected file: $_fileName'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Import Requirements
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Requirements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Required columns:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...['Name', 'Age', 'Gender', 'Contact Number']
                              .map((field) => Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text('• $field'),
                                  )),
                          const SizedBox(height: 16),
                          const Text(
                            'Optional columns:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...['Email', 'Address'].map(
                            (field) => Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text('• $field'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preview Results
                  if (_showPreview && _importResult != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Import Preview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Total rows: ${_importResult!.totalRows}',
                            ),
                            Text(
                              'Valid patients: ${_importResult!.validPatients.length}',
                              style: const TextStyle(color: Colors.green),
                            ),
                            if (_importResult!.errors.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Errors:',
                                style: TextStyle(color: Colors.red),
                              ),
                              ..._importResult!.errors.map(
                                (error) => Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    '• $error',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (_importResult!.validPatients.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _confirmImport,
                                  child: const Text('Import Patients'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
