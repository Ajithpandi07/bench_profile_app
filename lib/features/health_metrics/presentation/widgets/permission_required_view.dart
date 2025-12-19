import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequiredView extends StatelessWidget {
  final double cardCenterY;
  final Size size;
  final Color primaryColor;

  const PermissionRequiredView({
    super.key,
    required this.cardCenterY,
    required this.size,
    this.primaryColor = const Color(0xFFEE374D),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: cardCenterY - size.width,
          left: -size.width * 0.5,
          right: -size.width * 0.5,
          height: size.width * 1.65,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withOpacity(0.08),
                width: 1.5,
              ),
              gradient: RadialGradient(
                colors: [
                  Color.fromARGB(255, 207, 2, 153).withOpacity(0.04),
                  Color.fromARGB(255, 16, 16, 16).withOpacity(0.0),
                ],
                stops: const [0.7, 1.0],
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 64, color: primaryColor.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Permissions Locked',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Health permissions are required to show your dashboard. Please grant them in settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => openAppSettings(),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
