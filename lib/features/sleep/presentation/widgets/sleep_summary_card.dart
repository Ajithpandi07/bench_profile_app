import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sleep_log.dart';

class SleepSummaryCard extends StatelessWidget {
  final SleepLog? log;
  final VoidCallback? onTap;

  const SleepSummaryCard({super.key, this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    // If no log, show "0 h" and empty times
    final hasLog = log != null;
    final duration = hasLog ? log!.duration : Duration.zero;
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);

    String startTimeStr = '__ h __ m';
    String endTimeStr = '__ h __ m';

    if (hasLog) {
      startTimeStr = DateFormat('h:mm a').format(log!.startTime);
      endTimeStr = DateFormat('h:mm a').format(log!.endTime);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 356,
        height: 192,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: "Sleep time" and Moon Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sleep time',
                  style: TextStyle(
                    color: Color(0xFF6B7280), // Colors.grey[500]
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2), // Light red bg
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.bedtime_outlined, // Moon outline style
                    color: Color(0xFFEF4444), // Red color
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Big Duration Text (e.g. "9 h" or "9 h 30 m")
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$h',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'h',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD1D5DB), // Light grey
                  ),
                ),
                if (m > 0 || !hasLog) ...[
                  const SizedBox(width: 16),
                  Text(
                    hasLog
                        ? '$m'
                        : '', // Empty string if no log, layout wise ok
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (hasLog) const SizedBox(width: 4),
                  if (hasLog)
                    const Text(
                      'm',
                      style: TextStyle(
                        fontSize: 40, // Slightly bigger 'm' from screenshot
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD1D5DB),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // Bedtime -> Wake Up Visual Row
            Row(
              children: [
                // BEDTIME
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFFF8A8A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BEDTIME',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280).withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      startTimeStr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),

                // Arrow
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                ),

                // WAKE UP
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WAKE UP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280).withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      endTimeStr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
