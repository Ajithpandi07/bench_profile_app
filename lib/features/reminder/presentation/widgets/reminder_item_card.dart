import 'package:flutter/material.dart';
import '../../../../core/services/app_theme.dart';

class ReminderItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String scheduleType;
  final String? time; // Added time field
  final Color? color;
  final IconData? icon;

  final bool isEnabled;
  final ValueChanged<bool>? onToggle;

  const ReminderItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.scheduleType,
    this.time,
    this.color,
    this.icon,
    this.isEnabled = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (color ?? Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon ?? Icons.notifications,
              color: color ?? Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Wrap content
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1617),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7B6F72),
                    height: 1.3,
                  ),
                ),
                if (time != null && time!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    time!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color ?? Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Toggle Switch
          if (onToggle != null)
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeColor: Colors.white,
                activeTrackColor: AppTheme.primaryColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade200,
                trackOutlineColor: MaterialStateProperty.all(
                  Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
