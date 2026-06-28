import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add Customer
  static Future<String?> addCustomer({
    required String tailorId,
    required String name,
    required String phone,
    required String email,
    required String note,
  }) async {
    try {
      final customerRef = _firestore.collection("customers").doc();

      await customerRef.set({
        "customer_id": customerRef.id,
        "tailor_id": tailorId,
        "name": name.trim(),
        "phone": phone.trim(),
        "email": email.trim().isEmpty ? null : email.trim(),
        "note": note.trim().isEmpty ? null : note.trim(),
        "has_measurements": false, // ✅ Default false
        "created_at": Timestamp.now(),
        "updated_at": Timestamp.now(),
      });

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Get All Customers for a Tailor
  static Stream<QuerySnapshot> getCustomers(String tailorId) {
    return _firestore
        .collection("customers")
        .where("tailor_id", isEqualTo: tailorId)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  // Get Customers Without Measurements
  static Stream<QuerySnapshot> getCustomersWithoutMeasurements(String tailorId) {
    return _firestore
        .collection("customers")
        .where("tailor_id", isEqualTo: tailorId)
        .where("has_measurements", isEqualTo: false)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  // Get Customers With Measurements
  static Stream<QuerySnapshot> getCustomersWithMeasurements(String tailorId) {
    return _firestore
        .collection("customers")
        .where("tailor_id", isEqualTo: tailorId)
        .where("has_measurements", isEqualTo: true)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  // Get Single Customer
  static Future<DocumentSnapshot?> getCustomer(String customerId) async {
    try {
      final doc = await _firestore.collection("customers").doc(customerId).get();
      return doc;
    } catch (e) {
      return null;
    }
  }

  // Update Customer
  static Future<String?> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
    required String email,
    required String note,
  }) async {
    try {
      await _firestore.collection("customers").doc(customerId).update({
        "name": name.trim(),
        "phone": phone.trim(),
        "email": email.trim().isEmpty ? null : email.trim(),
        "note": note.trim().isEmpty ? null : note.trim(),
        "updated_at": Timestamp.now(),
      });

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Delete Customer
  static Future<String?> deleteCustomer(String customerId) async {
    try {
      await _firestore.collection("customers").doc(customerId).delete();
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Update Measurements Status (set to true when measurements are added)
  static Future<String?> updateMeasurementStatus({
    required String customerId,
    required bool hasMeasurements,
  }) async {
    try {
      await _firestore.collection("customers").doc(customerId).update({
        "has_measurements": hasMeasurements,
        "updated_at": Timestamp.now(),
      });
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Search Customers
  static Stream<QuerySnapshot> searchCustomers({
    required String tailorId,
    required String searchText,
  }) {
    return _firestore
        .collection("customers")
        .where("tailor_id", isEqualTo: tailorId)
        .orderBy("name")
        .startAt([searchText.trim()])
        // ignore: prefer_interpolation_to_compose_strings
        .endAt([searchText.trim() + '\uf8ff'])
        .snapshots();
  }

  // Get Customers Count
  static Future<int> getCustomersCount(String tailorId) async {
    try {
      final snapshot = await _firestore
          .collection("customers")
          .where("tailor_id", isEqualTo: tailorId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get Customers Without Measurements Count
  static Future<int> getCustomersWithoutMeasurementsCount(String tailorId) async {
    try {
      final snapshot = await _firestore
          .collection("customers")
          .where("tailor_id", isEqualTo: tailorId)
          .where("has_measurements", isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}