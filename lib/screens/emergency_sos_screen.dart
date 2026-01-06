import 'package:flutter/material.dart';
import 'dart:async'; // Required for Timer
import 'package:url_launcher/url_launcher.dart'; // Import for url_launcher
import 'package:geolocator/geolocator.dart'; // Correct import for geolocator
import 'package:geocoding/geocoding.dart'; // Import for geocoding
import 'package:shared_preferences/shared_preferences.dart'; // Import for shared_preferences
import 'package:arogya_sos_app/services/firebase_fcm_service.dart'; // Import Firebase FCM service

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  bool _isSendingAlert = false;
  int _countdown = 10;
  Timer? _timer;
  String _currentLocation = 'Fetching location...'; // To display current location (address)
  String _currentCoordinates = ''; // To display coordinates (latitude, longitude)
  String _areaName = ''; // To display area name separately
  final FirebaseFCMService _fcmService = FirebaseFCMService(); // Firebase FCM service instance

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Fetch location when screen initializes
    _initializeFCM(); // Initialize FCM service
  }

  // Initialize FCM and request permissions
  Future<void> _initializeFCM() async {
    try {
      // Setup foreground message handler
      _fcmService.setupForegroundMessageHandler();
      
      // Request FCM token for this device
      final token = await _fcmService.getFCMToken();
      if (token != null) {
        debugPrint('FCM token obtained: $token');
      } else {
        debugPrint('FCM token not available');
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  // Method to get current location and perform reverse geocoding
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _currentLocation = 'Location services are disabled. Please enable them.';
          _currentCoordinates = '';
          _areaName = '';
        });
      }
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _currentLocation = 'Location permissions are denied. Please grant them in settings.';
            _currentCoordinates = '';
            _areaName = '';
          });
        }
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _currentLocation = 'Location permissions are permanently denied. Cannot access location.';
          _currentCoordinates = '';
          _areaName = '';
        });
      }
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Try for high accuracy
        timeLimit: const Duration(seconds: 15), // Set a timeout for location acquisition
      );

      if (mounted) {
        setState(() {
          _currentCoordinates = '${position.latitude}, ${position.longitude}';
          _currentLocation = 'Getting address...'; // Update status while geocoding
        });
      }

      // Save location coordinates to shared_preferences for use in other screens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_latitude', position.latitude);
      await prefs.setDouble('user_longitude', position.longitude);

      // Perform reverse geocoding (convert coordinates to address)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
          // Removed 'localeIdentifier' as it's no longer a valid parameter in newer geocoding versions
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          if (mounted) {
            setState(() {
              // Extract area name (prioritize subLocality, then locality, then administrativeArea)
              _areaName = place.subLocality?.isNotEmpty == true
                  ? place.subLocality!
                  : (place.locality?.isNotEmpty == true
                      ? place.locality!
                      : (place.administrativeArea?.isNotEmpty == true
                          ? place.administrativeArea!
                          : ''));

              // Construct the address string, handling potential null values defensively
              String address = '${place.street ?? ''}, '
                               '${place.subLocality ?? ''}, '
                               '${place.locality ?? ''}, '
                               '${place.postalCode ?? ''}, '
                               '${place.country ?? ''}';

              // Clean up any extraneous commas or leading/trailing commas due to nulls
              address = address.replaceAll(RegExp(r',\s*,|\s*$|^,\s*'), '').trim();
              // Remove multiple spaces that might result from concatenation
              address = address.replaceAll(RegExp(r'\s+'), ' ');

              // Corrected assignment for _currentLocation
              _currentLocation = address.isEmpty ? 'Address not found for these coordinates.' : address;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _currentLocation = 'Address not found for these coordinates.';
              _areaName = '';
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _currentLocation = 'Geocoding error: ${e.toString()}'; // Display geocoding specific error
            _areaName = '';
          });
        }
      }
    } catch (e) {
      // Catch any errors during location acquisition itself (e.g., timeout)
      if (mounted) {
        setState(() {
          _currentLocation = 'Failed to get location: ${e.toString()}';
          _currentCoordinates = '';
          _areaName = '';
        });
      }
    }
  }

  // Method to make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Handle error, e.g., show a SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch call to $phoneNumber')),
        );
      }
    }
  }


  // Load medical information from SharedPreferences
  Future<String> _loadMedicalInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? bloodType = prefs.getString('bloodType');
      final String? allergies = prefs.getString('allergies');
      final String? medications = prefs.getString('medications');
      final String? conditions = prefs.getString('conditions');

      List<String> medicalInfoParts = [];
      if (bloodType != null && bloodType.isNotEmpty) {
        medicalInfoParts.add('Blood Type: $bloodType');
      }
      if (allergies != null && allergies.isNotEmpty) {
        medicalInfoParts.add('Allergies: $allergies');
      }
      if (medications != null && medications.isNotEmpty) {
        medicalInfoParts.add('Medications: $medications');
      }
      if (conditions != null && conditions.isNotEmpty) {
        medicalInfoParts.add('Medical Conditions: $conditions');
      }

      if (medicalInfoParts.isEmpty) {
        return 'Medical Info: Not provided';
      }
      return medicalInfoParts.join('. ');
    } catch (e) {
      debugPrint('Error loading medical info: $e');
      return 'Medical Info: Not available';
    }
  }

  // Triggers the actual emergency alert (sending FCM notifications)
  void _triggerEmergencyAlert() async {
    // Construct a comprehensive message including the location
    final String locationLink = _currentCoordinates.isNotEmpty
        ? 'https://www.google.com/maps/search/?api=1&query=$_currentCoordinates' // Google Maps link
        : 'Location unavailable.';

    // Load medical info from SharedPreferences
    final String medicalInfo = await _loadMedicalInfo();
    
    // Load user's name from profile
    final prefs = await SharedPreferences.getInstance();
    final String? firstName = prefs.getString('firstName');
    final String? lastName = prefs.getString('lastName');
    final String userName = (firstName != null && firstName.isNotEmpty || lastName != null && lastName.isNotEmpty)
        ? '${firstName ?? ''} ${lastName ?? ''}'.trim()
        : 'User';

    final String fullAlertMessage =
        '🚨 EMERGENCY ALERT 🚨\n\n'
        'This is $userName. I need immediate help!\n\n'
        '📍 Location: $_currentLocation\n'
        '🗺️ Map Link: $locationLink\n'
        '📱 Coordinates: $_currentCoordinates\n\n'
        '🏥 $medicalInfo\n\n'
        'Please send help immediately!';

    // Send SOS notification via FCM to emergency contacts
    bool success = false;

    try {
      // Queue SOS notification in Realtime Database
      // Cloud Functions will process this and send FCM notifications to all registered emergency contacts
      success = await _fcmService.sendSOSNotification(
        message: fullAlertMessage,
        location: _currentLocation,
        coordinates: _currentCoordinates,
        medicalInfo: medicalInfo,
        userName: userName,
        locationLink: locationLink,
      );
      
      if (success) {
        debugPrint('Emergency SOS notification queued successfully');
      } else {
        debugPrint('Failed to queue emergency SOS notification');
      }
    } catch (e) {
      debugPrint('Error sending SOS notification: $e');
      success = false;
    }

    // Show a confirmation to the user
    if (mounted) {
      final String message = success
          ? 'Emergency SOS notification sent to emergency contacts'
          : 'Failed to send emergency alert. Please try calling directly.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Starts the countdown for the emergency alert
  void _startEmergency() {
    setState(() {
      _isSendingAlert = true;
      _countdown = 10; // Reset countdown
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        _timer?.cancel(); // Stop the timer
        if (mounted) {
          setState(() {
            _isSendingAlert = false; // Stop alert state
          });
        }
        _triggerEmergencyAlert(); // Trigger actual alert after countdown
      }
    });
  }

  // Cancels the ongoing emergency countdown
  void _cancelEmergency() {
    _timer?.cancel(); // Stop the timer
    if (mounted) {
      setState(() {
        _isSendingAlert = false; // Reset alert state
        _countdown = 10; // Reset countdown
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency alert cancelled.')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: const Text('Online', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Tap the button below for immediate help',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Location',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          // Display area name prominently if available
                          if (_areaName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                _areaName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          // Display fetched location (address)
                          Text(
                            _currentLocation,
                            style: const TextStyle(fontSize: 14),
                          ),
                          // Display fetched coordinates
                          Text(
                            _currentCoordinates,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: _isSendingAlert ? null : _startEmergency,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isSendingAlert ? 180 : 200,
                  height: _isSendingAlert ? 180 : 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isSendingAlert
                          ? [Colors.red.shade700, Colors.red.shade900]
                          : [Colors.red.shade400, Colors.red.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade400,
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isSendingAlert
                          ? Text(
                              '$_countdown',
                              style: const TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          : const Icon(
                              Icons.warning_amber,
                              color: Colors.white,
                              size: 60,
                            ),
                      const SizedBox(height: 8),
                      Text(
                        _isSendingAlert ? 'Sending Alert...' : 'SOS\nEmergency',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isSendingAlert)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: OutlinedButton(
                    onPressed: _cancelEmergency,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: const Text(
                      'Cancel Emergency',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Quick Emergency Contacts',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall('108'), // Make ambulance call
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text('108\nAmbulance',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall('100'), // Make police call
                      icon: const Icon(Icons.local_police, color: Colors.white),
                      label: const Text('100\nPolice',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 2,
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'While waiting for help:',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check for consciousness, breathing, and pulse. Apply pressure to any bleeding wounds. Keep the person warm and comfortable.',
                            style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}