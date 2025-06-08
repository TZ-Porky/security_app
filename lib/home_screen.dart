// lib/main_app_screen.dart
import 'package:flutter/material.dart';
import 'settings_screen.dart'; // Pour la navigation vers SettingsScreen
import 'services_screen.dart'; // Pour la navigation vers ServicesScreen
import 'protection_active_screen.dart'; // Pour la navigation vers ProtectionActiveScreen
import 'security_screen.dart'; // Pour pouvoir revenir à l'écran de sécurité si déconnecté

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Pour la BottomNavigationBar

  // Liste des écrans à afficher dans le corps de la page
  // Note: ProtectionActiveScreen est la page principale selon votre design "Touch To Unlock-Main.png"
  static const List<Widget> _widgetOptions = <Widget>[
    ProtectionActiveScreen(),
    ServicesScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // L'AppBar sera gérée par les écrans individuels si nécessaire,
      // ou vous pouvez en mettre une générique ici si elle est la même pour tous.
      // Dans ce cas, les écrans individuels doivent gérer leur propre AppBar.
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}