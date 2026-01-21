import 'package:flutter/material.dart';

class ReminderItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String scheduleType;
  final String? time; // Added time field
  final Color? color;
  final IconData? icon;

  final bool isEnabled;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap; // Added onTap

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (color ?? Colors.blue).withValues(alpha: 0.1),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.3,
                        ),
                      ),
                      if (time != null && time!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatTimes(time!),
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
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      trackOutlineColor: MaterialStateProperty.all(
                        Colors.transparent,
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

  String _formatTimes(String rawTime) {
    if (!rawTime.contains(',')) {
      return _formatSingleTime(rawTime);
    }
    final times = rawTime.split(',').map((e) => e.trim());
    return times.map((t) => _formatSingleTime(t)).join(', ');
  }

  String _formatSingleTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return t;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return t;

    // Determine AM/PM
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}
