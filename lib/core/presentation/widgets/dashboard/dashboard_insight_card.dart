import 'package:flutter/material.dart';

class DashboardInsightCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color backgroundColor;

  const DashboardInsightCard({
    super.key,
    this.title = 'Great job!',
    required this.message,
    this.icon = Icons.auto_awesome,
    this.iconBackgroundColor = Colors.blue,
    this.backgroundColor = const Color(0xFFF0F8FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF131313),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
