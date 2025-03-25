import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';

import '../utils/storage_helper.dart';
import '../utils/theme_controller.dart';
import '../utils/database_helper.dart';
import '../screens/import_data_screen.dart';
import '../services/export_service.dart';
import '../utils/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class ExportOptions {
  final String format;
  final bool compress;
  final bool background;
  final DateTime? startDate;
  final DateTime? endDate;

  ExportOptions({
    required this.format,
    this.compress = false,
    this.background = false,
    this.startDate,
    this.endDate,
  });
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageHelper _storageHelper = StorageHelper();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String _databasePath = '';
  bool _isLoading = true;
  String _message = '';
  bool _showMessage = false;
  List<Map<String, dynamic>> _debugVisits = [];
  bool _loadingVisits = false;
  Map<String, List<Map<String, dynamic>>> _dbInfo = {};
  bool _loadingDbInfo = false;
  bool _isExporting = false;
  bool _showExportProgress = false;
  double _exportProgress = 0.0;
  String _exportStep = '';

  @override
  void initState() {
    super.initState();
    _loadDatabasePath();
  }

  Future<void> _loadDatabasePath() async {
    final path = await _storageHelper.getDatabasePath();
    if (mounted) {
      setState(() {
        _databasePath = path;
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showExportDialog() async {
    final options = await showDialog<ExportOptions>(
      context: context,
      builder: (BuildContext context) {
        return _ExportOptionsDialog();
      },
    );

    if (options != null) {
      await _exportDatabase(options);
    }
  }

  Future<void> _exportDatabase(ExportOptions options) async {
    setState(() {
      _isExporting = true;
      _showExportProgress = true;
      _exportProgress = 0.0;
      _exportStep = 'Preparing export...';
    });

    try {
      // Get all patients data
      final db = await _databaseHelper.database;
      final patients = await db.query('patients');

      void updateProgress(ExportProgress progress) {
        if (mounted) {
          setState(() {
            _exportProgress = progress.progress;
            _exportStep = progress.currentStep;
          });
        }
      }

      ExportResult result;
      switch (options.format.toLowerCase()) {
        case 'excel':
          result = await ExportService.exportToExcel(
            patients,
            onProgress: updateProgress,
            compress: options.compress,
            background: options.background,
          );
          break;
        case 'csv':
          result = await ExportService.exportToCSV(
            patients,
            onProgress: updateProgress,
            compress: options.compress,
            background: options.background,
          );
          break;
        case 'pdf':
          result = await ExportService.exportToPDF(
            patients,
            onProgress: updateProgress,
            compress: options.compress,
            background: options.background,
          );
          break;
        default:
          throw 'Unsupported format: ${options.format}';
      }

      if (!mounted) return;

      if (result.success) {
        String message = 'Export successful: ${result.filePath}';
        if (result.compressedFilePath != null) {
          message += '\nCompressed file: ${result.compressedFilePath}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Logger.error('Export failed: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _showExportProgress = false;
        });
      }
    }
  }

  Future<void> _importDatabase() async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'SQLite Database',
            extensions: ['db'],
          ),
        ],
      );

      if (file == null) {
        _showSnackBar('No file selected', true);
        return;
      }

      final String path = file.path;
      final bool success = await _storageHelper.importDatabase(path);

      if (success) {
        _showSnackBar('Database imported successfully', false);
      } else {
        _showSnackBar('Failed to import database', true);
      }
    } catch (e) {
      _showSnackBar('Error during import: $e', true);
    }
  }

  Future<void> _debugDatabaseVisits() async {
    setState(() {
      _loadingVisits = true;
      _debugVisits = [];
    });

    try {
      // Open the database directly for raw queries
      final db = await _databaseHelper.database;

      // Get all visits
      final List<Map<String, dynamic>> visitMaps = await db.query(
        'visits',
        orderBy: 'visitDate DESC',
      );

      if (visitMaps.isEmpty) {
        setState(() {
          _message = 'No visits found in database';
          _showMessage = true;
          _loadingVisits = false;
        });
        return;
      }

      // Add raw visit data for debugging
      setState(() {
        _debugVisits = visitMaps;
        _loadingVisits = false;
        _message = 'Found ${visitMaps.length} visits';
        _showMessage = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Error querying database: $e';
        _showMessage = true;
        _loadingVisits = false;
      });
    }
  }

  Future<void> _examineDatabase() async {
    setState(() {
      _loadingDbInfo = true;
      _dbInfo = {};
    });

    try {
      // Open the database directly for raw queries
      final db = await _databaseHelper.database;

      // Get table names
      final tableInfoResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'");

      final tableNames =
          tableInfoResult.map((row) => row['name'] as String).toList();

      // Get data from each table
      for (final tableName in tableNames) {
        final tableData = await db.query(tableName, limit: 10);
        _dbInfo[tableName] = tableData;
      }

      setState(() {
        _loadingDbInfo = false;
        _message = 'Database examined successfully';
        _showMessage = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Error examining database: $e';
        _showMessage = true;
        _loadingDbInfo = false;
      });
    }
  }

  Future<void> _resetDatabase() async {
    try {
      // Open the database directly for raw queries
      final db = await _databaseHelper.database;

      // Ask for confirmation
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Database'),
              content: const Text(
                  'This will clear all visits in the database. Patient data will be preserved. This action cannot be undone. Are you sure?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;

      // Delete all data from visits and medicines tables
      await db.delete('visits');
      await db.delete('medicines');

      setState(() {
        _message = 'Database visits reset successful';
        _showMessage = true;
        _debugVisits = [];
        _dbInfo = {};
      });

      _showSnackBar('Database visits reset complete', false);
    } catch (e) {
      setState(() {
        _message = 'Error resetting database: $e';
        _showMessage = true;
      });
      _showSnackBar('Error resetting database: $e', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme settings
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            value: isDarkMode,
                            onChanged: (value) {
                              themeController.setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Database settings
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Database',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: const Text('Database Location'),
                            subtitle: Text(_databasePath),
                            leading: const Icon(Icons.folder),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('Export Database'),
                            subtitle: const Text(
                                'Export patient data to Excel, CSV, or PDF'),
                            leading: const Icon(Icons.upload),
                            trailing: _isExporting
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.arrow_forward_ios),
                            onTap: _isExporting ? null : _showExportDialog,
                          ),
                          if (_showExportProgress)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _exportStep,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: _exportProgress,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(_exportProgress * 100).toStringAsFixed(1)}%',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ListTile(
                            leading: const Icon(Icons.file_download),
                            title: const Text('Import Database'),
                            onTap: _importDatabase,
                          ),
                          ListTile(
                            leading: const Icon(Icons.upload_file),
                            title: const Text('Import Patient Data'),
                            subtitle: const Text(
                                'Import patients from Excel or CSV files'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ImportDataScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Debug section
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debug',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: const Text('Check Visits Data'),
                            subtitle: const Text(
                                'Debug visit records in the database'),
                            leading: const Icon(Icons.bug_report),
                            onTap: _debugDatabaseVisits,
                          ),
                          ListTile(
                            title: const Text('Examine Database Structure'),
                            subtitle: const Text(
                                'View tables and records in the database'),
                            leading: const Icon(Icons.data_usage),
                            onTap: _examineDatabase,
                          ),
                          ListTile(
                            title: const Text('Reset Visits Data'),
                            subtitle: const Text(
                                'Delete all visits data (debugging)'),
                            leading: const Icon(Icons.delete_forever),
                            onTap: _resetDatabase,
                          ),
                          if (_showMessage)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _message,
                                style: TextStyle(
                                  color: _message.contains('Error')
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ),
                          if (_loadingVisits)
                            const Center(child: CircularProgressIndicator())
                          else if (_debugVisits.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              height: 300,
                              child: ListView.builder(
                                itemCount: _debugVisits.length,
                                itemBuilder: (context, index) {
                                  final visit = _debugVisits[index];
                                  return ExpansionTile(
                                    title: Text('Visit ID: ${visit['id']}'),
                                    subtitle: Text(
                                        'Patient ID: ${visit['patientId']}'),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Visit Date: ${visit['visitDate']}'),
                                            Text(
                                                'Tests: ${visit['recommendedTests']}'),
                                            Text(
                                                'Results: ${visit['testResults']}'),
                                            Text(
                                                'Treatment: ${visit['currentTreatmentPlan']}'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          // Database info examination results
                          if (_loadingDbInfo)
                            const Center(child: CircularProgressIndicator())
                          else if (_dbInfo.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              height: 400,
                              child: SingleChildScrollView(
                                child: ExpansionPanelList.radio(
                                  elevation: 1,
                                  children: _dbInfo.entries.map((entry) {
                                    return ExpansionPanelRadio(
                                      value: entry.key,
                                      headerBuilder: (context, isExpanded) {
                                        return ListTile(
                                          title: Text(
                                            'Table: ${entry.key}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                              '${entry.value.length} records shown'),
                                        );
                                      },
                                      body: entry.value.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child:
                                                  Text('No data in this table'),
                                            )
                                          : Column(
                                              children:
                                                  entry.value.map((record) {
                                                return Card(
                                                  margin:
                                                      const EdgeInsets.all(8),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: record.entries
                                                          .map((field) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 4),
                                                          child: RichText(
                                                            text: TextSpan(
                                                              style: DefaultTextStyle
                                                                      .of(context)
                                                                  .style,
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      '${field.key}: ',
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      '${field.value ?? "null"}',
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ExportOptionsDialog extends StatefulWidget {
  @override
  _ExportOptionsDialogState createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<_ExportOptionsDialog> {
  String _selectedFormat = 'excel';
  bool _compress = false;
  bool _background = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Format'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'excel',
                  label: Text('Excel'),
                  icon: Icon(Icons.table_chart),
                ),
                ButtonSegment(
                  value: 'csv',
                  label: Text('CSV'),
                  icon: Icon(Icons.description),
                ),
                ButtonSegment(
                  value: 'pdf',
                  label: Text('PDF'),
                  icon: Icon(Icons.picture_as_pdf),
                ),
              ],
              selected: {_selectedFormat},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedFormat = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Compress Output'),
              subtitle: const Text('Create a compressed archive'),
              value: _compress,
              onChanged: (bool value) {
                setState(() {
                  _compress = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Background Export'),
              subtitle: const Text('Process in background'),
              value: _background,
              onChanged: (bool value) {
                setState(() {
                  _background = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Date Range (Optional)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate == null
                        ? 'Start Date'
                        : DateFormat('MM/dd/yyyy').format(_startDate!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate == null
                        ? 'End Date'
                        : DateFormat('MM/dd/yyyy').format(_endDate!)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              ExportOptions(
                format: _selectedFormat,
                compress: _compress,
                background: _background,
                startDate: _startDate,
                endDate: _endDate,
              ),
            );
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}
