import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/first_aid_guide.dart';
import '../services/firebase_service.dart';

class FirstAidGuidesScreen extends StatefulWidget {
  const FirstAidGuidesScreen({super.key});

  @override
  State<FirstAidGuidesScreen> createState() => _FirstAidGuidesScreenState();
}

class _FirstAidGuidesScreenState extends State<FirstAidGuidesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedLanguage = 'English';
  String? _selectedCategory = 'All Categories';
  Map<String, bool> _downloadStatus = {};

  @override
  void initState() {
    super.initState();
    _loadDownloadStatus();
  }

  // Load download status from SharedPreferences
  Future<void> _loadDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, bool> status = {};
    for (var key in keys) {
      if (key.startsWith('guide_download_')) {
        final guideId = key.replaceFirst('guide_download_', '');
        status[guideId] = prefs.getBool(key) ?? false;
      }
    }
    setState(() {
      _downloadStatus = status;
    });
  }

  // Save download status to SharedPreferences
  Future<void> _saveDownloadStatus(String guideId, bool isDownloaded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guide_download_$guideId', isDownloaded);
    setState(() {
      _downloadStatus[guideId] = isDownloaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Guides'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                      hint: const Text('English'),
                      value: _selectedLanguage,
                      items: <String>['English', 'Hindi', 'Marathi']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLanguage = newValue;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      hint: const Text('All Categories'),
                      value: _selectedCategory,
                      items: <String>['All Categories', 'Emergency', 'Poisoning', 'Breathing', 'Cardiac']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<List<FirstAidGuide>>(
              stream: _firebaseService.getFirstAidGuides(
                language: _selectedLanguage,
                category: _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading guides: ${snapshot.error}',
                            style: TextStyle(color: Colors.red[700]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.book_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No guides found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final guides = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: guides.length,
                  itemBuilder: (context, index) {
                    final guide = guides[index];
                    final isDownloaded = _downloadStatus[guide.id] ?? false;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDownloaded ? Icons.check_circle : Icons.warning_amber,
                              color: isDownloaded ? Colors.green : Colors.orange.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                guide.title,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...guide.tags.map((tag) => Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 10)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.grey[700], size: 20),
                            const SizedBox(width: 8),
                            Text('Offline Guide - ${guide.size}'),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                _saveDownloadStatus(guide.id, !isDownloaded);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isDownloaded
                                        ? '${guide.title} removed from offline.'
                                        : '${guide.title} downloaded for offline access.'),
                                  ),
                                );
                              },
                              icon: Icon(isDownloaded ? Icons.delete_outline : Icons.download, size: 18),
                              label: Text(isDownloaded ? 'Remove' : 'Download'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDownloaded ? Colors.red.shade100 : Colors.green.shade100,
                                foregroundColor: isDownloaded ? Colors.red.shade800 : Colors.green.shade800,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        if (isDownloaded) ...[ // Only show these if downloaded
                          const SizedBox(height: 12),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Icon(Icons.list_alt, color: Colors.grey[700], size: 20),
                                const SizedBox(width: 8),
                                Text('Treatment Steps (${guide.steps})'),
                              ],
                            ),
                            children: guide.treatmentContent.map((step) =>
                                Padding(
                                  padding: const EdgeInsets.only(left: 36.0, bottom: 8.0),
                                  child: Text(step),
                                ),
                            ).toList(),
                          ),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text('Important Warnings (${guide.warnings})'),
                              ],
                            ),
                            children: guide.warningContent.map((warning) =>
                                Padding(
                                  padding: const EdgeInsets.only(left: 36.0, bottom: 8.0),
                                  child: Text(warning, style: TextStyle(color: Colors.red[800])),
                                ),
                            ).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
                  },
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