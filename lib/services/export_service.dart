import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:archive/archive.dart';
import '../utils/logger.dart';

class ExportProgress {
  final int totalItems;
  final int processedItems;
  final String currentStep;

  ExportProgress({
    required this.totalItems,
    required this.processedItems,
    required this.currentStep,
  });

  double get progress => totalItems > 0 ? processedItems / totalItems : 0.0;
}

class ExportResult {
  final bool success;
  final String message;
  final String? filePath;
  final String? compressedFilePath;

  ExportResult({
    required this.success,
    required this.message,
    this.filePath,
    this.compressedFilePath,
  });
}

class ExportService {
  static final Map<String, String> _requiredFields = {
    'name': 'Name',
    'age': 'Age',
    'gender': 'Gender',
    'phone': 'Phone',
    'email': 'Email',
    'address': 'Address',
  };

  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd_HH-mm-ss').format(date);
  }

  static Future<String> _compressFile(String filePath) async {
    Logger.info('Compressing file: $filePath');
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final compressedBytes = GZipEncoder().encode(bytes);

    if (compressedBytes == null) {
      throw 'Failed to compress file';
    }

    final compressedPath = '$filePath.gz';
    await File(compressedPath).writeAsBytes(compressedBytes);
    Logger.info('File compressed successfully: $compressedPath');
    return compressedPath;
  }

  static Future<bool> _checkFileExists(String filePath) async {
    final file = File(filePath);
    return file.exists();
  }

  static Future<String> _getUniqueFilePath(String basePath) async {
    String filePath = basePath;
    int counter = 1;

    while (await _checkFileExists(filePath)) {
      final lastDot = basePath.lastIndexOf('.');
      if (lastDot != -1) {
        filePath =
            '${basePath.substring(0, lastDot)}_$counter${basePath.substring(lastDot)}';
      } else {
        filePath = '${basePath}_$counter';
      }
      counter++;
    }

    return filePath;
  }

  static Future<ExportResult> exportToExcel(
    List<Map<String, dynamic>> data, {
    void Function(ExportProgress)? onProgress,
    bool compress = false,
    bool background = false,
  }) async {
    try {
      Logger.info('Starting Excel export');
      onProgress?.call(ExportProgress(
        totalItems: data.length + 1,
        processedItems: 0,
        currentStep: 'Creating Excel workbook',
      ));

      final excel = Excel.createExcel();
      final sheet = excel['Patients'];

      // Add headers
      var headerRow = _requiredFields.values.toList();
      sheet.insertRowIterables(headerRow, 0);
      onProgress?.call(ExportProgress(
        totalItems: data.length + 1,
        processedItems: 1,
        currentStep: 'Adding data rows',
      ));

      // Add data rows
      for (var i = 0; i < data.length; i++) {
        var row =
            _requiredFields.keys.map((key) => data[i][key].toString()).toList();
        sheet.insertRowIterables(row, i + 1);
        onProgress?.call(ExportProgress(
          totalItems: data.length + 1,
          processedItems: i + 2,
          currentStep: 'Processing row ${i + 1}',
        ));
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'patients_export_${_formatDate(DateTime.now())}.xlsx';
      final filePath = await _getUniqueFilePath('${directory.path}/$fileName');

      final fileBytes = excel.encode();
      if (fileBytes == null) {
        Logger.error('Failed to encode Excel file');
        return ExportResult(
          success: false,
          message: 'Failed to create Excel file',
        );
      }

      onProgress?.call(ExportProgress(
        totalItems: data.length + 1,
        processedItems: data.length + 1,
        currentStep: 'Saving file',
      ));

      await File(filePath).writeAsBytes(fileBytes);

      if (compress) {
        onProgress?.call(ExportProgress(
          totalItems: data.length + 1,
          processedItems: data.length + 1,
          currentStep: 'Compressing file',
        ));
        final compressedPath = await _compressFile(filePath);
        return ExportResult(
          success: true,
          message: 'Excel export completed successfully',
          filePath: filePath,
          compressedFilePath: compressedPath,
        );
      }

      Logger.info('Excel export completed successfully: $filePath');
      return ExportResult(
        success: true,
        message: 'Excel export completed successfully',
        filePath: filePath,
      );
    } catch (e) {
      Logger.error('Excel export failed: $e');
      return ExportResult(
        success: false,
        message: 'Failed to export to Excel: ${e.toString()}',
      );
    }
  }

  static Future<ExportResult> exportToCSV(
    List<Map<String, dynamic>> data, {
    void Function(ExportProgress)? onProgress,
    bool compress = false,
    bool background = false,
  }) async {
    try {
      Logger.info('Starting CSV export');
      onProgress?.call(ExportProgress(
        totalItems: data.length + 1,
        processedItems: 0,
        currentStep: 'Preparing CSV data',
      ));

      final List<List<dynamic>> csvData = [];
      csvData.add(_requiredFields.values.toList());
      onProgress?.call(ExportProgress(
        totalItems: data.length + 1,
        processedItems: 1,
        currentStep: 'Processing data rows',
      ));

      for (var i = 0; i < data.length; i++) {
        csvData.add(_requiredFields.keys
            .map((key) => data[i][key].toString())
            .toList());
        onProgress?.call(ExportProgress(
          totalItems: data.length + 1,
          processedItems: i + 2,
          currentStep: 'Processing row ${i + 1}',
        ));
      }

      final String csvString = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'patients_export_${_formatDate(DateTime.now())}.csv';
      final filePath = await _getUniqueFilePath('${directory.path}/$fileName');

      onProgress?.call(ExportProgress(
        totalItems: data.length + 1,
        processedItems: data.length + 1,
        currentStep: 'Saving file',
      ));

      await File(filePath).writeAsString(csvString);

      if (compress) {
        onProgress?.call(ExportProgress(
          totalItems: data.length + 1,
          processedItems: data.length + 1,
          currentStep: 'Compressing file',
        ));
        final compressedPath = await _compressFile(filePath);
        return ExportResult(
          success: true,
          message: 'CSV export completed successfully',
          filePath: filePath,
          compressedFilePath: compressedPath,
        );
      }

      Logger.info('CSV export completed successfully: $filePath');
      return ExportResult(
        success: true,
        message: 'CSV export completed successfully',
        filePath: filePath,
      );
    } catch (e) {
      Logger.error('CSV export failed: $e');
      return ExportResult(
        success: false,
        message: 'Failed to export to CSV: ${e.toString()}',
      );
    }
  }

  static Future<ExportResult> exportToPDF(
    List<Map<String, dynamic>> data, {
    void Function(ExportProgress)? onProgress,
    bool compress = false,
    bool background = false,
  }) async {
    try {
      Logger.info('Starting PDF export');
      onProgress?.call(ExportProgress(
        totalItems: data.length + 1,
        processedItems: 0,
        currentStep: 'Creating PDF document',
      ));

      final pdf = pw.Document();

      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Patient Records',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Add data pages
      const itemsPerPage = 10;
      final totalPages = (data.length / itemsPerPage).ceil();

      for (var pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final startIndex = pageIndex * itemsPerPage;
        final endIndex = (startIndex + itemsPerPage < data.length)
            ? startIndex + itemsPerPage
            : data.length;
        final pageData = data.sublist(startIndex, endIndex);

        onProgress?.call(ExportProgress(
          totalItems: totalPages,
          processedItems: pageIndex + 1,
          currentStep: 'Creating page ${pageIndex + 1}',
        ));

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      'Patient Records - Page ${pageIndex + 1}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    headers: _requiredFields.values.toList(),
                    data: pageData.map((row) {
                      return _requiredFields.keys
                          .map((key) => row[key].toString())
                          .toList();
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    border: pw.TableBorder.all(),
                    cellHeight: 25,
                    cellAlignments: {
                      for (var i = 0; i < _requiredFields.length; i++)
                        i: pw.Alignment.centerLeft,
                    },
                  ),
                ],
              );
            },
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'patients_export_${_formatDate(DateTime.now())}.pdf';
      final filePath = await _getUniqueFilePath('${directory.path}/$fileName');

      onProgress?.call(ExportProgress(
        totalItems: totalPages,
        processedItems: totalPages,
        currentStep: 'Saving file',
      ));

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (compress) {
        onProgress?.call(ExportProgress(
          totalItems: totalPages,
          processedItems: totalPages,
          currentStep: 'Compressing file',
        ));
        final compressedPath = await _compressFile(filePath);
        return ExportResult(
          success: true,
          message: 'PDF export completed successfully',
          filePath: filePath,
          compressedFilePath: compressedPath,
        );
      }

      Logger.info('PDF export completed successfully: $filePath');
      return ExportResult(
        success: true,
        message: 'PDF export completed successfully',
        filePath: filePath,
      );
    } catch (e) {
      Logger.error('PDF export failed: $e');
      return ExportResult(
        success: false,
        message: 'Failed to export to PDF: ${e.toString()}',
      );
    }
  }
}
