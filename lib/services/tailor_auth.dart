import 'package:cloud_firestore/cloud_firestore.dart';

class TailorAuth {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store current tailor data
  static Map<String, dynamic>? _currentTailor;

  // Signup function
  static Future<String?> signupTailor({
    required String name,
    required String shopName,
    required String shopAddress,
    required String email,
    required String password,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _firestore
          .collection("tailors")
          .where("email", isEqualTo: email.trim())
          .get();

      if (existingUser.docs.isNotEmpty) {
        return "Email already registered";
      }

      // Generate unique tailor document
      final tailorRef = _firestore.collection("tailors").doc();

      await tailorRef.set({
        "tailor_id": tailorRef.id, 
        "name": name.trim(),
        "shop_name": shopName.trim(),
        "shop_address": shopAddress.trim(),
        "email": email.trim(),
        "password": password.trim(),
        "created_at": Timestamp.now(),
      });

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Login function
  static Future<String?> loginTailor({
    required String email,
    required String password,
  }) async {
    try {
      QuerySnapshot result = await _firestore
          .collection("tailors")
          .where("email", isEqualTo: email.trim())
          .where("password", isEqualTo: password.trim())
          .get();

      if (result.docs.isNotEmpty) {
        // Store the logged-in tailor data
        final doc = result.docs.first;
        _currentTailor = doc.data() as Map<String, dynamic>;
        _currentTailor!['id'] = doc.id; // Also store document ID
        
        // ignore: avoid_print
        print('✅ Login successful. Tailor ID: ${_currentTailor!['id']}');
        // ignore: avoid_print
        print('✅ Tailor Name: ${_currentTailor!['name']}');
        
        return null; // Success
      } else {
        return "Invalid Email or Password";
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Login error: $e');
      return e.toString();
    }
  }

  // Logout function
  static Future<void> logout() async {
    // ignore: avoid_print
    print('👋 Logging out...');
    _currentTailor = null; 
    return Future.value();
  }

  // Get current tailor ID (from document)
  static String? getCurrentTailorId() {
    if (_currentTailor == null) {
      // ignore: avoid_print
      print('❌ getCurrentTailorId: _currentTailor is null');
      return null;
    }
    
    final id = _currentTailor?['id'];
    
    return id;
  }

  // Get current tailor data
  static Map<String, dynamic>? getCurrentTailor() {
    return _currentTailor;
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    final loggedIn = _currentTailor != null;
    // ignore: avoid_print
    print('🔍 isLoggedIn: $loggedIn');
    return loggedIn;
  }

  // Get tailor name
  static String? getTailorName() {
    return _currentTailor?['name'];
  }

  // Get tailor email
  static String? getTailorEmail() {
    return _currentTailor?['email'];
  }

  // Get tailor shop name
  static String? getShopName() {
    return _currentTailor?['shop_name'];
  }

  // Get tailor shop address
  static String? getShopAddress() {
    return _currentTailor?['shop_address'];
  }
}