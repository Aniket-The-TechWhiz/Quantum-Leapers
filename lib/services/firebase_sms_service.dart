import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to send SMS messages via Firebase Cloud Functions
/// 
/// This service supports two methods:
/// 1. Direct HTTP calls to Cloud Functions (recommended)
/// 2. Realtime Database queue (for Cloud Functions triggers)
/// 
/// Project: arogyasos-c23e6
/// Database URL: https://arogyasos-c23e6-default-rtdb.firebaseio.com/
/// 
/// To use this service:
/// 1. Deploy the Cloud Function (see functions/index.js)
/// 2. Get the function URL from Firebase Console after deployment
/// 3. Pass the URL when initializing the service, or set it via setFunctionUrl()
class FirebaseSMSService {
  // Cloud Function URL for sending SMS
  String? _functionUrl;
  
  // Realtime Database URL for your project
  static const String _realtimeDbUrl = 'https://arogyasos-c23e6-default-rtdb.firebaseio.com';
  static const String _smsQueuePath = '/smsQueue';

  /// Constructor with optional function URL
  /// 
  /// If functionUrl is not provided, you can set it later using setFunctionUrl()
  /// If useRealtimeDatabase is true, SMS will be queued in Realtime Database
  FirebaseSMSService({String? functionUrl, bool useRealtimeDatabase = false}) 
      : _functionUrl = functionUrl;

  /// Set the Cloud Function URL
  /// 
  /// Get this URL from Firebase Console > Functions after deploying
  /// Format: https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendSMSHTTP
  void setFunctionUrl(String url) {
    _functionUrl = url;
  }

  /// Send SMS using Firebase Cloud Functions via HTTP or Realtime Database queue
  /// 
  /// [phoneNumber] - The recipient phone number (E.164 format, e.g., +1234567890)
  /// [message] - The message content to send
  /// [useRealtimeDatabase] - If true, queues SMS in Realtime Database for Cloud Functions trigger
  /// 
  /// Returns true if SMS was queued/sent successfully, false otherwise
  Future<bool> sendSMS({
    required String phoneNumber,
    required String message,
    bool useRealtimeDatabase = false,
  }) async {
    // Option 1: Queue in Realtime Database (for Cloud Functions triggers)
    if (useRealtimeDatabase) {
      return await queueSMSInRealtimeDatabase(
        phoneNumber: phoneNumber,
        message: message,
      );
    }
    
    // Option 2: Direct HTTP call to Cloud Function
    if (_functionUrl == null || _functionUrl!.isEmpty) {
      print('Error: Cloud Function URL not set. Please set it using setFunctionUrl() or pass it in constructor.');
      // Fallback to Realtime Database queue if URL not set
      return await queueSMSInRealtimeDatabase(
        phoneNumber: phoneNumber,
        message: message,
      );
    }

    return await sendSMSViaHTTP(
      functionUrl: _functionUrl!,
      phoneNumber: phoneNumber,
      message: message,
    );
  }
  
  /// Queue SMS in Realtime Database for Cloud Functions trigger
  /// 
  /// This method adds SMS requests to Realtime Database via REST API,
  /// which can be monitored by Cloud Functions triggers to automatically send SMS
  /// 
  /// Database: https://arogyasos-c23e6-default-rtdb.firebaseio.com/
  Future<bool> queueSMSInRealtimeDatabase({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Generate a unique key for the SMS request
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final smsId = 'sms_$timestamp';
      
      // Prepare the SMS data
      final smsData = {
        'phoneNumber': phoneNumber,
        'message': message,
        'timestamp': timestamp,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Post to Realtime Database using REST API
      final url = Uri.parse('$_realtimeDbUrl$_smsQueuePath/$smsId.json');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(smsData),
      );
      
      if (response.statusCode == 200) {
        print('SMS queued in Realtime Database: $smsId');
        return true;
      } else {
        print('Error queueing SMS: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error queueing SMS in Realtime Database: $e');
      return false;
    }
  }

  /// Send SMS to multiple recipients
  /// 
  /// [phoneNumbers] - List of recipient phone numbers
  /// [message] - The message content to send
  /// 
  /// Returns a map with phone numbers as keys and success status as values
  Future<Map<String, bool>> sendBulkSMS({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final Map<String, bool> results = {};
    
    for (final phoneNumber in phoneNumbers) {
      final success = await sendSMS(
        phoneNumber: phoneNumber,
        message: message,
      );
      results[phoneNumber] = success;
    }
    
    return results;
  }

  /// Send SMS using direct HTTP call to Cloud Function URL (alternative method)
  /// 
  /// Use this if you prefer HTTP calls instead of the Functions SDK
  /// [functionUrl] - The HTTPS URL of your Cloud Function
  /// [phoneNumber] - The recipient phone number
  /// [message] - The message content
  /// 
  /// Returns true if SMS was sent successfully, false otherwise
  Future<bool> sendSMSViaHTTP({
    required String functionUrl,
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['success'] == true;
      } else {
        print('HTTP Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending SMS via HTTP: $e');
      return false;
    }
  }
}

