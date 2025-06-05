import 'package:flutter/material.dart';
import 'package:fingerprint_auth/fingerprint_auth.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Erreur lors de l\'initialisation des caméras: $e');
  }

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.storage,
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
      ),
      home: const SecurityScreen(),
    );
  }
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  String _authStatus = 'Veuillez authentifier';
  CameraController? _cameraController;
  Future<void>? _initializeCameraControllerFuture;

  bool _canCheckBiometrics = false;
  bool _isPluginActivityAttached = false; // Pour la vérification de l'activité du plugin

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkBiometricsSupport();
    _checkPluginActivityAttached();
  }

  // --- MODIFICATION ICI ---
  Future<void> _initializeCamera() async {
    if (cameras.isNotEmpty) {
      // Trouver la caméra avant
      CameraDescription? frontCamera;
      for (var cameraDescription in cameras) {
        if (cameraDescription.lensDirection == CameraLensDirection.front) {
          frontCamera = cameraDescription;
          break; // Une fois trouvée, on peut sortir de la boucle
        }
      }

      if (frontCamera != null) {
        _cameraController = CameraController(
          frontCamera, // Utiliser la caméra avant
          ResolutionPreset.medium,
        );
        _initializeCameraControllerFuture = _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      } else {
        print("Aucune caméra avant disponible sur l'appareil. Utilisation de la caméra arrière si disponible.");
        // Fallback: Si aucune caméra avant, utiliser la première caméra disponible (souvent l'arrière)
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
        );
        _initializeCameraControllerFuture = _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      print("Aucune caméra disponible sur l'appareil.");
      setState(() {
        _authStatus = "Erreur: Aucune caméra disponible.";
      });
    }
  }
  // --- FIN DE LA MODIFICATION ---

  Future<void> _checkBiometricsSupport() async {
    bool canAuthenticate = false;
    try {
      canAuthenticate = await FingerprintAuth.canAuthenticate();
    } on PlatformException catch (e) {
      print("Erreur lors de la vérification biométrique: ${e.code} - ${e.message}");
      setState(() {
        _authStatus = 'Biométrie non disponible: ${e.message}';
      });
    }
    if (mounted) {
      setState(() {
        _canCheckBiometrics = canAuthenticate;
        if (!_canCheckBiometrics && _authStatus == 'Veuillez authentifier') {
          _authStatus = "Authentification biométrique non disponible ou non configurée.";
        }
      });
    }
  }

  Future<void> _checkPluginActivityAttached() async {
    final bool attached = await FingerprintAuth.isActivityAttached();
    if (mounted) {
      setState(() {
        _isPluginActivityAttached = attached;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!_canCheckBiometrics) {
      setState(() {
        _authStatus = 'L\'authentification biométrique n\'est pas configurée sur cet appareil.';
      });
      return;
    }

    if (!_isPluginActivityAttached) {
        setState(() {
            _authStatus = 'Le système n\'est pas prêt pour l\'authentification. Veuillez patienter et réessayer.';
        });
        print("Tentative d'authentification alors que l'activité du plugin n'est pas attachée.");
        return;
    }

    bool authenticated = false;
    try {
      setState(() {
        _authStatus = 'Authentification en cours...';
      });

      authenticated = await FingerprintAuth.authenticate(
        title: 'Accès sécurisé',
        subtitle: 'Scanner votre empreinte digitale',
        negativeButtonText: 'Annuler',
      );
    } on PlatformException catch (e) {
      if (e.code == "NO_ACTIVITY") {
        print("Erreur: Le plugin n'est pas attaché à l'activité Android. Réessayez plus tard.");
        setState(() {
          _authStatus = 'Erreur d\'initialisation. Réessayez.';
        });
      } else if (e.code == "AUTH_ERROR") {
         print("Erreur d'authentification native: ${e.message}");
         setState(() {
            _authStatus = 'Erreur d\'authentification: ${e.message}';
         });
      } else {
        print('Erreur inconnue lors de l\'authentification: $e');
        setState(() {
          _authStatus = 'Erreur: ${e.message}';
        });
      }
      return;
    } catch (e) {
      print('Erreur inattendue: $e');
      setState(() {
        _authStatus = 'Erreur inattendue: $e';
      });
      return;
    }

    if (authenticated) {
      setState(() {
        _authStatus = 'Authentification réussie !';
      });
    } else {
      setState(() {
        _authStatus = 'Authentification échouée. Capture de photo...';
      });
      _takePhotoAndSend();
    }
  }

  Future<void> _takePhotoAndSend() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        await _initializeCameraControllerFuture;
        if (_cameraController == null || !_cameraController!.value.isInitialized) {
            print("Caméra non initialisée. Impossible de prendre la photo.");
            return;
        }
      }

      final image = await _cameraController!.takePicture();
      final appDir = await getTemporaryDirectory();
      final String filePath = '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final File newImage = await File(image.path).copy(filePath);

      await Share.shareXFiles(
        [XFile(newImage.path)],
        text: 'Alerte sécurité: Tentative d\'accès non autorisée détectée !',
      );

      setState(() {
        _authStatus = 'Photo envoyée au contact d\'urgence.';
      });
    } catch (e) {
      print('Erreur lors de la capture ou de l\'envoi de la photo: $e');
      setState(() {
        _authStatus = 'Erreur lors de l\'envoi de la photo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application de Sécurité'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _authStatus,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: (_canCheckBiometrics && _isPluginActivityAttached) ? _authenticate : null,
              child: const Text('Tenter l\'authentification'),
            ),
            const SizedBox(height: 20),
            FutureBuilder<void>(
              future: _initializeCameraControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (_cameraController != null && _cameraController!.value.isInitialized) {
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: CameraPreview(_cameraController!),
                    );
                  } else {
                    return const Text("Prévisualisation caméra non disponible.");
                  }
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}