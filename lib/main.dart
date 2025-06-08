// main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

// Imports des écrans séparés
import 'security_screen.dart';
import 'home_screen.dart'; // L'écran principal après authentification
import 'settings_screen.dart'; // Import nécessaire pour les tests directs ou autres utilisations
import 'services_screen.dart'; // Import nécessaire pour les tests directs ou autres utilisations
import 'protection_active_screen.dart'; // Import nécessaire

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Erreur lors de l\'initialisation des caméras: $e');
    cameras = []; // Assurez-vous que cameras est initialisé même en cas d'erreur
  }

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.storage,
    // Ajoutez d'autres permissions si vos services les nécessitent (ex: Permission.location, Permission.sms)
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ma Sécurité App',
      debugShowCheckedModeBanner: false, // Désactive le bandeau de débogage
      theme: ThemeData(
        primarySwatch: Colors.blue, // Utilise un thème principal bleu pour l'app
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF471B9A), // Couleur violette de la barre
          foregroundColor: Colors.white, // Texte blanc sur l'AppBar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF471B9A), // Couleur violette de la barre
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        switchTheme: SwitchThemeData( // Style pour les interrupteurs
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Color(0xFF471B9A); // Couleur violette de la barre
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Color(0xFF471B9A).withOpacity(0.5);
            }
            return Colors.grey.withOpacity(0.5);
          }),
        ),
        cardTheme: CardTheme( // Style pour les cartes des services
          color: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const SecurityScreen(), // Démarre toujours avec l'écran d'authentification
    );
  }
}