import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import 'security_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Erreur lors de l\'initialisation des caméras: $e');
  }

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.storage,
    // Note: Pas besoin de Permission.contacts pour l'e-mail si vous le faites manuellement
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ma Sécurité App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Personnalisation simple du thème
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[800],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, // Couleur du bouton
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const SecurityScreen(),
    );
  }
}
