import 'dart:async';
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
  /// 
  /// Returns the notification ID if successful, null otherwise
  Future<String?> sendSOSNotification({
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
        return notificationId;
      } else {
        print('Error queueing SOS notification: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending SOS notification: $e');
      return null;
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

  /// Listen to SOS notification status changes
  /// 
  /// [notificationId] - The ID of the SOS notification to monitor
  /// Returns a stream that emits notification status updates
  Stream<Map<String, dynamic>?> watchSOSNotificationStatus(String notificationId) {
    return _database
        .child(_sosNotificationsPath)
        .child(notificationId)
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return Map<String, dynamic>.from(data);
      }
      return null;
    });
  }

  /// Listen to all SOS notifications for a specific user
  /// 
  /// Returns a stream that emits all SOS notifications for the current user
  Stream<List<Map<String, dynamic>>> watchUserSOSNotifications() {
    return _database
        .child(_sosNotificationsPath)
        .orderByChild('userId')
        .onValue
        .asyncExpand((event) async* {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final userId = await _getUserId();
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> notifications = [];
        
        data.forEach((key, value) {
          if (value is Map && value['userId'] == userId) {
            final notification = Map<String, dynamic>.from(value);
            notification['id'] = key.toString();
            notifications.add(notification);
          }
        });
        
        // Sort by timestamp (newest first)
        notifications.sort((a, b) {
          final timestampA = a['timestamp'] as int? ?? 0;
          final timestampB = b['timestamp'] as int? ?? 0;
          return timestampB.compareTo(timestampA);
        });
        
        yield notifications;
      } else {
        yield <Map<String, dynamic>>[];
      }
    });
  }

  /// Listen to changes in emergency contact FCM tokens
  /// 
  /// Returns a stream that emits a map of contact phone numbers to their FCM tokens
  Stream<Map<String, String>> watchEmergencyContactTokens() {
    return _database
        .child(_fcmTokensPath)
        .child('emergencyContacts')
        .onValue
        .asyncExpand((event) async* {
      final userId = await _getUserId();
      final Map<String, String> tokens = {};
      
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final userTokens = data[userId];
        
        if (userTokens is Map) {
          userTokens.forEach((key, value) {
            if (value is Map && value['token'] != null) {
              final phone = value['phone'] as String? ?? key.toString();
              tokens[phone] = value['token'] as String;
            }
          });
        }
      }
      
      yield tokens;
    });
  }

  /// Listen to changes in user's own FCM token
  /// 
  /// Returns a stream that emits the user's FCM token when it changes
  Stream<String?> watchUserFCMToken() {
    return _database
        .child(_fcmTokensPath)
        .onValue
        .asyncExpand((event) async* {
      final userId = await _getUserId();
      
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final userData = data[userId];
        
        if (userData is Map && userData['token'] != null) {
          yield userData['token'] as String;
        } else {
          yield null;
        }
      } else {
        yield null;
      }
    });
  }

  /// Listen to any changes in a specific database path
  /// 
  /// [path] - The database path to listen to (e.g., 'users/123/profile')
  /// Returns a stream that emits the data at the specified path
  Stream<dynamic> watchDatabasePath(String path) {
    return _database
        .child(path)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return event.snapshot.value;
      }
      return null;
    });
  }

  /// Listen to child changes in a specific database path
  /// 
  /// [path] - The database path to listen to (e.g., 'users/123/emergencyContacts')
  /// Returns a stream that emits events when children are added, changed, or removed
  /// Note: This returns the onChildAdded stream. For more granular control, use individual streams.
  Stream<DatabaseEvent> watchChildChanges(String path) {
    return _database.child(path).onChildAdded;
  }
  
  /// Listen to child added events in a specific database path
  Stream<DatabaseEvent> watchChildAdded(String path) {
    return _database.child(path).onChildAdded;
  }
  
  /// Listen to child changed events in a specific database path
  Stream<DatabaseEvent> watchChildChanged(String path) {
    return _database.child(path).onChildChanged;
  }
  
  /// Listen to child removed events in a specific database path
  Stream<DatabaseEvent> watchChildRemoved(String path) {
    return _database.child(path).onChildRemoved;
  }

  /// Listen to value changes at a path with a callback (onDataChange equivalent)
  ///
  /// Returns the subscription so callers can cancel it in dispose().
  StreamSubscription<DatabaseEvent> onDataChange(
    String path,
    void Function(DatabaseEvent event) onData, {
    Function? onError,
  }) {
    return _database.child(path).onValue.listen(onData, onError: onError);
  }
}
