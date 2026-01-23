import 'package:flutter/material.dart';

class ReminderItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? detail1; // e.g. "Every 2 Hrs" or "7:30 PM"
  final String? detail2; // e.g. "Breakfast" or "Cycling"
  final Color? color;
  final IconData? icon;

  final bool isEnabled;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  const ReminderItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.detail1,
    this.detail2,
    this.color,
    this.icon,
    this.isEnabled = true,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.blue;

    return Container(
      width: 340,
      height: 119,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 32.6,
            offset: const Offset(0, 19),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon ?? Icons.notifications,
                    color: themeColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 20),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (detail1 != null && detail1!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail1!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: themeColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      if (detail2 != null && detail2!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          detail2!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Toggle Switch
                if (onToggle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: isEnabled,
                        onChanged: onToggle,
                        activeColor: Colors.white,
                        activeTrackColor: const Color(
                          0xFFFF5252,
                        ), // Matching the mockup's red/pink active color
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
                        trackOutlineColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
