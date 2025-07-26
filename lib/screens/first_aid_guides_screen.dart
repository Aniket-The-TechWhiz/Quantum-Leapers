import 'package:flutter/material.dart';

class FirstAidGuidesScreen extends StatefulWidget {
  const FirstAidGuidesScreen({super.key});

  @override
  State<FirstAidGuidesScreen> createState() => _FirstAidGuidesScreenState();
}

class _FirstAidGuidesScreenState extends State<FirstAidGuidesScreen> {
  // A map to store the download status of each guide, using its title as a key.
  // In a real app, this would be persisted (e.g., using shared_preferences or a database).
  final Map<String, bool> _downloadStatus = {};

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> guides = [
      {
        'title': 'Snake Bite Treatment',
        'tags': ['Emergency', 'Poisoning'],
        'size': '2.5 MB',
        'steps': 7,
        'warnings': 4,
        'treatmentContent': [
          'Step 1: Keep the person calm and still. This helps slow the spread of venom.',
          'Step 2: Remove any tight clothing or jewelry from the area of the bite.',
          'Step 3: Keep the bitten limb lower than the heart.',
          'Step 4: Clean the wound with soap and water.',
          'Step 5: Cover the bite with a clean, dry dressing.',
          'Step 6: Get medical help immediately. Call emergency services.',
          'Step 7: Do NOT try to cut the bite or suck out the venom.',
        ],
        'warningContent': [
          'Warning 1: Do NOT apply ice or a tourniquet.',
          'Warning 2: Do NOT try to catch the snake.',
          'Warning 3: Do NOT drink alcohol or caffeine.',
          'Warning 4: Do NOT try to give the person pain medication unless directed by medical personnel.',
        ],
      },
      {
        'title': 'Asthma Attack Response',
        'tags': ['Emergency', 'Breathing'],
        'size': '1.8 MB',
        'steps': 6,
        'warnings': 3,
        'treatmentContent': [
          'Step 1: Help the person sit upright and loosen any tight clothing.',
          'Step 2: Help them use their inhaler (reliever puffer). Shake it well and give one puff every minute.',
          'Step 3: If no improvement after 4 puffs, or if they don\'t have an inhaler, call emergency services (e.g., 108).',
          'Step 4: Continue giving one puff of the inhaler every minute until help arrives or breathing improves.',
          'Step 5: Reassure the person and keep them calm.',
          'Step 6: Monitor their breathing and level of consciousness.',
        ],
        'warningContent': [
          'Warning 1: Do NOT leave the person alone.',
          'Warning 2: Do NOT lie the person down.',
          'Warning 3: Do NOT allow the person to panic, which can worsen the attack.',
        ],
      },
      {
        'title': 'Heart Attack First Aid',
        'tags': ['Emergency', 'Cardiac'],
        'size': '3.1 MB',
        'steps': 5,
        'warnings': 2,
        'treatmentContent': [
          'Step 1: Call emergency services immediately (e.g., 108).',
          'Step 2: Help the person to a comfortable, seated position, preferably with legs bent.',
          'Step 3: Loosen any tight clothing around their neck or chest.',
          'Step 4: If the person is conscious and not allergic, give them aspirin (chewable, 300mg if available) as directed by emergency dispatcher.',
          'Step 5: Stay with the person and reassure them until medical help arrives.',
        ],
        'warningContent': [
          'Warning 1: Do NOT let the person drive themselves to the hospital.',
          'Warning 2: Do NOT force aspirin on an unconscious person or someone who is allergic.',
        ],
      },
    ];

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
                      items: <String>['English', 'Hindi', 'Marathi']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        // Handle language change (for demo, no effect)
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
                      items: <String>['All Categories', 'Emergency', 'Poisoning', 'Breathing', 'Cardiac'] // Added Cardiac
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        // Handle category change (for demo, no effect)
                      },
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: guides.length,
              itemBuilder: (context, index) {
                final guide = guides[index];
                final isDownloaded = _downloadStatus[guide['title']] ?? false;

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
                                guide['title'] as String,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...(guide['tags'] as List<String>).map((tag) => Padding(
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
                            Text('Offline Guide - ${guide['size'] as String}'),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _downloadStatus[guide['title'] as String] = !isDownloaded;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isDownloaded
                                        ? '${guide['title']} removed from offline.'
                                        : '${guide['title']} downloaded for offline access.'),
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
                                Text('Treatment Steps (${guide['steps'] as int})'),
                              ],
                            ),
                            children: (guide['treatmentContent'] as List<String>).map((step) =>
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
                                Text('Important Warnings (${guide['warnings'] as int})'),
                              ],
                            ),
                            children: (guide['warningContent'] as List<String>).map((warning) =>
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
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}