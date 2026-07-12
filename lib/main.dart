import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/screens/home_screen.dart';

// main() is the first function Flutter calls.
// "async" means it can wait for things (like opening a database).
Future<void> main() async {
  // This line MUST come first when you use plugins (like sqflite).
  // It makes sure Flutter's engine is ready before we do anything.
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite works differently on Windows/Linux/Mac vs Android/iOS.
  // This call sets up the right version for whatever platform we're on.
  DatabaseHelper.initFfiIfNeeded();

  // Open (or create) the database before showing any screen.
  // The "await" keyword means: wait here until this is done.
  await DatabaseHelper.instance.database;

  // Now start the app!
  runApp(const ChronicleApp());
}

// Every Flutter app has one root widget.
// StatelessWidget = a widget that never changes after it's built.
class ChronicleApp extends StatelessWidget {
  const ChronicleApp({super.key});

  // build() describes what this widget looks like / does.
  // Flutter calls this whenever it needs to draw this widget.
  @override
  Widget build(BuildContext context) {
    // MaterialApp sets up navigation, themes, and the overall app structure.
    return MaterialApp(
      title: 'Chronicle',
      debugShowCheckedModeBanner: false, // hides the red "DEBUG" banner

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E9E50)),
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),

        // These two lines DISABLE the ripple/hover effect on buttons.
        // This prevents a crash on Windows when navigating (mouse tracker bug).
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),

      // home: is the first screen the user sees.
      home: const HomeScreen(),
    );
  }
}