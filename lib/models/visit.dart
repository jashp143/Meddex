class Visit {
  final String id;
  final String patientId;
  final DateTime visitDate;
  final String prescription;
  final List<String> recommendedTests;
  final Map<String, dynamic> testResults;
  final DateTime? followUpDate;
  final String currentTreatmentPlan;
  final List<Medicine> medicines;
  final String instructions;
  final double consultationFee;
  final double pendingAmount;
  final double totalBill;
  final String paymentMode;

  Visit({
    required this.id,
    required this.patientId,
    required this.visitDate,
    required this.prescription,
    required this.recommendedTests,
    required this.testResults,
    this.followUpDate,
    required this.currentTreatmentPlan,
    required this.medicines,
    required this.instructions,
    required this.consultationFee,
    required this.pendingAmount,
    required this.totalBill,
    required this.paymentMode,
  });

  // Convert visit to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'visitDate': visitDate.toIso8601String(),
      'prescription': prescription,
      'recommendedTests':
          recommendedTests.isNotEmpty ? recommendedTests.join(',') : '',
      'testResults': testResults.isEmpty ? '{}' : testResults.toString(),
      'followUpDate': followUpDate?.toIso8601String(),
      'currentTreatmentPlan': currentTreatmentPlan,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'instructions': instructions,
      'consultationFee': consultationFee,
      'pendingAmount': pendingAmount,
      'totalBill': totalBill,
      'paymentMode': paymentMode,
    };
  }

  // Create visit from map
  factory Visit.fromMap(Map<String, dynamic> map) {
    List<String> parseRecommendedTests(dynamic testsData) {
      if (testsData is String) {
        return testsData.split(',').where((e) => e.isNotEmpty).toList();
      } else if (testsData is List) {
        return List<String>.from(testsData);
      }
      return [];
    }

    Map<String, dynamic> parseTestResults(dynamic resultsData) {
      if (resultsData is String) {
        if (resultsData.isEmpty || resultsData == '{}') {
          return {};
        }
        return {'results': resultsData};
      } else if (resultsData is Map) {
        return Map<String, dynamic>.from(resultsData);
      }
      return {};
    }

    List<Medicine> parseMedicines(dynamic medicinesData) {
      if (medicinesData == null) {
        return [];
      }

      if (medicinesData is List) {
        return medicinesData.map((medicineItem) {
          if (medicineItem is Medicine) {
            return medicineItem;
          } else if (medicineItem is Map<String, dynamic>) {
            return Medicine.fromMap(medicineItem);
          } else {
            print('Unknown medicine data type: ${medicineItem.runtimeType}');
            return Medicine(
                name: 'Unknown', dosage: 'Unknown', duration: 'Unknown');
          }
        }).toList();
      }

      print('Medicines data is not a list: ${medicinesData.runtimeType}');
      return [];
    }

    return Visit(
      id: map['id'],
      patientId: map['patientId'],
      visitDate: DateTime.parse(map['visitDate']),
      prescription: map['prescription'],
      recommendedTests: parseRecommendedTests(map['recommendedTests']),
      testResults: parseTestResults(map['testResults']),
      followUpDate: map['followUpDate'] != null
          ? DateTime.parse(map['followUpDate'])
          : null,
      currentTreatmentPlan: map['currentTreatmentPlan'],
      medicines: parseMedicines(map['medicines']),
      instructions: map['instructions'],
      consultationFee: map['consultationFee'] is int
          ? (map['consultationFee'] as int).toDouble()
          : map['consultationFee'],
      pendingAmount: map['pendingAmount'] is int
          ? (map['pendingAmount'] as int).toDouble()
          : map['pendingAmount'],
      totalBill: map['totalBill'] is int
          ? (map['totalBill'] as int).toDouble()
          : map['totalBill'],
      paymentMode: map['paymentMode'],
    );
  }

  // JSON conversion methods
  Map<String, dynamic> toJson() => toMap();

  factory Visit.fromJson(Map<String, dynamic> json) => Visit.fromMap(json);
}

class Medicine {
  final String name;
  final String dosage;
  final String duration;

  Medicine({
    required this.name,
    required this.dosage,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'duration': duration,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      name: map['name'],
      dosage: map['dosage'],
      duration: map['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'duration': duration,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      duration: json['duration'] as String,
    );
  }
}
