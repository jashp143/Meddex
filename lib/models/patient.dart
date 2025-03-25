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

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contactNumber,
    this.email,
    this.address,
    required this.registrationDate,
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
    );
  }
}
