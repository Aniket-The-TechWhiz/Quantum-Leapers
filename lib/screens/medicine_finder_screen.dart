import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for url_launcher

class MedicineFinderScreen extends StatelessWidget {
  const MedicineFinderScreen({super.key});

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
  Future<void> _navigateToPharmacy(String address, BuildContext context) async {
    // You can encode the address for Google Maps.
    // For a real app, consider using the 'url_launcher' package's more robust map launching.
    // Example: final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    // For simplicity, directly using a generic map intent for now.
    final Uri launchUri = Uri.parse('google.navigation:q=$address&mode=d'); // 'd' for driving mode

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Fallback for when specific map app isn't found or if on iOS (use general scheme)
      final Uri webLaunchUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
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
    // Moved pharmacies list inside build method for easier access
    // This could also be a global/state variable or fetched from a service in a real app
    final pharmacies = [
      {
        'name': 'Apollo Pharmacy',
        'distance': '0.8 km away',
        'rating': '4.5',
        'address': 'Shop No. 12, Linking Road, Bandra West, Mumbai', // Added Mumbai for better navigation
        'status': 'Open',
        'statusColor': Colors.green,
        'phone': '9876543210', // Added phone number
      },
      {
        'name': 'MedPlus Pharmacy',
        'distance': '1.2 km away',
        'rating': '4.2',
        'address': 'Ground Floor, Hill Road, Bandra West, Mumbai',
        'status': 'Open',
        'statusColor': Colors.green,
        'phone': '9876543211',
      },
      {
        'name': '1mg Pharmacy',
        'distance': '1.5 km away',
        'rating': '4.3',
        'address': 'Turner Road, Bandra West, Mumbai',
        'status': 'Closed',
        'statusColor': Colors.red,
        'phone': '9876543212',
      },
      {
        'name': 'Wellness Forever',
        'distance': '2.0 km away',
        'rating': '4.6',
        'address': 'Main Road, Khar West, Mumbai',
        'status': 'Open',
        'statusColor': Colors.green,
        'phone': '9876543213',
      },
    ];


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
                      items: <String>['1 km', '5 km', '10 km', '20 km']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        // Handle distance filter change (for demo, no effect on list)
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Handle "Open Only" filter (for demo, no effect on list)
                      },
                      icon: const Icon(Icons.access_time, color: Colors.black87),
                      label: const Text('Open Only', style: TextStyle(color: Colors.black87)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pharmacies.length, // Use the actual length of the mock data
              itemBuilder: (context, index) {
                final pharmacy = pharmacies[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                pharmacy['name'] as String,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              pharmacy['distance'] as String,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              pharmacy['rating'] as String,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pharmacy['address'] as String,
                          style: TextStyle(color: Colors.grey[700]),
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
                                    pharmacy['address'] as String, context), // Navigate
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