import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:arogya_sos_app/screens/emergency_sos_screen.dart';
import 'package:arogya_sos_app/screens/medicine_finder_screen.dart';
import 'package:arogya_sos_app/screens/first_aid_guides_screen.dart';
import 'package:arogya_sos_app/screens/profile_settings_screen.dart';
import 'package:arogya_sos_app/screens/emergency_chatbot_screen.dart';

import 'package:arogya_sos_app/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    final firebaseService = FirebaseService();
    await firebaseService.initializeDefaultGuides();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Please run: flutterfire configure');
  }

  runApp(const ArogyaSOSApp());
}

class ArogyaSOSApp extends StatefulWidget {
  const ArogyaSOSApp({super.key});

  @override
  State<ArogyaSOSApp> createState() => _ArogyaSOSAppState();
}

class _ArogyaSOSAppState extends State<ArogyaSOSApp> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    EmergencySOSScreen(),
    MedicineFinderScreen(),
    FirstAidGuidesScreen(),
    ProfileSettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArogyaSOS+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        cardTheme: CardThemeData(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 2,
        ),
      ),
      home: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),

        // 🔴 FLOATING CHATBOT BUTTON (ADDED)
        floatingActionButton: Builder(
          builder: (innerContext) => FloatingActionButton(
            backgroundColor: Colors.red,
            child: const Icon(Icons.chat),
            onPressed: () {
              Navigator.of(innerContext).push(
                MaterialPageRoute(
                  builder: (_) => const EmergencyChatbotScreen(),
                ),
              );
            },
          ),
        ),

        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.call),
                label: 'SOS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medication),
                label: 'Medicine',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: 'Guides',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF8A2BE2),
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0.0,
          ),
        ),
      ),
    );
  }
}
