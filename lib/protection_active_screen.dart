// lib/protection_active_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'security_screen.dart';
import 'package:intl/intl.dart'; // NOUVEL IMPORT pour le formatage de la date

class ProtectionActiveScreen extends StatelessWidget {
  const ProtectionActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenez la date actuelle et formatez-la comme "Jour Mois Année"
    final String formattedDate = DateFormat('d MMMM y').format(DateTime.now());

    return Scaffold(
      // *** CORRECTION : Fond de l'écran principal clair ***
      backgroundColor: const Color(0xFFF0F0F0), // Une couleur très claire ou blanche cassée

      appBar: AppBar(
        title: Column(children: [
          const Text(
          'TOUCH TO UNLOCK',
              style: TextStyle(
                fontSize: 11, // Taille de police ajustée
              ),
          ),
          const SizedBox(height: 2,),
          Text(
                'Version 1.0.0', // Texte de la version comme dans le design
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF471B9A), // Couleur violette de la barre
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/images/Logo.png',
            width: 20,
            height: 20,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 5.0),
            child: Center(
              child: IconButton(
                onPressed: () => {}, 
                icon: SvgPicture.asset(
                      'assets/icons/bars.svg',
                      width: 22,
                      height: 22,
                      colorFilter: const ColorFilter.mode(Colors.white,BlendMode.srcIn),
                ),
              )
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // *** NOUVEAU : Le cercle bleu avec effet fluorescent ***
            Container(
              width: 200, // Ajustez la taille du cercle
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00ACC1), // Un bleu/cyan
                    const Color(0xFF00E5FF).withOpacity(0.5), // Un bleu plus clair et transparent pour l'effet
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                // L'effet "fluorescent" peut être simulé avec un BoxShadow subtil
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00ACC1).withOpacity(0.6), // Couleur de l'ombre
                    blurRadius: 50, // Rayon de flou pour l'effet
                    spreadRadius: 10, // Étendue de l'ombre
                    offset: Offset.zero, // Centre l'ombre
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/LogoV2.png',
                    width: 150, // Ajustez la taille du bouclier à l'intérieur du cercle
                    height: 150,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // *** CORRECTION : Taille du texte "PROTECTION ACTIVE" ***
            const Text(
              'PROTECTION ACTIVE',
              style: TextStyle(
                color: Colors.deepPurple, // Couleur violette plus foncée pour le texte
                fontSize: 18, // Taille de police ajustée
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5, // Léger espacement pour la lisibilité
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Dernière activation : $formattedDate', // Utilisation de la date formatée
              style: const TextStyle(
                color: Colors.grey, // Couleur grise pour la date
                fontSize: 14, // Taille de police ajustée
              ),
            ),
            const SizedBox(height: 20),

            // Bouton "DÉSACTIVER LA PROTECTION"
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SecurityScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:  const Color(0xFF471B9A), // Couleur violette de la barre
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), // Ajustement du padding
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Taille de police ajustée
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rayon des coins ajusté pour être moins arrondi que précédemment, mais plus que le design strict (qui semble avoir 4-6)
                ),
                elevation: 5, // Ajout d'une légère ombre pour le relief
              ),
              child: const Text('DÉSACTIVER LA PROTECTION'),
            ),
          ],
        ),
      ),
    );
  }
}