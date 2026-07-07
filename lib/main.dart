// lib/main.dart
import 'package:flutter/material.dart';
import 'package:travel/database/database_helper.dart';
import 'package:travel/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Only needed on Desktop/Web. Android & iOS use the native sqflite engine.
  DatabaseHelper.initFfiIfNeeded();
  // Warm up the DB connection so the first screen never waits.
  await DatabaseHelper.instance.database;
  runApp(const ChronicleApp());
}

class ChronicleApp extends StatelessWidget {
  const ChronicleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronicle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E9E50)),
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      ),
      home: const HomeScreen(),
    );
  }
}
