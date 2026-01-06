import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/first_aid_guide.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'first_aid_guides';

  // Get all first aid guides
  Stream<List<FirstAidGuide>> getFirstAidGuides({String? language, String? category}) {
    Query query = _firestore.collection(_collectionName);

    // Apply language filter if provided
    if (language != null && language != 'English') {
      query = query.where('language', isEqualTo: language);
    } else {
      query = query.where('language', isEqualTo: 'English');
    }

    // Apply category filter if provided
    if (category != null && category != 'All Categories') {
      query = query.where('tags', arrayContains: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FirstAidGuide.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get a single first aid guide by ID
  Future<FirstAidGuide?> getFirstAidGuideById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return FirstAidGuide.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting first aid guide: $e');
      return null;
    }
  }

  // Add a new first aid guide
  Future<String?> addFirstAidGuide(FirstAidGuide guide) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(
        guide.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toMap(),
      );
      return docRef.id;
    } catch (e) {
      print('Error adding first aid guide: $e');
      return null;
    }
  }

  // Update an existing first aid guide
  Future<bool> updateFirstAidGuide(FirstAidGuide guide) async {
    try {
      await _firestore.collection(_collectionName).doc(guide.id).update(
        guide.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      return true;
    } catch (e) {
      print('Error updating first aid guide: $e');
      return false;
    }
  }

  // Delete a first aid guide
  Future<bool> deleteFirstAidGuide(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting first aid guide: $e');
      return false;
    }
  }

  // Initialize with default guides (run once to populate database)
  Future<void> initializeDefaultGuides() async {
    try {
      // Check if guides already exist
      final snapshot = await _firestore.collection(_collectionName).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('Default guides already exist');
        return;
      }

      // Default guides
      final defaultGuides = [
        FirstAidGuide(
          id: '',
          title: 'Snake Bite Treatment',
          tags: ['Emergency', 'Poisoning'],
          size: '2.5 MB',
          steps: 7,
          warnings: 4,
          treatmentContent: [
            'Step 1: Keep the person calm and still. This helps slow the spread of venom.',
            'Step 2: Remove any tight clothing or jewelry from the area of the bite.',
            'Step 3: Keep the bitten limb lower than the heart.',
            'Step 4: Clean the wound with soap and water.',
            'Step 5: Cover the bite with a clean, dry dressing.',
            'Step 6: Get medical help immediately. Call emergency services.',
            'Step 7: Do NOT try to cut the bite or suck out the venom.',
          ],
          warningContent: [
            'Warning 1: Do NOT apply ice or a tourniquet.',
            'Warning 2: Do NOT try to catch the snake.',
            'Warning 3: Do NOT drink alcohol or caffeine.',
            'Warning 4: Do NOT try to give the person pain medication unless directed by medical personnel.',
          ],
          language: 'English',
        ),
        FirstAidGuide(
          id: '',
          title: 'Asthma Attack Response',
          tags: ['Emergency', 'Breathing'],
          size: '1.8 MB',
          steps: 6,
          warnings: 3,
          treatmentContent: [
            'Step 1: Help the person sit upright and loosen any tight clothing.',
            'Step 2: Help them use their inhaler (reliever puffer). Shake it well and give one puff every minute.',
            'Step 3: If no improvement after 4 puffs, or if they don\'t have an inhaler, call emergency services (e.g., 108).',
            'Step 4: Continue giving one puff of the inhaler every minute until help arrives or breathing improves.',
            'Step 5: Reassure the person and keep them calm.',
            'Step 6: Monitor their breathing and level of consciousness.',
          ],
          warningContent: [
            'Warning 1: Do NOT leave the person alone.',
            'Warning 2: Do NOT lie the person down.',
            'Warning 3: Do NOT allow the person to panic, which can worsen the attack.',
          ],
          language: 'English',
        ),
        FirstAidGuide(
          id: '',
          title: 'Heart Attack First Aid',
          tags: ['Emergency', 'Cardiac'],
          size: '3.1 MB',
          steps: 5,
          warnings: 2,
          treatmentContent: [
            'Step 1: Call emergency services immediately (e.g., 108).',
            'Step 2: Help the person to a comfortable, seated position, preferably with legs bent.',
            'Step 3: Loosen any tight clothing around their neck or chest.',
            'Step 4: If the person is conscious and not allergic, give them aspirin (chewable, 300mg if available) as directed by emergency dispatcher.',
            'Step 5: Stay with the person and reassure them until medical help arrives.',
          ],
          warningContent: [
            'Warning 1: Do NOT let the person drive themselves to the hospital.',
            'Warning 2: Do NOT force aspirin on an unconscious person or someone who is allergic.',
          ],
          language: 'English',
        ),
      ];

      // Add all default guides
      for (var guide in defaultGuides) {
        await addFirstAidGuide(guide);
      }

      print('Default guides initialized successfully');
    } catch (e) {
      print('Error initializing default guides: $e');
    }
  }
}

