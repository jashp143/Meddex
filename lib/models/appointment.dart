class Appointment {
  final String id;
  final String patientId;
  final DateTime appointmentDate;
  final String purpose;
  final String? notes;
  final bool isFollowUp;
  final String status; // 'scheduled', 'completed', 'cancelled'

  Appointment({
    required this.id,
    required this.patientId,
    required this.appointmentDate,
    required this.purpose,
    this.notes,
    this.isFollowUp = false,
    this.status = 'scheduled',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'purpose': purpose,
      'notes': notes,
      'isFollowUp': isFollowUp ? 1 : 0,
      'status': status,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      purpose: json['purpose'] as String,
      notes: json['notes'] as String?,
      isFollowUp: (json['isFollowUp'] as int) == 1,
      status: json['status'] as String,
    );
  }
}
