import 'package:flutter/material.dart';
import 'package:arogya_sos_app/widgets/custom_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'dart:convert'; // Required for jsonEncode/jsonDecode

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactRelationshipController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  String? _selectedBloodType;
  bool _emergencyNotificationsEnabled = true;
  bool _locationSharingEnabled = true;

  List<Map<String, String>> _emergencyContacts = []; // Initialize as empty

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Load data when the screen initializes
  }

  // Method to load profile data from SharedPreferences
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('firstName') ?? '';
      _lastNameController.text = prefs.getString('lastName') ?? '';
      _phoneController.text = prefs.getString('phoneNumber') ?? '';
      _addressController.text = prefs.getString('address') ?? '';
      _allergiesController.text = prefs.getString('allergies') ?? '';
      _medicationsController.text = prefs.getString('medications') ?? '';
      _conditionsController.text = prefs.getString('conditions') ?? '';
      _selectedBloodType = prefs.getString('bloodType');
      _emergencyNotificationsEnabled = prefs.getBool('emergencyNotifications') ?? true;
      _locationSharingEnabled = prefs.getBool('locationSharing') ?? true;

      final String? contactsJson = prefs.getString('emergencyContacts');
      if (contactsJson != null) {
        // Decode the JSON string back to a List<dynamic>
        final List<dynamic> decodedList = jsonDecode(contactsJson);
        // Map each dynamic item to Map<String, String>
        _emergencyContacts = decodedList.map((item) => Map<String, String>.from(item)).toList();
      }
    });
  }

  // Method to save profile data to SharedPreferences
  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', _firstNameController.text);
    await prefs.setString('lastName', _lastNameController.text);
    await prefs.setString('phoneNumber', _phoneController.text);
    await prefs.setString('address', _addressController.text);
    await prefs.setString('allergies', _allergiesController.text);
    await prefs.setString('medications', _medicationsController.text);
    await prefs.setString('conditions', _conditionsController.text);
    if (_selectedBloodType != null) {
      await prefs.setString('bloodType', _selectedBloodType!);
    } else {
      await prefs.remove('bloodType');
    }
    await prefs.setBool('emergencyNotifications', _emergencyNotificationsEnabled);
    await prefs.setBool('locationSharing', _locationSharingEnabled);

    // Encode List<Map<String, String>> to JSON string
    await prefs.setString('emergencyContacts', jsonEncode(_emergencyContacts));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
    }
  }

  void _addEmergencyContact() {
    if (_contactNameController.text.isNotEmpty &&
        _contactRelationshipController.text.isNotEmpty &&
        _contactPhoneController.text.isNotEmpty) {
      setState(() {
        _emergencyContacts.add({
          'name': _contactNameController.text,
          'relationship': _contactRelationshipController.text,
          'phone': _contactPhoneController.text,
        });
        _contactNameController.clear();
        _contactRelationshipController.clear();
        _contactPhoneController.clear();
      });
      _saveProfileData(); // Save data after adding a contact
    }
  }

  void _deleteEmergencyContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
    _saveProfileData(); // Save data after deleting a contact
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _conditionsController.dispose();
    _contactNameController.dispose();
    _contactRelationshipController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfileData, // Save button
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
                'Manage your emergency settings and contacts',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: CustomTextField(label: 'First Name', controller: _firstNameController)),
                        const SizedBox(width: 16),
                        Expanded(child: CustomTextField(label: 'Last Name', controller: _lastNameController)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(label: 'Phone Number', controller: _phoneController),
                    const SizedBox(height: 16),
                    CustomTextField(label: 'Address', controller: _addressController),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 10),
                        Text(
                          'Medical Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Blood Type', style: TextStyle(color: Colors.grey[700])),
                    DropdownButtonFormField<String>(
                      value: _selectedBloodType,
                      hint: const Text('Select blood type'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: <String>['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBloodType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(label: 'Allergies', controller: _allergiesController, hint: 'List any allergies (e.g., peanuts, penicillin)'),
                    const SizedBox(height: 16),
                    CustomTextField(label: 'Current Medications', controller: _medicationsController, hint: 'List current medications'),
                    const SizedBox(height: 16),
                    CustomTextField(label: 'Medical Conditions', controller: _conditionsController, hint: 'List any medical conditions'),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.call, color: Colors.green),
                        const SizedBox(width: 10),
                        Text(
                          'Emergency Contacts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_emergencyContacts.isEmpty)
                      const Text('No emergency contacts added yet.'),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _emergencyContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _emergencyContacts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.orange.shade200,
                                child: Icon(Icons.person, color: Colors.orange.shade800),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact['name']!,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      contact['relationship']!,
                                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                    ),
                                    Text(
                                      contact['phone']!,
                                      style: TextStyle(color: Colors.blue.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.grey[600]),
                                onPressed: () => _deleteEmergencyContact(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        _showAddContactDialog(context);
                      },
                      icon: const Icon(Icons.add, color: Colors.green),
                      label: const Text(
                        'Add Emergency Contact',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.teal),
                        const SizedBox(width: 10),
                        Text(
                          'App Settings',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Language', style: TextStyle(color: Colors.grey[700])),
                    DropdownButtonFormField<String>(
                      value: 'English',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: <String>['English', 'Hindi', 'Marathi']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        // Handle language change
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchListTile(
                      icon: Icons.notifications,
                      title: 'Emergency Notifications',
                      subtitle: 'Receive alerts and updates',
                      value: _emergencyNotificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _emergencyNotificationsEnabled = value;
                          _saveProfileData(); // Save setting on change
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchListTile(
                      icon: Icons.location_on,
                      title: 'Location Sharing',
                      subtitle: 'Share location in emergencies',
                      value: _locationSharingEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _locationSharingEnabled = value;
                          _saveProfileData(); // Save setting on change
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.privacy_tip, color: Colors.purple),
                        const SizedBox(width: 10),
                        Text(
                          'Data & Privacy',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.green.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your medical data is stored locally on your device for privacy and offline access.',
                              style: TextStyle(color: Colors.green.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement export data functionality (e.g., save to file)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Export Data functionality not yet implemented.')),
                              );
                            },
                            icon: const Icon(Icons.download, color: Colors.blue),
                            label: const Text('Export Data', style: TextStyle(color: Colors.blue)),
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
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear(); // Clears all saved preferences
                              _loadProfileData(); // Reload UI to reflect cleared data
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All local data cleared.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Clear Data', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
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
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 30),
                    const SizedBox(height: 8),
                    const Text(
                      'Emergency Medical App v1.0',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'For emergency situations, always call 108',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        children: const [
                          TextSpan(text: 'Made with '),
                          TextSpan(
                            text: '❤️',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                          TextSpan(text: ' for your safety'),
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

  Widget _buildSwitchListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Text('Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Using CustomTextField directly
                CustomTextField(label: 'Name', controller: _contactNameController),
                const SizedBox(height: 16),
                CustomTextField(label: 'Relationship (e.g., Spouse, Doctor)', controller: _contactRelationshipController),
                const SizedBox(height: 16),
                CustomTextField(label: 'Phone Number', controller: _contactPhoneController, keyboardType: TextInputType.phone),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _contactNameController.clear();
                _contactRelationshipController.clear();
                _contactPhoneController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addEmergencyContact();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('Add Contact', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}