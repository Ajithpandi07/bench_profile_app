import 'package:flutter/material.dart';

class ActivitySummaryCard extends StatelessWidget {
  final double activeTimeMinutes;
  final double caloriesBurned;
  final int stepCount;

  const ActivitySummaryCard({
    super.key,
    required this.activeTimeMinutes,
    required this.caloriesBurned,
    this.stepCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4), // Visual margin
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildRingItem(
            label: 'STEPS',
            value: '$stepCount',
            subValue: '/ 4000',
            color: const Color(0xFF00C853), // Green
            progress: (stepCount / 4000).clamp(0.0, 1.0),
            icon: Icons.directions_walk,
          ),
          _buildRingItem(
            label: 'ACTIVE TIME',
            value: activeTimeMinutes.toInt().toString(),
            subValue: '/ 90 mins',
            color: const Color(0xFF2962FF), // Blue
            progress: (activeTimeMinutes / 90).clamp(0.0, 1.0),
            icon: Icons.access_time,
          ),
          _buildRingItem(
            label: 'ACTIVITY',
            value: caloriesBurned.toInt().toString(),
            subValue: '/ 500Kcal',
            color: const Color(0xFFD50000), // Red
            progress: (caloriesBurned / 500).clamp(0.0, 1.0),
            icon: Icons.local_fire_department,
          ),
        ],
      ),
    );
  }

  Widget _buildRingItem({
    required String label,
    required String value,
    required String subValue,
    required Color color,
    required double progress,
    required IconData icon,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    color: Colors.grey.shade100,
                    strokeWidth: 6,
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    color: color,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Center(child: Icon(icon, color: color, size: 20)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF131313),
          ),
        ),
        Text(
          subValue,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
