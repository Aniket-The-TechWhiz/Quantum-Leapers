import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to send SOS notifications via Firebase Cloud Messaging (FCM)
/// 
/// This service handles:
/// 1. Registering and storing FCM tokens for users and emergency contacts
/// 2. Sending SOS notifications via FCM to emergency contacts
/// 3. Queueing notifications in Realtime Database for Cloud Functions processing
/// 
/// Project: arogyasos-c23e6
/// Database URL: https://arogyasos-c23e6-default-rtdb.firebaseio.com/
class FirebaseFCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Database paths
  static const String _fcmTokensPath = 'fcmTokens';
  static const String _sosNotificationsPath = 'sosNotifications';
  static const String _realtimeDbUrl = 'https://arogyasos-c23e6-default-rtdb.firebaseio.com';

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

  /// Request notification permissions and get FCM token
  /// 
  /// Returns the FCM token if successful, null otherwise
  Future<String?> getFCMToken() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get the token
        String? token = await _messaging.getToken();
        
        if (token != null) {
          // Store token in Firebase for this user
          await _saveFCMToken(token);
          return token;
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to Firebase Realtime Database
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = await _getUserId();
      await _database
          .child(_fcmTokensPath)
          .child(userId)
          .set({
        'token': token,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Register FCM token for an emergency contact
  /// 
  /// [contactPhone] - Phone number of the emergency contact
  /// [contactName] - Name of the emergency contact
  /// [fcmToken] - FCM token of the emergency contact's device
  Future<bool> registerEmergencyContactToken({
    required String contactPhone,
    required String contactName,
    required String fcmToken,
  }) async {
    try {
      final userId = await _getUserId();
      final contactId = _normalizePhoneNumber(contactPhone);
      
      await _database
          .child(_fcmTokensPath)
          .child('emergencyContacts')
          .child(userId)
          .child(contactId)
          .set({
        'token': fcmToken,
        'phone': contactPhone,
        'name': contactName,
        'updatedAt': ServerValue.timestamp,
      });
      
      return true;
    } catch (e) {
      print('Error registering emergency contact token: $e');
      return false;
    }
  }

  /// Get FCM tokens for emergency contacts from Firebase
  /// 
  /// Returns a map of contact phone numbers to their FCM tokens
  Future<Map<String, String>> getEmergencyContactTokens() async {
    try {
      final userId = await _getUserId();
      final snapshot = await _database
          .child(_fcmTokensPath)
          .child('emergencyContacts')
          .child(userId)
          .get();
      
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final Map<String, String> tokens = {};
        
        data.forEach((key, value) {
          if (value is Map && value['token'] != null) {
            tokens[value['phone'] as String? ?? key.toString()] = value['token'] as String;
          }
        });
        
        return tokens;
      }
      
      return {};
    } catch (e) {
      print('Error getting emergency contact tokens: $e');
      return {};
    }
  }

  /// Send SOS notification via FCM to emergency contacts
  /// 
  /// This method queues the notification in Realtime Database for Cloud Functions processing
  /// Cloud Functions will then send FCM notifications to all registered tokens
  /// 
  /// [message] - The SOS message content
  /// [location] - Location information
  /// [coordinates] - GPS coordinates
  /// [medicalInfo] - Medical information
  /// [userName] - Name of the user in distress
  Future<bool> sendSOSNotification({
    required String message,
    required String location,
    required String coordinates,
    required String medicalInfo,
    required String userName,
    String? locationLink,
  }) async {
    try {
      final userId = await _getUserId();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final notificationId = 'sos_$timestamp';
      
      // Prepare notification data
      final notificationData = {
        'userId': userId,
        'userName': userName,
        'message': message,
        'location': location,
        'coordinates': coordinates,
        'locationLink': locationLink ?? '',
        'medicalInfo': medicalInfo,
        'timestamp': timestamp,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Queue in Realtime Database (Cloud Functions will process this)
      final url = Uri.parse('$_realtimeDbUrl/$_sosNotificationsPath/$notificationId.json');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(notificationData),
      );
      
      if (response.statusCode == 200) {
        print('SOS notification queued: $notificationId');
        return true;
      } else {
        print('Error queueing SOS notification: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending SOS notification: $e');
      return false;
    }
  }

  /// Send SOS notification directly via HTTP to Cloud Functions (if endpoint available)
  /// 
  /// This requires a Cloud Function endpoint that handles FCM sending
  Future<bool> sendSOSNotificationViaHTTP({
    required String functionUrl,
    required Map<String, String> contactTokens,
    required String message,
    required String location,
    required String coordinates,
    required String medicalInfo,
    required String userName,
    String? locationLink,
  }) async {
    try {
      final notificationData = {
        'tokens': contactTokens.values.toList(),
        'title': '🚨 EMERGENCY SOS ALERT',
        'body': message,
        'data': {
          'type': 'sos_alert',
          'userName': userName,
          'location': location,
          'coordinates': coordinates,
          'locationLink': locationLink ?? '',
          'medicalInfo': medicalInfo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
      
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(notificationData),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['success'] == true;
      } else {
        print('HTTP Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending SOS notification via HTTP: $e');
      return false;
    }
  }

  /// Normalize phone number for use as database key
  String _normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Setup FCM message handlers for foreground messages
  void setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }
}
