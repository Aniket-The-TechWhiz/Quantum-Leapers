import 'package:flutter/material.dart';
import 'dart:async'; // Import for StreamSubscription
import 'package:url_launcher/url_launcher.dart'; // Import for url_launcher
import 'package:geolocator/geolocator.dart'; // Import for geolocator
import 'package:shared_preferences/shared_preferences.dart'; // Import for shared_preferences
import 'package:firebase_database/firebase_database.dart'; // Fetch pharmacies from Firebase RTDB
import 'package:firebase_core/firebase_core.dart'; // Required for Firebase.app() in instanceFor

class MedicineFinderScreen extends StatefulWidget {
  const MedicineFinderScreen({super.key});

  @override
  State<MedicineFinderScreen> createState() => _MedicineFinderScreenState();
}

class _MedicineFinderScreenState extends State<MedicineFinderScreen> {
  double? _userLatitude;
  double? _userLongitude;
  String? _selectedDistanceFilter;
  bool _showOpenOnly = false;
  bool _isLoadingLocation = true;
  bool _isLoadingPharmacies = true;
  String? _pharmacyError;
  List<Map<String, dynamic>> _pharmacies = [];
  StreamSubscription<DatabaseEvent>? _pharmaciesSubscription;
  StreamSubscription<DatabaseEvent>? _pharmaciesChildChangedSubscription;
  // Explicitly bind to the project's RTDB instance (avoids using a wrong/default URL)
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://arogyasos-c23e6-default-rtdb.firebaseio.com',
  );

  @override
  void initState() {
    super.initState();
    _initializeDatabase(); // Ensure live reads (no disk cache) before fetching
  }

  @override
  void dispose() {
    _pharmaciesSubscription?.cancel(); // Cancel pharmacy listener when widget is disposed
    _pharmaciesChildChangedSubscription?.cancel();
    super.dispose();
  }

  // Initialize RTDB without disk caching, then start fetching/listening
  Future<void> _initializeDatabase() async {
    try {
      _database.setPersistenceEnabled(false);
    } catch (e) {
      debugPrint('Failed to disable RTDB persistence: $e');
    }

    // Start operations after persistence setting is applied
    _getUserLocation();
    _fetchPharmacies();
    _setupPharmaciesListener(); // Setup real-time listener for pharmacies
  }

  // Setup real-time listener for pharmacies data changes
  void _setupPharmaciesListener() {
    // Avoid local caching; always read directly from the backend
    final pharmaciesRef = _database.ref('pharmacies');
    
    // Listen to value changes (updates when any pharmacy data changes)
    _pharmaciesSubscription = pharmaciesRef.onValue.listen(
      (DatabaseEvent event) {
        try {
          final List<Map<String, dynamic>> pharmaciesList =
              _parsePharmaciesSnapshot(event.snapshot.value);

          if (mounted) {
            setState(() {
              _pharmacies = pharmaciesList;
              _isLoadingPharmacies = false;
              _pharmacyError = null;
              _sortByDistance();
            });
          }
        } catch (e) {
          debugPrint('Error parsing pharmacies snapshot: $e');
          if (mounted) {
            setState(() {
              _pharmacyError = 'Error parsing pharmacy updates: $e';
              _isLoadingPharmacies = false;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('Error listening to pharmacies: $error');
        if (mounted) {
          setState(() {
            _pharmacyError = 'Error listening to pharmacy updates: $error';
          });
        }
      },
    );

    // Fallback: explicitly handle child updates (covers partial writes)
    _pharmaciesChildChangedSubscription = pharmaciesRef.onChildChanged.listen(
      (DatabaseEvent event) {
        final key = event.snapshot.key;
        final value = event.snapshot.value;
        if (key == null || value is! Map) return;

        final index = _pharmacies.indexWhere((p) => p['id'] == key.toString());
        final updated = _parsePharmacyNode(key, value);
        if (index >= 0) {
          setState(() {
            _pharmacies[index] = updated;
            _isLoadingPharmacies = false;
            _pharmacyError = null;
            _sortByDistance();
          });
        }
      },
      onError: (error) {
        debugPrint('Error onChildChanged pharmacies: $error');
      },
    );
  }

  // Method to get user location from shared_preferences or GPS
  Future<void> _getUserLocation() async {
    try {
      // First try to get from shared_preferences (saved from emergency SOS screen)
      final prefs = await SharedPreferences.getInstance();
      final savedLat = prefs.getDouble('user_latitude');
      final savedLng = prefs.getDouble('user_longitude');

      if (savedLat != null && savedLng != null) {
      setState(() {
        _userLatitude = savedLat;
        _userLongitude = savedLng;
        _isLoadingLocation = false;
      });
      return;
      }

      // If not in shared_preferences, get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _isLoadingLocation = false;
      });

      // Save to shared_preferences for future use
      await prefs.setDouble('user_latitude', position.latitude);
      await prefs.setDouble('user_longitude', position.longitude);
      
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Convert raw RTDB payload (Map/List) into a pharmacy list the UI expects
  List<Map<String, dynamic>> _parsePharmaciesSnapshot(dynamic raw) {
    if (raw == null) return [];

    // RTDB can return a Map (recommended) or List (array-like). Normalize to Map.
    Map<dynamic, dynamic> pharmaciesData = {};
    if (raw is Map<dynamic, dynamic>) {
      pharmaciesData = raw;
    } else if (raw is List<dynamic>) {
      pharmaciesData = raw.asMap().map((key, value) => MapEntry(key, value));
    }

    final List<Map<String, dynamic>> pharmaciesList = [];

    pharmaciesData.forEach((key, value) {
      if (value is Map) {
        pharmaciesList.add(_parsePharmacyNode(key, value));
      }
    });

    return pharmaciesList;
  }

  Map<String, dynamic> _parsePharmacyNode(dynamic key, Map value) {
    final pharmacy = Map<String, dynamic>.from(value);
    final location = pharmacy['location'] as Map<dynamic, dynamic>?;
    final distanceValue = pharmacy['distance'] ??
        pharmacy['distanceKm'] ??
        pharmacy['distance_km'] ??
        pharmacy['distance_kms'];
    final double? distance = _toDouble(distanceValue);
    final distanceText = pharmacy['distanceText'] ?? pharmacy['distance_text'];

    double? latitude;
    double? longitude;
    if (location != null) {
      latitude = (location['latitude'] as num?)?.toDouble();
      longitude = (location['longitude'] as num?)?.toDouble();
    }

    final isOpenRaw = pharmacy['isOpen'];
    final isOpen = isOpenRaw == true || isOpenRaw == 'true';

    return {
      'id': pharmacy['id'] ?? key.toString(),
      'name': pharmacy['name'] ?? 'Unknown Pharmacy',
      'address': pharmacy['address'] ?? 'Address not available',
      'rating': (pharmacy['rating'] ?? 0.0).toString(),
      'status': isOpen ? 'Open' : 'Closed',
      'statusColor': isOpen ? Colors.green : Colors.red,
      'phone': pharmacy['contactNumber'] ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'distanceString': distance != null
          ? _formatDistance(distance)
          : (distanceText ?? 'Distance unknown'),
      'distanceText': distanceText ?? 'Distance unknown',
    };
  }

  // Format distance for display
  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m away';
    } else {
      return '${distance.toStringAsFixed(1)} km away';
    }
  }

  // Method to fetch pharmacies from Firebase Realtime Database
  Future<void> _fetchPharmacies() async {
    try {
      setState(() {
        _isLoadingPharmacies = true;
        _pharmacyError = null;
      });

      final DatabaseReference pharmaciesRef = _database.ref('pharmacies');
      final DataSnapshot snapshot = await pharmaciesRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final pharmaciesList = _parsePharmaciesSnapshot(snapshot.value);

        setState(() {
          _pharmacies = pharmaciesList;
          _isLoadingPharmacies = false;
        });

        // Sort by distance coming from backend
        _sortByDistance();
      } else {
        setState(() {
          _pharmacies = [];
          _isLoadingPharmacies = false;
          _pharmacyError = 'No pharmacies found in database';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPharmacies = false;
        _pharmacyError = 'Error fetching pharmacies: $e';
        _pharmacies = [];
      });
    }
  }

  // Sort pharmacies by the backend-provided distance field (km)
  void _sortByDistance() {
    _pharmacies.sort((a, b) {
      final double distA = a['distance'] as double? ?? 999.0;
      final double distB = b['distance'] as double? ?? 999.0;
      return distA.compareTo(distB);
    });
  }


  // Method to make a phone call
  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch call to $phoneNumber')),
        );
      }
    }
  }

  // Method to navigate to a location using a mapping app
  Future<void> _navigateToPharmacy(
      String address, double? latitude, double? longitude, BuildContext context) async {
    // Prefer coordinates if available, otherwise use address
    String query;
    if (latitude != null && longitude != null) {
      query = '$latitude,$longitude';
    } else {
      query = address;
    }

    final Uri launchUri = Uri.parse('google.navigation:q=$query&mode=d'); // 'd' for driving mode

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Fallback for when specific map app isn't found or if on iOS (use general scheme)
      final Uri webLaunchUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      if (await canLaunchUrl(webLaunchUri)) {
        await launchUrl(webLaunchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch maps for $address')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a filtered list from fetched pharmacies
    List<Map<String, dynamic>> pharmacies = List.from(_pharmacies);

    // Ensure all pharmacies have distance values for filtering
    for (var pharmacy in pharmacies) {
      if (!pharmacy.containsKey('distance')) {
        pharmacy['distance'] = 999.0;
      }
      if (!pharmacy.containsKey('distanceString')) {
        pharmacy['distanceString'] = pharmacy['distanceText'] ?? 'Distance unknown';
      }
    }

    // Apply distance filter
    if (_selectedDistanceFilter != null) {
      double maxDistance = double.parse(_selectedDistanceFilter!.replaceAll(' km', ''));
      pharmacies = pharmacies.where((pharmacy) {
        final double distance = pharmacy['distance'] as double? ?? 999.0;
        return distance <= maxDistance;
      }).toList();
    }

    // Apply open only filter
    if (_showOpenOnly) {
      pharmacies = pharmacies.where((pharmacy) {
        return pharmacy['status'] == 'Open';
      }).toList();
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Finder'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for medicines (e.g., Antivenom, Paracetamol)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
                onChanged: (query) {
                  // In a real app, you would filter the 'pharmacies' list based on 'query'
                  // and potentially search for specific medicines if you had that data.
                  // For this demo, we're not implementing search logic on the mock data.
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Distance'),
                      value: _selectedDistanceFilter,
                      items: <String>['1 km', '5 km', '10 km', '20 km']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDistanceFilter = newValue;
                        });
                        _sortByDistance();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showOpenOnly = !_showOpenOnly;
                        });
                      },
                      icon: Icon(
                        _showOpenOnly ? Icons.check_circle : Icons.access_time,
                        color: _showOpenOnly ? Colors.green : Colors.black87,
                      ),
                      label: Text(
                        'Open Only',
                        style: TextStyle(
                          color: _showOpenOnly ? Colors.green : Colors.black87,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showOpenOnly ? Colors.green.shade50 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoadingPharmacies)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_pharmacyError != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _pharmacyError!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                        TextButton(
                          onPressed: _fetchPharmacies,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby Pharmacies (${pharmacies.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_userLatitude != null && _userLongitude != null)
                    Chip(
                      avatar: Icon(Icons.location_on, size: 16, color: Colors.blue.shade700),
                      label: const Text('Sorted by distance'),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Common Emergency Medicines:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: const [
                  Chip(label: Text('Antivenom')),
                  Chip(label: Text('Paracetamol')),
                  Chip(label: Text('Aspirin')),
                  Chip(label: Text('Insulin')),
                  Chip(label: Text('Ventolin')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingLocation)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_userLatitude == null || _userLongitude == null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.location_off, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Location unavailable. Showing all pharmacies.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isLoadingPharmacies)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading pharmacies...'),
                    ],
                  ),
                ),
              )
            else if (_pharmacyError != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _pharmacyError!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            _fetchPharmacies();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (pharmacies.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_pharmacy_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _pharmacies.isEmpty
                            ? 'No pharmacies found in database.'
                            : 'No pharmacies found matching your filters.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pharmacies.length, // Use the actual length of the mock data
              itemBuilder: (context, index) {
                final pharmacy = pharmacies[index];

                final double distance = pharmacy['distance'] as double? ?? 999.0;
                final bool isNearby = distance <= 2.0; // Highlight if within 2km
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  elevation: isNearby ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isNearby 
                        ? BorderSide(color: Colors.green.shade300, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (isNearby)
                                    Icon(
                                      Icons.near_me,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                  if (isNearby) const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      pharmacy['name'] as String,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isNearby ? Colors.green.shade900 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(
                                pharmacy['status'] as String,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor: pharmacy['statusColor'] as Color,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.blue.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    pharmacy['distanceString'] as String? ?? 'Distance unknown',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    pharmacy['rating'] as String,
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.place, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pharmacy['address'] as String,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _makePhoneCall(
                                    pharmacy['phone'] as String, context), // Make call
                                icon: const Icon(Icons.call, color: Colors.blue),
                                label: const Text('Call', style: TextStyle(color: Colors.blue)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToPharmacy(
                                  pharmacy['address'] as String,
                                  pharmacy['latitude'] as double?,
                                  pharmacy['longitude'] as double?,
                                  context,
                                ), // Navigate
                                icon: const Icon(Icons.navigation, color: Colors.white),
                                label: const Text('Navigate', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}