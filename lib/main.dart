import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

void main() {
  runApp(const MtkaApp());
}

class MtkaApp extends StatelessWidget {
  const MtkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTKA Fishing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFB703),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFB703),
          secondary: Color(0xFFFB8500),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DetectorState {
  final String id;
  final String name;
  final String rodName;
  int battery;
  bool isConnected;
  bool isBiting;
  double sensitivity;

  DetectorState({
    required this.id,
    required this.name,
    required this.rodName,
    this.battery = 100,
    this.isConnected = true,
    this.isBiting = false,
    this.sensitivity = 0.10,
  });
}

class BiteLog {
  final String detectorName;
  final String time;
  final String duration;

  BiteLog({required this.detectorName, required this.time, required this.duration});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Liste des équipements
  final List<DetectorState> detectors = [
    DetectorState(id: "1", name: "Bipper 01", rodName: "Canne Gauche", battery: 88),
    DetectorState(id: "2", name: "Bipper 02", rodName: "Canne Centre", battery: 94),
    DetectorState(id: "3", name: "Bipper 03", rodName: "Canne Droite", battery: 76),
  ];

  int centralBattery = 92;
  bool isCentralConnected = true;

  // Calibration
  bool isCalibrating = false;
  int calibrationTimer = 10;
  Timer? _timer;

  // Historique des touches
  List<BiteLog> biteLogs = [
    BiteLog(detectorName: "Canne Centre", time: "14:22", duration: "4 sec"),
    BiteLog(detectorName: "Canne Gauche", time: "11:05", duration: "12 sec"),
  ];

  void startCalibration() {
    setState(() {
      isCalibrating = true;
      calibrationTimer = 10;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (calibrationTimer > 1) {
        setState(() {
          calibrationTimer--;
        });
      } else {
        timer.cancel();
        setState(() {
          isCalibrating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calibration automatique terminée (Marge de 10% appliquée)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void simulateBite(int index) {
    setState(() {
      detectors[index].isBiting = true;
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      biteLogs.insert(0, BiteLog(
        detectorName: detectors[index].rodName,
        time: timeStr,
        duration: "5 sec",
      ));
    });

    Timer(const Duration(seconds: 5), () {
      setState(() {
        detectors[index].isBiting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB703),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phishing, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'MTKA FISHING',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recherche des bippers BLE en cours...')),
              );
            },
          )
        ],
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Centrale Master
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB703).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCentralConnected ? Icons.router : Icons.router_outlined,
                        color: isCentralConnected ? Colors.greenAccent : Colors.redAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Centrale Relais Master',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            isCentralConnected ? 'Connectée via BLE (Hors-Ligne OK)' : 'Déconnectée',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.battery_charging_full, color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 4),
                      Text('$centralBattery%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'DÉTECTEURS DE TOUCHE',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFFB703), letterSpacing: 1),
            ),
            const SizedBox(height: 10),

            // Cartes des Bippers
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detectors.length,
              itemBuilder: (context, index) {
                final d = detectors[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: d.isBiting ? Colors.red.withOpacity(0.2) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: d.isBiting ? Colors.red : Colors.white10,
                      width: d.isBiting ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: d.isBiting ? Colors.red : const Color(0xFFFFB703),
                                child: Icon(
                                  d.isBiting ? Icons.warning : Icons.sensors,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.rodName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '${d.name} • Sensibilité ${(d.sensitivity * 100).toInt()}%',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                d.battery > 20 ? Icons.battery_5_bar : Icons.battery_alert,
                                color: d.battery > 20 ? Colors.greenAccent : Colors.orangeAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text('${d.battery}%', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      if (d.isBiting) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_active, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'DÉPART DÉTECTÉ !',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => simulateBite(index),
                          icon: const Icon(Icons.play_arrow, size: 16, color: Color(0xFFFFB703)),
                          label: const Text('Simuler Départ', style: TextStyle(color: Color(0xFFFFB703), fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Bouton Calibration Automatique
            ElevatedButton(
              onPressed: isCalibrating ? null : startCalibration,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB703),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isCalibrating ? Icons.hourglass_top : Icons.tune),
                  const SizedBox(width: 10),
                  Text(
                    isCalibrating
                        ? 'CALIBRATION EN COURS (${calibrationTimer}s)...'
                        : 'LANCER LA CALIBRATION AUTO (10s)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text(
              'HISTORIQUE DES TOUCHES',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFFB703), letterSpacing: 1),
            ),
            const SizedBox(height: 10),

            // Liste Historique
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: biteLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
                itemBuilder: (context, index) {
                  final log = biteLogs[index];
                  return ListTile(
                    leading: const Icon(Icons.history, color: Color(0xFFFFB703)),
                    title: Text(log.detectorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Durée de la touche: ${log.duration}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    trailing: Text(log.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
