import 'package:flutter/material.dart';

class SleepInsightCard extends StatelessWidget {
  final double percentageChange; // e.g. 12 means +12%, -5 means -5%

  const SleepInsightCard({super.key, required this.percentageChange});

  @override
  Widget build(BuildContext context) {
    bool isPositive = percentageChange >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3), // Light blue bg
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor, // Icon bg
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Great job!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Your sleep duration has ',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: isPositive ? 'increased' : 'decreased',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' by '),
                      TextSpan(
                        text: '${percentageChange.abs().toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                            ' compared to last week. Keep maintaining this schedule.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
