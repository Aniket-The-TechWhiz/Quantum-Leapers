import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to sync emergency contacts and profile data with Firebase Realtime Database
/// 
/// This service syncs data between local SharedPreferences and Firebase Realtime Database
/// Project: arogyasos-c23e6
/// Database URL: https://arogyasos-c23e6-default-rtdb.firebaseio.com/
class FirebaseRealtimeService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Database paths
  static const String _usersPath = 'users';
  static const String _emergencyContactsPath = 'emergencyContacts';
  static const String _profilePath = 'profile';
  static const String _smsQueuePath = 'smsQueue';

  /// Get or create a user ID (stored locally)
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('firebase_user_id');
    
    if (userId == null || userId.isEmpty) {
      // Generate a new user ID
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('firebase_user_id', userId);
    }
    
    return userId;
  }

  /// Sync emergency contacts to Firebase Realtime Database
  /// 
  /// [contacts] - List of emergency contacts to sync
  Future<bool> syncEmergencyContacts(List<Map<String, String>> contacts) async {
    try {
      final userId = await _getUserId();
      final contactsRef = _database.child(_usersPath).child(userId).child(_emergencyContactsPath);
      
      // Convert list to map for Firebase (using index as key)
      final Map<String, dynamic> contactsMap = {};
      for (int i = 0; i < contacts.length; i++) {
        contactsMap[i.toString()] = contacts[i];
      }
      
      await contactsRef.set(contactsMap);
      return true;
    } catch (e) {
      print('Error syncing emergency contacts: $e');
      return false;
    }
  }

  /// Load emergency contacts from Firebase Realtime Database
  Future<List<Map<String, String>>> loadEmergencyContacts() async {
    try {
      final userId = await _getUserId();
      final contactsRef = _database.child(_usersPath).child(userId).child(_emergencyContactsPath);
      
      final snapshot = await contactsRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, String>> contacts = [];
        
        // Convert map back to list
        data.forEach((key, value) {
          if (value is Map) {
            contacts.add(Map<String, String>.from(value));
          }
        });
        
        return contacts;
      }
      
      return [];
    } catch (e) {
      print('Error loading emergency contacts: $e');
      return [];
    }
  }

  /// Sync profile data to Firebase Realtime Database
  /// 
  /// [profileData] - Map containing profile information
  Future<bool> syncProfileData(Map<String, dynamic> profileData) async {
    try {
      final userId = await _getUserId();
      final profileRef = _database.child(_usersPath).child(userId).child(_profilePath);
      
      await profileRef.set(profileData);
      return true;
    } catch (e) {
      print('Error syncing profile data: $e');
      return false;
    }
  }

  /// Load profile data from Firebase Realtime Database
  Future<Map<String, dynamic>> loadProfileData() async {
    try {
      final userId = await _getUserId();
      final profileRef = _database.child(_usersPath).child(userId).child(_profilePath);
      
      final snapshot = await profileRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      
      return {};
    } catch (e) {
      print('Error loading profile data: $e');
      return {};
    }
  }

  /// Add SMS request to queue (for Cloud Functions trigger)
  /// 
  /// This can be used to trigger SMS sending via Realtime Database triggers
  /// [phoneNumber] - Recipient phone number
  /// [message] - SMS message content
  /// [userId] - User ID (optional, will be fetched if not provided)
  Future<bool> queueSMS({
    required String phoneNumber,
    required String message,
    String? userId,
  }) async {
    try {
      final uid = userId ?? await _getUserId();
      final smsRef = _database.child(_smsQueuePath).push();
      
      await smsRef.set({
        'userId': uid,
        'phoneNumber': phoneNumber,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'status': 'pending',
      });
      
      return true;
    } catch (e) {
      print('Error queueing SMS: $e');
      return false;
    }
  }

  /// Listen to emergency contacts changes (real-time updates)
  /// 
  /// Returns a stream of emergency contacts list
  Stream<List<Map<String, String>>> watchEmergencyContacts() {
    return _database
        .child(_usersPath)
        .child(_getUserId().then((id) => id).toString())
        .child(_emergencyContactsPath)
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, String>> contacts = [];
        
        data.forEach((key, value) {
          if (value is Map) {
            contacts.add(Map<String, String>.from(value));
          }
        });
        
        return contacts;
      }
      return <Map<String, String>>[];
    });
  }

  /// Delete user data from Firebase (for privacy/account deletion)
  Future<bool> deleteUserData() async {
    try {
      final userId = await _getUserId();
      final userRef = _database.child(_usersPath).child(userId);
      
      await userRef.remove();
      return true;
    } catch (e) {
      print('Error deleting user data: $e');
      return false;
    }
  }
}

