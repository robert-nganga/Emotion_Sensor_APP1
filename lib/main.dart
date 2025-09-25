import 'package:app/data/database/isar_database.dart';
import 'package:app/pages/camera_page.dart';
import 'package:app/pages/camera_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';


late List<CameraDescription> cameras;
late Isar isar; // Late for initialization

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras(); // Fetch available cameras
  isar = await IsarDatabase.createIsarDatabase(); //it takes time to create the database, thats why we dont put before the class
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Sensor App', // App name (visible to users)
      theme: ThemeData(
        primarySwatch: Colors.blue, // Primary color
      ),
      home: const CameraPage(), // Main screen
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}