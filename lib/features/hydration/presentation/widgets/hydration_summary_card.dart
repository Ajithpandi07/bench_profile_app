import 'package:flutter/material.dart';

class HydrationSummaryCard extends StatelessWidget {
  final double currentLiters;
  final double targetLiters;
  final String? lastAddedTime;

  const HydrationSummaryCard({
    super.key,
    required this.currentLiters,
    this.targetLiters = 3.0,
    this.lastAddedTime,
  });

  @override
  Widget build(BuildContext context) {
    final currentMl = (currentLiters * 1000).toInt();
    final remainingLiters = (targetLiters - currentLiters).clamp(
      0.0,
      targetLiters,
    );
    // Simple string formatting for remaining
    String remainingText = remainingLiters % 1 == 0
        ? '${remainingLiters.toInt()} Litre remaining'
        : '${remainingLiters.toStringAsFixed(1)} Litre remaining';

    // If goal reached
    if (currentLiters >= targetLiters) {
      remainingText = "Goal Reached!";
    }

    final progress = (currentLiters / targetLiters).clamp(0.0, 1.0);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 356),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 356,
          height: 192,
          child: Container(
            padding: const EdgeInsets.all(20), // Reduced from 24
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WATER',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4), // Reduced from 8
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$currentMl',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF131313),
                                height: 1.0, // Tighter line height
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ml',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Color(0xFF3B9BFF),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const Spacer(), // Use Spacer to distribute available space instead of fixed SizedBox
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: ${targetLiters % 1 == 0 ? targetLiters.toInt() : targetLiters.toStringAsFixed(2)} Litre',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      remainingText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced from 12
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          height: 12,
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEE374D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                if (lastAddedTime != null) ...[
                  const SizedBox(height: 12), // Reduced from 16
                  Center(
                    child: Text(
                      'Last water added at $lastAddedTime',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
