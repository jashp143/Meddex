import '../repositories/base_repository.dart';

class Patient implements DatabaseItem {
  @override
  final String id;
  final String name;
  final int age;
  final String gender;
  final String contactNumber;
  final String? email;
  final String? address;
  final DateTime registrationDate;
  final double? weight; // Weight in Kg
  final String? allergies; // Patient allergies
  final List<String>? comorbidities; // Common comorbidities

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contactNumber,
    this.email,
    this.address,
    required this.registrationDate,
    this.weight,
    this.allergies,
    this.comorbidities,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'contactNumber': contactNumber,
      'email': email,
      'address': address,
      'registrationDate': registrationDate.toIso8601String(),
      'weight': weight,
      'allergies': allergies,
      'comorbidities': comorbidities != null ? comorbidities!.join(',') : null,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      contactNumber: map['contactNumber'],
      email: map['email'],
      address: map['address'],
      registrationDate: DateTime.parse(map['registrationDate']),
      weight: map['weight'] != null ? map['weight'] as double : null,
      allergies: map['allergies'],
      comorbidities: map['comorbidities'] != null
          ? (map['comorbidities'] as String).split(',')
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => toMap();

  factory Patient.fromJson(Map<String, dynamic> json) => Patient.fromMap(json);

  // Add copyWith method for easy updates
  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? contactNumber,
    String? email,
    String? address,
    DateTime? registrationDate,
    double? weight,
    String? allergies,
    List<String>? comorbidities,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      registrationDate: registrationDate ?? this.registrationDate,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      comorbidities: comorbidities ?? this.comorbidities,
    );
  }
}
