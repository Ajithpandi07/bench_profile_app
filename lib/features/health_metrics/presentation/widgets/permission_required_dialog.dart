import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequiredDialog extends StatelessWidget {
  const PermissionRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Permission Required',
        style: TextStyle(
          color: Color(0xFFEE374D),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Text(
        'To track your progress, this app needs access to your health data. Please grant the necessary permissions in settings.',
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
            openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}
