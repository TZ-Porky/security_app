// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _emergencyEmailController = TextEditingController();
  final TextEditingController _sendingEmailController = TextEditingController();
  final TextEditingController _sendingPasswordController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _captureImageEnabled = true;
  bool _passwordAuthEnabled = true;
  bool _patternAuthEnabled = true;
  bool _fingerprintAuthEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyEmailController.text = prefs.getString('emergency_email') ?? '';
      _sendingEmailController.text = prefs.getString('sending_email') ?? '';
      _sendingPasswordController.text = prefs.getString('sending_password') ?? ''; // PAS RECOMMANDÉ DE STOCKER EN CLAIR
      _subjectController.text = prefs.getString('email_subject') ?? 'ALERTE SÉCURITÉ - Tentative d\'accès non autorisée !';
      _captureImageEnabled = prefs.getBool('capture_image_enabled') ?? true;
      _passwordAuthEnabled = prefs.getBool('password_auth_enabled') ?? true;
      _patternAuthEnabled = prefs.getBool('pattern_auth_enabled') ?? true;
      _fingerprintAuthEnabled = prefs.getBool('fingerprint_auth_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_email', _emergencyEmailController.text);
    await prefs.setString('sending_email', _sendingEmailController.text);
    await prefs.setString('sending_password', _sendingPasswordController.text); // DANGER: NE PAS FAIRE EN PROD
    await prefs.setString('email_subject', _subjectController.text);
    await prefs.setBool('capture_image_enabled', _captureImageEnabled);
    await prefs.setBool('password_auth_enabled', _passwordAuthEnabled);
    await prefs.setBool('pattern_auth_enabled', _patternAuthEnabled);
    await prefs.setBool('fingerprint_auth_enabled', _fingerprintAuthEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres sauvegardés !')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        backgroundColor: const Color(0xFF471B9A), // Couleur violette de la barre
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 16),
              // Adresse e-mail d'urgence
              TextField(
                controller: _emergencyEmailController,
                decoration: InputDecoration(
                  labelText: 'Adresse e-mail d\'urgence',
                  hintText: 'ex: moncontact@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Adresse e-mail d'envoi
              TextField(
                controller: _sendingEmailController,
                decoration: InputDecoration(
                  labelText: 'Adresse e-mail d\'envoi',
                  hintText: 'ex: ma_securite_app@gmail.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Mot de passe de l'adresse d'envoi (AVERTISSEMENT: NE PAS FAIRE EN PROD)
              TextField(
                controller: _sendingPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Mot de passe de l\'adresse d\'envoi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Objet du message
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Objet du message',
                  hintText: 'ALERTE SÉCURITÉ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
              ),
              const SizedBox(height: 24),

              // Options avec SwitchListTile
              SwitchListTile(
                title: const Text('Capture d\'image inclus automatiquement', style: TextStyle(fontSize: 13),),
                value: _captureImageEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _captureImageEnabled = value;
                  });
                },
                secondary: Icon(Icons.camera_alt),
              ),
              SwitchListTile(
                title: const Text('Autoriser l\'authentification par MOT DE PASSE', style: TextStyle(fontSize: 13),),
                value: _passwordAuthEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _passwordAuthEnabled = value;
                  });
                },
                secondary: Icon(Icons.password),
              ),
              SwitchListTile(
                title: const Text('Autoriser l\'authentification par SCHEMA', style: TextStyle(fontSize: 13),),
                value: _patternAuthEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _patternAuthEnabled = value;
                  });
                },
                secondary: Icon(Icons.pattern),
              ),
              SwitchListTile(
                title: const Text('Autoriser l\'authentification par EMPREINTE', style: TextStyle(fontSize: 13),),
                value: _fingerprintAuthEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _fingerprintAuthEnabled = value;
                  });
                },
                secondary: Icon(Icons.fingerprint),
              ),
              const SizedBox(height: 24),

              // Bouton SAUVEGARDER
              Center(
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:const Color(0xFF471B9A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('SAUVEGARDER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}