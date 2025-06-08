// lib/services_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Pour la caméra et le partage, nous aurons besoin de ces imports si la logique de capture/envoi est ici
// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'dart:io';

// Cette variable doit être accessible si vous voulez prendre des photos depuis ici
// late List<CameraDescription> cameras;

class ServicesScreen extends StatefulWidget {
  // Optionnel: Passer cameras si la capture photo est gérée ici
  // final List<CameraDescription> cameras;
  // const ServicesScreen({super.key, required this.cameras});
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  // État des services
  bool _lockMobile = false;
  bool _takePhoto = false;
  bool _soundAlarm = false;
  bool _sendLocation = false;
  bool _activateData = false;
  bool _formatDevice = false;

  // Camera and email related variables might be here if services trigger them
  // CameraController? _cameraController;
  // Future<void>? _initializeCameraControllerFuture;
  // String? _emergencyEmail; // Loaded from shared_preferences

  @override
  void initState() {
    super.initState();
    _loadServiceSettings();
    // _initializeCamera(); // Si la caméra est utilisée ici
    // _loadEmergencyEmail(); // Si l'e-mail est utilisé ici
  }

  // @override
  // void dispose() {
  //   _cameraController?.dispose(); // Si la caméra est utilisée ici
  //   super.dispose();
  // }

  Future<void> _loadServiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lockMobile = prefs.getBool('service_lock_mobile') ?? false;
      _takePhoto = prefs.getBool('service_take_photo') ?? false;
      _soundAlarm = prefs.getBool('service_sound_alarm') ?? false;
      _sendLocation = prefs.getBool('service_send_location') ?? false;
      _activateData = prefs.getBool('service_activate_data') ?? false;
      _formatDevice = prefs.getBool('service_format_device') ?? false;
    });
  }

  Future<void> _saveServiceSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service $key mis à jour.')),
      );
    }
    // Si la capture photo est activée, vous pourriez initier des écouteurs ici
    // Exemple: if (key == 'service_take_photo' && value) { setupBackgroundPhotoListener(); }
  }

  // Exemple d'action si un service est activé/désactivé
  void _onServiceChanged(String key, bool value) {
    setState(() {
      switch (key) {
        case 'service_lock_mobile': _lockMobile = value; break;
        case 'service_take_photo': _takePhoto = value; break;
        case 'service_sound_alarm': _soundAlarm = value; break;
        case 'service_send_location': _sendLocation = value; break;
        case 'service_activate_data': _activateData = value; break;
        case 'service_format_device': _formatDevice = value; break;
      }
    });
    _saveServiceSetting(key, value);
  }

  // La logique de _takePhotoAndSend() ou _initializeCamera() pourrait être ici
  // si ces actions sont déclenchées par l'activation d'un service.
  // Pour l'instant, on se contente des toggles visuels.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SERVICES'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // 2 colonnes comme sur le design
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          shrinkWrap: true, // Pour que GridView ne prenne que l'espace nécessaire
          physics: const NeverScrollableScrollPhysics(), // Pour éviter le double scroll
          children: <Widget>[
            _buildServiceCard(
              icon: Icons.lock_outline,
              title: 'Verrouillage mobile',
              value: _lockMobile,
              onChanged: (val) => _onServiceChanged('service_lock_mobile', val),
            ),
            _buildServiceCard(
              icon: Icons.camera_alt,
              title: 'Prendre une photo',
              value: _takePhoto,
              onChanged: (val) => _onServiceChanged('service_take_photo', val),
            ),
            _buildServiceCard(
              icon: Icons.notifications_active,
              title: 'Sonner l\'alarme',
              value: _soundAlarm,
              onChanged: (val) => _onServiceChanged('service_sound_alarm', val),
            ),
            _buildServiceCard(
              icon: Icons.location_on,
              title: 'Envoyer localisation',
              value: _sendLocation,
              onChanged: (val) => _onServiceChanged('service_send_location', val),
            ),
            _buildServiceCard(
              icon: Icons.data_usage,
              title: 'Activer les données',
              value: _activateData,
              onChanged: (val) => _onServiceChanged('service_activate_data', val),
            ),
            _buildServiceCard(
              icon: Icons.delete_forever,
              title: 'Formater l\'appareil',
              value: _formatDevice,
              onChanged: (val) => _onServiceChanged('service_format_device', val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}