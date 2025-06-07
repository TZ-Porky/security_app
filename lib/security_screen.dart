import 'package:flutter/material.dart';
import 'package:fingerprint_auth/fingerprint_auth.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

late List<CameraDescription> cameras;

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> with WidgetsBindingObserver {
  String _authStatus = 'Veuillez authentifier pour accéder.';
  CameraController? _cameraController;
  Future<void>? _initializeCameraControllerFuture;

  bool _canCheckBiometrics = false;
  bool _isPluginActivityAttached = false;
  bool _isAuthenticated = false;
  String? _emergencyEmail; // Variable pour stocker l'adresse e-mail

  @override
  void initState() {
    super.initState();
    _loadEmergencyEmail();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _checkBiometricsSupport();
    _checkPluginActivityAttached();
    _authenticate(); // Lancer l'authentification au démarrage
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_isAuthenticated) {
      print("Application mise en arrière-plan sans authentification. Fermeture de l'application.");
      SystemNavigator.pop(); // Tenter de fermer l'application
    } else if (state == AppLifecycleState.resumed && !_isAuthenticated) {
        print("Application de retour au premier plan sans authentification. Relancement de l'authentification.");
        _authenticate();
    }
  }

  Future<void> _loadEmergencyEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyEmail = prefs.getString('emergency_email');
    });
  }

  Future<void> _saveEmergencyEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_email', email);
    setState(() {
      _emergencyEmail = email;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adresse e-mail d\'urgence enregistrée.')),
    );
  }

  void _showEmailInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String inputEmail = _emergencyEmail ?? '';
        return AlertDialog(
          title: const Text('Définir l\'e-mail d\'urgence'),
          content: TextField(
            controller: TextEditingController(text: inputEmail),
            decoration: const InputDecoration(
              hintText: "Entrez l'e-mail de destination",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              inputEmail = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton( // Utilisation d'ElevatedButton pour un look plus moderne
              child: const Text('Enregistrer'),
              onPressed: () {
                if (inputEmail.isNotEmpty && inputEmail.contains('@')) {
                  _saveEmergencyEmail(inputEmail);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer une adresse e-mail valide.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeCamera() async {
    if (cameras.isNotEmpty) {
      CameraDescription? frontCamera;
      for (var cameraDescription in cameras) {
        if (cameraDescription.lensDirection == CameraLensDirection.front) {
          frontCamera = cameraDescription;
          break;
        }
      }

      if (frontCamera != null) {
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
        );
        _initializeCameraControllerFuture = _cameraController!.initialize();
        if (mounted) setState(() {});
      } else {
        print("Aucune caméra avant disponible. Utilisation de la caméra arrière si disponible.");
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
        );
        _initializeCameraControllerFuture = _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } else {
      print("Aucune caméra disponible.");
      setState(() {
        _authStatus = "Erreur: Aucune caméra disponible pour la capture.";
      });
    }
  }

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
        if (!_canCheckBiometrics && _authStatus == 'Veuillez authentifier pour accéder.') {
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

  Future<void> _authenticate() async {
    if (_isAuthenticated) return;

    if (!_canCheckBiometrics) {
      setState(() {
        _authStatus = 'L\'authentification biométrique n\'est pas configurée sur cet appareil.';
      });
      return;
    }

    if (!_isPluginActivityAttached) {
        setState(() {
            _authStatus = 'Le système n\'est pas prêt. Veuillez patienter et réessayer.';
        });
        print("Tentative d'authentification alors que l'activité du plugin n'est pas attachée.");
        return;
    }

    bool authenticated = false;
    try {
      setState(() {
        _authStatus = 'Authentification en cours... Veuillez scanner.';
      });

      authenticated = await FingerprintAuth.authenticate(
        title: 'Accès sécurisé',
        subtitle: 'Scanner votre empreinte digitale',
        negativeButtonText: 'Annuler',
      );
    } on PlatformException catch (e) {
      _isAuthenticated = false; // Réinitialiser l'état d'authentification en cas d'erreur
      if (e.code == "NO_ACTIVITY") {
        setState(() { _authStatus = 'Erreur d\'initialisation. Réessayez.'; });
      } else if (e.code == "AUTH_ERROR") {
         setState(() { _authStatus = 'Échec d\'authentification: ${e.message}'; });
      } else if (e.code == "CANCELLED") {
        setState(() { _authStatus = 'Authentification annulée par l\'utilisateur.'; });
      } else if (e.code == "NOT_AVAILABLE") { // Exemple d'erreur de biométrie non disponible
         setState(() { _authStatus = 'Biométrie non disponible sur cet appareil.'; });
      } else {
        setState(() { _authStatus = 'Erreur: ${e.message}'; });
      }
      if (e.code != "CANCELLED" && e.code != "NO_ACTIVITY" && e.code != "NOT_AVAILABLE") {
          // Si l'échec n'est pas une annulation ou une erreur d'initialisation, prendre la photo
          _takePhotoAndSend();
      }
      return;
    } catch (e) {
      _isAuthenticated = false; // Réinitialiser l'état d'authentification en cas d'erreur
      setState(() { _authStatus = 'Erreur inattendue: $e'; });
      _takePhotoAndSend(); // Prendre la photo pour toute erreur inattendue
      return;
    }

    if (authenticated) {
      setState(() {
        _authStatus = 'Authentification réussie ! Accès autorisé.';
        _isAuthenticated = true;
      });
    } else {
      // Ce bloc ne devrait être atteint que si `authenticate` retourne `false` sans lever d'exception.
      // Dans notre plugin, `authenticate` lève une exception en cas d'échec, donc ce bloc est moins probable.
      setState(() {
        _authStatus = 'Authentification échouée. Capture de photo...';
        _isAuthenticated = false;
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
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erreur: Caméra non prête pour la photo.')),
            );
            return;
        }
      }

      final image = await _cameraController!.takePicture();
      final appDir = await getTemporaryDirectory();
      final String filePath = '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final File newImage = await File(image.path).copy(filePath);

      // Préparer l'envoi de l'e-mail
      final List<String> recipients = [];
      if (_emergencyEmail != null && _emergencyEmail!.isNotEmpty) {
        recipients.add(_emergencyEmail!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez définir une adresse e-mail d\'urgence dans les paramètres.')),
        );
      }

      await Share.shareXFiles(
        [XFile(newImage.path)],
        subject: 'ALERTE SÉCURITÉ - Tentative d\'accès non autorisée !',
        text: 'Une tentative d\'accès non autorisée a été détectée sur votre appareil sécurisé. Voici une photo.',
        // emails: recipients, // SharePlus ne prend pas directement 'emails' pour shareXFiles.
                           // L'utilisateur devra choisir le destinataire.
      );

      setState(() {
        _authStatus = 'Photo capturée et partage lancée.';
      });
    } catch (e) {
      print('Erreur lors de la capture ou de l\'envoi de la photo: $e');
      setState(() {
        _authStatus = 'Erreur: Impossible de capturer/envoyer la photo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isAuthenticated,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (!_isAuthenticated) {
          _authenticate();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ma Sécurité App'),
          automaticallyImplyLeading: _isAuthenticated,
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _isAuthenticated ? _showEmailInputDialog : null, // Active le bouton seulement si authentifié
              tooltip: 'Définir l\'e-mail d\'urgence',
            ),
          ],
        ),
        body: Container( // Utilisation d'un Container pour le dégradé
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView( // Pour éviter les problèmes de dépassement
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    _isAuthenticated ? Icons.lock_open : Icons.lock,
                    size: 100,
                    color: _isAuthenticated ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _authStatus,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Bouton d'authentification
                  ElevatedButton.icon(
                    onPressed: (_canCheckBiometrics && _isPluginActivityAttached && !_isAuthenticated) ? _authenticate : null,
                    icon: Icon(Icons.fingerprint),
                    label: const Text('Tenter l\'authentification'),
                  ),
                  const SizedBox(height: 30),
                  // Prévisualisation de la caméra si pas authentifié
                  if (!_isAuthenticated)
                    FutureBuilder<void>(
                      future: _initializeCameraControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (_cameraController != null && _cameraController!.value.isInitialized) {
                            return ClipRRect( // Pour les coins arrondis
                              borderRadius: BorderRadius.circular(15.0),
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white54, width: 2),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: CameraPreview(_cameraController!),
                              ),
                            );
                          } else {
                            return const Text(
                              "Prévisualisation caméra non disponible.",
                              style: TextStyle(color: Colors.white70),
                            );
                          }
                        } else {
                          return const CircularProgressIndicator(color: Colors.white);
                        }
                      },
                    ),
                  if (_isAuthenticated) // Message après authentification
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Bienvenue ! Votre appareil est sécurisé.",
                        style: TextStyle(fontSize: 18, color: Colors.greenAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}