import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sleep_log.dart';

class SleepLogItem extends StatelessWidget {
  final SleepLog log;
  final VoidCallback? onTap;

  const SleepLogItem({super.key, required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    final duration = log.duration;
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);

    // Start time
    final timeString = DateFormat('h:mm a').format(log.startTime);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC), // very light grey/blue
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bedtime_rounded,
                color: Color(0xFFEF4444), // Red
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SLEEP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B), // Slate 500
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8), // Slate 400
                    ),
                  ),
                ],
              ),
            ),

            // Value
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: h > 0 ? '$h' : '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A), // Slate 900
                    ),
                  ),
                  if (h > 0)
                    const TextSpan(
                      text: 'h ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  TextSpan(
                    text: '$m',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const TextSpan(
                    text: 'm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
