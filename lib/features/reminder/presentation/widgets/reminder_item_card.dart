import 'package:flutter/material.dart';
import '../../../../core/services/app_theme.dart';

class ReminderItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String scheduleType;
  final VoidCallback? onEdit;
  final Color? color;
  final IconData? icon;

  const ReminderItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.scheduleType,
    this.onEdit,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65, // Fixed height as per user request
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8), // Adjusted padding to fit height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding:
                const EdgeInsets.all(8), // Reduced padding for icon container
            decoration: BoxDecoration(
              color: (color ?? Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon ?? Icons.notifications,
              color: color ?? Colors.blue,
              size: 20, // Reduced icon size
            ),
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center text vertically
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14, // Slightly reduced font size
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1617),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (color ?? Colors.blue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scheduleType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color ?? Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11, // Slightly reduced font size
                    color: Color(0xFF7B6F72),
                  ),
                ),
              ],
            ),
          ),
          // Edit Button
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.transparent,
                child: const Icon(
                  Icons.edit_square, // Matches the "square with pencil" look
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
