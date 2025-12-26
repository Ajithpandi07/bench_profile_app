import 'package:flutter/material.dart';
import 'package:health/health.dart';

class HealthConnectInstallDialog extends StatelessWidget {
  const HealthConnectInstallDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Install Health Connect',
        style: TextStyle(
          color: Color(0xFFEE374D),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Text(
        'To track your progress, this app requires the Health Connect app to be installed using the button below.',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEE374D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Health().installHealthConnect();
          },
          child: const Text('Install'),
        ),
      ],
    );
  }
}
