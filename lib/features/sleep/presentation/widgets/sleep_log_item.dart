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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.05),
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
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2), // Light red bg
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bedtime_rounded,
                color: Color(0xFFEF4444), // Red
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF131313),
                          ),
                        ),
                        if (h > 0)
                          const TextSpan(
                            text: 'h ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF909DAD),
                            ),
                          ),
                        TextSpan(
                          text: '$m',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF131313),
                          ),
                        ),
                        const TextSpan(
                          text: 'm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF909DAD),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('h:mm a').format(log.startTime)} - ${DateFormat('h:mm a').format(log.endTime)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF909DAD),
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
