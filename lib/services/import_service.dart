import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';

class ImportResult {
  final List<Patient> validPatients;
  final List<String> errors;
  final int totalRows;
  final int successfulRows;

  ImportResult({
    required this.validPatients,
    required this.errors,
    required this.totalRows,
    required this.successfulRows,
  });
}

class ImportService {
  static const _requiredFields = {
    'name': 'Name',
    'age': 'Age',
    'gender': 'Gender',
    'contact': 'Contact Number',
  };

  Future<ImportResult> importFromExcel(String filePath) async {
    final List<Patient> validPatients = [];
    final List<String> errors = [];
    int totalRows = 0;

    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        final headers = _getHeaders(sheet);

        // Validate headers
        final missingFields = _validateHeaders(headers);
        if (missingFields.isNotEmpty) {
          errors.add('Missing required columns: ${missingFields.join(", ")}');
          return ImportResult(
            validPatients: [],
            errors: errors,
            totalRows: 0,
            successfulRows: 0,
          );
        }

        // Process rows
        for (var row in sheet.rows.skip(1)) {
          totalRows++;
          try {
            final patient = _processRow(row, headers);
            if (patient != null) {
              validPatients.add(patient);
            }
          } catch (e) {
            errors.add('Error in row $totalRows: $e');
          }
        }
        break; // Only process first sheet
      }
    } catch (e) {
      errors.add('Error reading Excel file: $e');
    }

    return ImportResult(
      validPatients: validPatients,
      errors: errors,
      totalRows: totalRows,
      successfulRows: validPatients.length,
    );
  }

  Future<ImportResult> importFromCSV(String filePath) async {
    final List<Patient> validPatients = [];
    final List<String> errors = [];
    int totalRows = 0;

    try {
      final input = File(filePath).readAsStringSync();
      final rows = const CsvToListConverter().convert(input);

      if (rows.isEmpty) {
        errors.add('CSV file is empty');
        return ImportResult(
          validPatients: [],
          errors: errors,
          totalRows: 0,
          successfulRows: 0,
        );
      }

      // Get and validate headers
      final headers = Map<String, int>.fromIterables(
        List<String>.from(rows[0]),
        List.generate(rows[0].length, (i) => i),
      );

      final missingFields = _validateHeaders(headers);
      if (missingFields.isNotEmpty) {
        errors.add('Missing required columns: ${missingFields.join(", ")}');
        return ImportResult(
          validPatients: [],
          errors: errors,
          totalRows: 0,
          successfulRows: 0,
        );
      }

      // Process rows
      for (var i = 1; i < rows.length; i++) {
        totalRows++;
        try {
          final patient = _processCSVRow(rows[i], headers);
          if (patient != null) {
            validPatients.add(patient);
          }
        } catch (e) {
          errors.add('Error in row ${i + 1}: $e');
        }
      }
    } catch (e) {
      errors.add('Error reading CSV file: $e');
    }

    return ImportResult(
      validPatients: validPatients,
      errors: errors,
      totalRows: totalRows,
      successfulRows: validPatients.length,
    );
  }

  Map<String, int> _getHeaders(Sheet sheet) {
    final headerRow = sheet.rows[0];
    final headers = <String, int>{};

    for (var i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell?.value != null) {
        headers[cell!.value.toString().toLowerCase()] = i;
      }
    }

    return headers;
  }

  List<String> _validateHeaders(Map<String, int> headers) {
    final missingFields = <String>[];

    for (var field in _requiredFields.keys) {
      if (!headers.containsKey(field.toLowerCase())) {
        missingFields.add(_requiredFields[field]!);
      }
    }

    return missingFields;
  }

  Patient? _processRow(List<dynamic> row, Map<String, int> headers) {
    if (row.isEmpty) return null;

    final name = _getCellValue(row, headers['name']!);
    final ageStr = _getCellValue(row, headers['age']!);
    final gender = _getCellValue(row, headers['gender']!);
    final contact = _getCellValue(row, headers['contact']!);

    if (name.isEmpty || ageStr.isEmpty || gender.isEmpty || contact.isEmpty) {
      throw 'Missing required fields';
    }

    final age = int.tryParse(ageStr);
    if (age == null) throw 'Invalid age format';

    String? email;
    String? address;

    if (headers.containsKey('email')) {
      email = _getCellValue(row, headers['email']!);
    }

    if (headers.containsKey('address')) {
      address = _getCellValue(row, headers['address']!);
    }

    return Patient(
      id: const Uuid().v4(),
      name: name,
      age: age,
      gender: gender,
      contactNumber: contact,
      email: email?.isNotEmpty == true ? email : null,
      address: address?.isNotEmpty == true ? address : null,
      registrationDate: DateTime.now(),
    );
  }

  Patient? _processCSVRow(List<dynamic> row, Map<String, int> headers) {
    if (row.isEmpty) return null;

    final name = row[headers['name']!].toString();
    final ageStr = row[headers['age']!].toString();
    final gender = row[headers['gender']!].toString();
    final contact = row[headers['contact']!].toString();

    if (name.isEmpty || ageStr.isEmpty || gender.isEmpty || contact.isEmpty) {
      throw 'Missing required fields';
    }

    final age = int.tryParse(ageStr);
    if (age == null) throw 'Invalid age format';

    String? email;
    String? address;

    if (headers.containsKey('email')) {
      email = row[headers['email']!].toString();
    }

    if (headers.containsKey('address')) {
      address = row[headers['address']!].toString();
    }

    return Patient(
      id: const Uuid().v4(),
      name: name,
      age: age,
      gender: gender,
      contactNumber: contact,
      email: email?.isNotEmpty == true ? email : null,
      address: address?.isNotEmpty == true ? address : null,
      registrationDate: DateTime.now(),
    );
  }

  String _getCellValue(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    final cell = row[index];
    if (cell == null) return '';
    return cell.toString().trim();
  }
}
