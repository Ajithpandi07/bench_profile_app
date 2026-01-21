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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 356,
        height: 81,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1), // Light red bg
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bedtime_rounded,
                color: Theme.of(context).primaryColor, // Red
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Duration and Time
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: h > 0 ? '$h' : '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (h > 0)
                          TextSpan(
                            text: 'h ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        TextSpan(
                          text: '$m',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: 'm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('h:mm a').format(log.startTime)} - ${DateFormat('h:mm a').format(log.endTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
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
