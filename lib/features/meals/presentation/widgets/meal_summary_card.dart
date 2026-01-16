import 'package:flutter/material.dart';

class MealSummaryCard extends StatelessWidget {
  final double currentKcal;
  final double targetKcal;
  final String? lastAddedTime;

  const MealSummaryCard({
    super.key,
    required this.currentKcal,
    this.targetKcal = 450.0, // Default to 450 or as passed
    this.lastAddedTime,
  });

  @override
  Widget build(BuildContext context) {
    final remainingKcal = (targetKcal - currentKcal).clamp(0.0, targetKcal);
    final remainingText = '${remainingKcal.toInt()} kcal remaining';

    final progress = (currentKcal / targetKcal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 192),
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FOOD',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${currentKcal.toInt()}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF131313),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kcal',
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
                  color: Color(0xFFFFEBEB), // Light red bg
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .restaurant, // Or equivalent fork/knife icon as per request image
                  color: Color(0xFFEE374D), // Red accent
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: ${targetKcal.toInt()} kcal',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Text(
                remainingText,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Last meal added at $lastAddedTime',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
