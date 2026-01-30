import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sleep_log.dart';

class SleepSummaryCard extends StatelessWidget {
  final SleepLog? log;
  final Duration? totalDuration;
  final VoidCallback? onTap;

  const SleepSummaryCard({super.key, this.log, this.totalDuration, this.onTap});

  @override
  Widget build(BuildContext context) {
    // If no log, show "0 h" and empty times
    final hasLog = log != null;
    final duration = totalDuration ?? (hasLog ? log!.duration : Duration.zero);
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
        width: double.infinity,
        constraints: BoxConstraints(minHeight: hasLog ? 256 : 184),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
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
                Text(
                  'Sleep time',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.bedtime_outlined, // Moon outline style
                    color: Theme.of(context).primaryColor,
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
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'h',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).hintColor.withOpacity(0.5),
                  ),
                ),
                if (m > 0 || !hasLog) ...[
                  const SizedBox(width: 16),
                  Text(
                    hasLog
                        ? '$m'
                        : '', // Empty string if no log, layout wise ok
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (hasLog) const SizedBox(width: 4),
                  if (hasLog)
                    Text(
                      'm',
                      style: TextStyle(
                        fontSize: 40, // Slightly bigger 'm' from screenshot
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).hintColor.withOpacity(0.5),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 24),

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
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.6),
                              ],
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
                            color: Theme.of(context).hintColor.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      startTimeStr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                // Arrow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: Theme.of(context).hintColor,
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
                        color: Theme.of(context).hintColor.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      endTimeStr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
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
