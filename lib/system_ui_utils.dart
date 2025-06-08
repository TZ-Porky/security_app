// lib/utils/system_ui_utils.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'; // Pour Colors et Brightness

/// Classe utilitaire pour la gestion de l'interface utilisateur système (barres de statut/navigation).
class SystemUiUtils {
  /// Active le mode plein écran (immersive sticky) et définit le style des icônes de la barre de statut.
  static void enterFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      // Ou SystemUiMode.leanBack, ou SystemUiMode.manual, overlays: [] selon le comportement souhaité.
    );
    // Définit les icônes de la barre de statut en clair (pour un fond sombre)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  /// Rétablit le mode normal d'affichage des barres de statut et de navigation.
  /// Définit également un style par défaut pour les icônes.
  static void exitFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge, // Rétablit les barres normalement
    );
    // Rétablit un style par défaut pour les barres (ex: transparentes, icônes sombres)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Rend la barre de statut transparente
        statusBarIconBrightness: Brightness.dark, // Icônes sombres pour contenu clair
        systemNavigationBarColor: Colors.black, // Couleur de la barre de navigation
        systemNavigationBarIconBrightness: Brightness.light, // Icônes claires pour barre de navigation sombre
      ),
    );
  }

  // Vous pouvez ajouter d'autres fonctions utilitaires ici à l'avenir,
  // par exemple, pour gérer l'orientation de l'appareil:
  static void setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  static void enableAllOrientations() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}