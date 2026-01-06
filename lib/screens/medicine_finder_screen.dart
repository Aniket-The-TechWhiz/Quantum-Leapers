import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for url_launcher
import 'package:geolocator/geolocator.dart'; // Import for geolocator
import 'package:shared_preferences/shared_preferences.dart'; // Import for shared_preferences
import 'dart:math' as math; // Import for distance calculation

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

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of the earth in km
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadius * c; // Distance in km
    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Format distance for display
  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m away';
    } else {
      return '${distance.toStringAsFixed(1)} km away';
    }
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
    // Pharmacy data with coordinates (latitude, longitude)
    // These are example coordinates for Mumbai area - in a real app, these would come from an API
    List<Map<String, dynamic>> pharmacies = [
      {
        'name': 'Apollo Pharmacy',
        'latitude': 19.0596,
        'longitude': 72.8295,
        'rating': '4.5',
        'address': 'Shop No. 12, Linking Road, Bandra West, Mumbai',
        'status': 'Open',
        'statusColor': Colors.green,
        'phone': '9876543210',
      },
      {
        'name': 'MedPlus Pharmacy',
        'latitude': 19.0550,
        'longitude': 72.8260,
        'rating': '4.2',
        'address': 'Ground Floor, Hill Road, Bandra West, Mumbai',
        'status': 'Open',
        'statusColor': Colors.green,
        'phone': '9876543211',
      },
      {
        'name': '1mg Pharmacy',
        'latitude': 19.0520,
        'longitude': 72.8280,
        'rating': '4.3',
        'address': 'Turner Road, Bandra West, Mumbai',
        'status': 'Closed',
        'statusColor': Colors.red,
        'phone': '9876543212',
      },
      {
        'name': 'Wellness Forever',
        'latitude': 19.0650,
        'longitude': 72.8320,
        'rating': '4.6',
        'address': 'Main Road, Khar West, Mumbai',
        'status': 'Open',
        'statusColor': Colors.green,
        'phone': '9876543213',
      },
      {
        'name': 'Fortis Pharmacy',
        'latitude': 19.0700,
        'longitude': 72.8400,
        'rating': '4.4',
        'address': 'SV Road, Santacruz West, Mumbai',
        'status': 'Open',
        'statusColor': Colors.green,
        'phone': '9876543214',
      },
      {
        'name': 'Guardian Pharmacy',
        'latitude': 19.0450,
        'longitude': 72.8200,
        'rating': '4.7',
        'address': 'Waterfield Road, Bandra West, Mumbai',
        'status': 'Open',
        'statusColor': Colors.green,
        'phone': '9876543215',
      },
    ];

    // Calculate distances and add to pharmacy data if user location is available
    if (_userLatitude != null && _userLongitude != null) {
      for (var pharmacy in pharmacies) {
        double distance = _calculateDistance(
          _userLatitude!,
          _userLongitude!,
          pharmacy['latitude'] as double,
          pharmacy['longitude'] as double,
        );
        pharmacy['distance'] = distance;
        pharmacy['distanceString'] = _formatDistance(distance);
      }

      // Sort pharmacies by distance
      pharmacies.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    } else {
      // If no location, use default distance strings
      for (var pharmacy in pharmacies) {
        pharmacy['distance'] = 999.0; // Large number for sorting
        pharmacy['distanceString'] = 'Distance unknown';
      }
    }

    // Apply distance filter
    if (_selectedDistanceFilter != null) {
      double maxDistance = double.parse(_selectedDistanceFilter!.replaceAll(' km', ''));
      pharmacies = pharmacies.where((pharmacy) {
        return (pharmacy['distance'] as double) <= maxDistance;
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
            if (pharmacies.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No pharmacies found matching your filters.'),
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