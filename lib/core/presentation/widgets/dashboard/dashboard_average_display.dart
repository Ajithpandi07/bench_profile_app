import 'package:flutter/material.dart';

class DashboardAverageDisplay extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const DashboardAverageDisplay({
    super.key,
    required this.value,
    required this.unit,
    this.label = 'Average',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF131313),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
