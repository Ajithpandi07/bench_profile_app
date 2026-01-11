import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sleep_log.dart';

class SleepSummaryCard extends StatelessWidget {
  final SleepLog log;
  final VoidCallback? onTap;

  const SleepSummaryCard({super.key, required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    final duration = log.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    final startFormat = DateFormat('h:mm a');
    final endFormat = DateFormat('h:mm a');
    final timeRange =
        '${startFormat.format(log.startTime).toLowerCase()} - ${endFormat.format(log.endTime).toLowerCase()}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(
            0xFFFFF9FA,
          ), // Very light pinkish background from image
          borderRadius: BorderRadius.circular(32),
          // No shadow in the new design reference, flat look or very subtle
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEAEA), // Light pink circle
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bedtime_outlined,
                    color: Color(0xFFE11D48), // Pink/Red icon
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SLEEP TIME',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Middle: Duration + Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Duration
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$hours',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'h',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$minutes',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),

                // Chevron Arrow Circle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Footer: Time Range
            Text(
              timeRange,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
