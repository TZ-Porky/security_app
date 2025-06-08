// lib/security_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fingerprint_auth/fingerprint_auth.dart';
import 'package:flutter_svg/svg.dart';
// Importez votre MainAppScreen où l'utilisateur sera redirigé après succès
import 'home_screen.dart';
import 'system_ui_utils.dart'; // Nous allons créer ce fichier ensuite

// On suppose que 'cameras' est passé ou est accessible globalement (initialisé dans main.dart)
// Vous pouvez également le passer en argument si vous le préférez.
// late List<CameraDescription> cameras; // Ne pas déclarer ici si déclaré globalement dans main.dart

class SecurityScreen extends StatefulWidget {
  // Optionnel: Vous pourriez passer 'cameras' si vous ne le voulez pas global.
  // final List<CameraDescription> cameras;
  // const SecurityScreen({super.key, required this.cameras});
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen>
    with WidgetsBindingObserver {
  String _authStatus = 'Touch to Unlock'; // Texte initial
  bool _isAuthenticated = false; // État d'authentification
  bool _canCheckBiometrics = false; // Disponibilité biométrie
  bool _isPluginActivityAttached = false; // État du plugin

  // Variables liées à la photo et à l'email ne sont PLUS GÉRÉES DIRECTEMENT ICI.
  // Elles seront gérées par un service ou par l'écran "Services" ou "Protection Active".

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometricsSupport();
    _checkPluginActivityAttached();
    // Lancer l'authentification automatiquement au démarrage de cet écran
    _authenticate();
    SystemUiUtils.enterFullscreenMode(); // Entrer en mode plein écran
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Pas de _cameraController.dispose() ici, car la caméra n'est plus gérée directement.
    SystemUiUtils.exitFullscreenMode();
    super.dispose();
  }

  // Gérer le cycle de vie de l'application pour la sécurité
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_isAuthenticated) {
      print(
        "Application mise en arrière-plan sans authentification. Tentative de fermeture.",
      );
      SystemNavigator.pop(); // Tenter de fermer l'application
    } else if (state == AppLifecycleState.resumed && !_isAuthenticated) {
      print(
        "Application de retour au premier plan sans authentification. Relancement de l'authentification.",
      );
      _authenticate();
    }
  }

  // Fonctions de vérification de la biométrie et du plugin
  Future<void> _checkBiometricsSupport() async {
    bool canAuthenticate = false;
    try {
      canAuthenticate = await FingerprintAuth.canAuthenticate();
    } on PlatformException catch (e) {
      print(
        "Erreur lors de la vérification biométrique: ${e.code} - ${e.message}",
      );
    }
    if (mounted) {
      setState(() {
        _canCheckBiometrics = canAuthenticate;
        if (!_canCheckBiometrics && _authStatus == 'Touch to Unlock') {
          _authStatus = "Biométrie non disponible ou non configurée.";
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

  // Fonction d'authentification principale
  Future<void> _authenticate() async {
    if (_isAuthenticated) return;

    if (!_canCheckBiometrics) {
      setState(() {
        _authStatus = 'L\'authentification biométrique n\'est pas configurée.';
      });
      return;
    }

    if (!_isPluginActivityAttached) {
      setState(() {
        _authStatus = 'Système non prêt. Veuillez patienter et réessayer.';
      });
      print(
        "Tentative d'authentification alors que l'activité du plugin n'est pas attachée.",
      );
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
      _isAuthenticated = false;
      if (e.code == "NO_ACTIVITY") {
        setState(() {
          _authStatus = 'Erreur d\'initialisation. Réessayez.';
        });
      } else if (e.code == "AUTH_ERROR") {
        setState(() {
          _authStatus = 'Échec d\'authentification: ${e.message}';
        });
        // Ici, NOTIFIEZ un service d'alerte ou la logique principale
        // Exemple: AppLifecycleObserver.instance.notifyAuthenticationFailed();
        // Pour l'instant, on se contente d'un print.
        print("Authentification échouée, devrait déclencher une alerte !");
      } else if (e.code == "CANCELLED") {
        setState(() {
          _authStatus = 'Authentification annulée.';
        });
      } else if (e.code == "NOT_AVAILABLE") {
        setState(() {
          _authStatus = 'Biométrie non disponible sur cet appareil.';
        });
      } else {
        setState(() {
          _authStatus = 'Erreur: ${e.message}';
        });
      }
      return;
    } catch (e) {
      _isAuthenticated = false;
      setState(() {
        _authStatus = 'Erreur inattendue: $e';
      });
      print(
        "Authentification échouée avec erreur inattendue, devrait déclencher une alerte !",
      );
      return;
    }

    if (authenticated) {
      setState(() {
        _authStatus = 'Authentification réussie !';
        _isAuthenticated = true;
      });
      // Naviguer vers l'écran principal après authentification réussie
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ), // Navigue vers la VRAIE page principale
      );
    } else {
      setState(() {
        _authStatus = 'Authentification échouée. Veuillez réessayer.';
        _isAuthenticated = false;
      });
      print("Authentification échouée, devrait déclencher une alerte !");
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
        backgroundColor: const Color(0xFF8A2BE2), // Violet de l'image
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Bouclier et cadenas
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/Logo.png', // Chemin vers votre image de bouclier
                    width: 200,
                    height: 200,
                  ),
                ],
              ),
              const SizedBox(height: 100),

              // Texte "Touch to Unlock" avec flèche
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle:180 *(math.pi / 180),
                    child: SvgPicture.asset(
                      'assets/icons/caret-down.svg',
                      width: 30,
                      height: 30,
                      colorFilter: const ColorFilter.mode(Colors.white,BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _authStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Cercle et icône d'empreinte digitale
              GestureDetector(
                onTap: _isAuthenticated ? null : _authenticate,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
