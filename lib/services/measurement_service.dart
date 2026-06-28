// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Add Measurements
static Future<String?> addMeasurements({
  required String customerId,
  required String tailorId,
  required double chest,
  required double waist,
  required double hip,
  required double shoulder,
  required double sleeveLength,
  required double neck,
  required double shirtLength,
  required double trouserLength,
  required double price,
}) async {
  try {
    final measurementRef = _firestore.collection("measurements").doc();

    await measurementRef.set({
      "measurement_id": measurementRef.id,
      "customer_id": customerId,
      "tailor_id": tailorId,
      "chest": chest,
      "waist": waist,
      "hip": hip,
      "shoulder": shoulder,
      "sleeve_length": sleeveLength,
      "neck": neck,
      "shirt_length": shirtLength,
      "trouser_length": trouserLength,
      "price": price,
      "isCompleted": false,
      "isBill": false,  // ✅ Add this
      "created_at": Timestamp.now(),
      "updated_at": Timestamp.now(),
    });

    return null;
  } catch (e) {
    return e.toString();
  }
}

  // Get Measurements by Customer ID
  static Future<List<Map<String, dynamic>>> getMeasurementsByCustomer(
      String customerId) async {
    try {
      final snapshot = await _firestore
          .collection("measurements")
          .where("customer_id", isEqualTo: customerId)
          .orderBy("created_at", descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('Error getting measurements: $e');
      return [];
    }
  }

  // Get Latest Measurement by Customer ID
  static Future<Map<String, dynamic>?> getLatestMeasurement(
      String customerId) async {
    try {
      final snapshot = await _firestore
          .collection("measurements")
          .where("customer_id", isEqualTo: customerId)
          .orderBy("created_at", descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return {
          "id": snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        };
      }
      return null;
    } catch (e) {
      print('Error getting latest measurement: $e');
      return null;
    }
  }

  // Update Measurement
  static Future<String?> updateMeasurement({
    required String measurementId,
    required double chest,
    required double waist,
    required double hip,
    required double shoulder,
    required double sleeveLength,
    required double neck,
    required double shirtLength,
    required double trouserLength,
    required double price,
  }) async {
    try {
      await _firestore.collection("measurements").doc(measurementId).update({
        "chest": chest,
        "waist": waist,
        "hip": hip,
        "shoulder": shoulder,
        "sleeve_length": sleeveLength,
        "neck": neck,
        "shirt_length": shirtLength,
        "trouser_length": trouserLength,
        "price": price,
        "updated_at": Timestamp.now(),
      });

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Update Measurement Status (isCompleted)
  static Future<String?> updateMeasurementStatus({
    required String measurementId,
    required bool isCompleted,
  }) async {
    try {
      await _firestore.collection("measurements").doc(measurementId).update({
        "isCompleted": isCompleted,
        "updated_at": Timestamp.now(),
      });
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }


  // Update Bill Status (isBill)
static Future<String?> updateBillStatus({
  required String measurementId,
  required bool isBill,
}) async {
  try {
    await _firestore.collection("measurements").doc(measurementId).update({
      "isBill": isBill,
      "updated_at": Timestamp.now(),
    });
    return null;
  } catch (e) {
    return e.toString();
  }
}

  // Delete Measurement
  static Future<String?> deleteMeasurement(String measurementId) async {
    try {
      await _firestore.collection("measurements").doc(measurementId).delete();
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Get All Measurements for a Tailor
  static Stream<QuerySnapshot> getTailorMeasurements(String tailorId) {
    return _firestore
        .collection("measurements")
        .where("tailor_id", isEqualTo: tailorId)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  // Get Completed Measurements for a Tailor
  static Stream<QuerySnapshot> getCompletedMeasurements(String tailorId) {
    return _firestore
        .collection("measurements")
        .where("tailor_id", isEqualTo: tailorId)
        .where("isCompleted", isEqualTo: true)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  // Get Pending Measurements for a Tailor
  static Stream<QuerySnapshot> getPendingMeasurements(String tailorId) {
    return _firestore
        .collection("measurements")
        .where("tailor_id", isEqualTo: tailorId)
        .where("isCompleted", isEqualTo: false)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  // Get Measurements Count by Status
  static Future<int> getMeasurementsCountByStatus({
    required String tailorId,
    required bool isCompleted,
  }) async {
    try {
      final snapshot = await _firestore
          .collection("measurements")
          .where("tailor_id", isEqualTo: tailorId)
          .where("isCompleted", isEqualTo: isCompleted)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get Total Measurements Count for a Tailor
  static Future<int> getTotalMeasurementsCount(String tailorId) async {
    try {
      final snapshot = await _firestore
          .collection("measurements")
          .where("tailor_id", isEqualTo: tailorId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}