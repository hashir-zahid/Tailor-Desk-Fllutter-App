import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String tailorId;
  final String name;
  final String phone;
  final String? email;
  final String? note;
  final bool hasMeasurements;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.tailorId,
    required this.name,
    required this.phone,
    this.email,
    this.note,
    required this.hasMeasurements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromMap(String id, Map<String, dynamic> data) {
    return Customer(
      id: id,
      tailorId: data['tailor_id'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      note: data['note'],
      hasMeasurements: data['has_measurements'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': id,
      'tailor_id': tailorId,
      'name': name,
      'phone': phone,
      'email': email,
      'note': note,
      'has_measurements': hasMeasurements,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}