import 'package:flutter/material.dart';
import '../shimmer_effect.dart';

class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date Range Text
        const ShimmerEffect.rectangular(height: 14, width: 120, radius: 4),
        const SizedBox(height: 12),

        // Average Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const ShimmerEffect.rectangular(height: 48, width: 60, radius: 8),
            const SizedBox(width: 8),
            const ShimmerEffect.rectangular(height: 24, width: 30, radius: 4),
          ],
        ),
        const SizedBox(height: 4),
        const ShimmerEffect.rectangular(height: 12, width: 100, radius: 4),
        const SizedBox(height: 32),

        // Goals
        Row(
          children: [
            Expanded(child: _buildGoalCardShimmer()),
            const SizedBox(width: 16),
            Expanded(child: _buildGoalCardShimmer()),
          ],
        ),
        const SizedBox(height: 32),

        // Chart
        Container(
          height: 280,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              // Sine wave like pattern for bars
              final height = 50.0 + (index % 3) * 40 + (index % 2) * 20;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShimmerEffect.rectangular(
                    height: height,
                    width: 20,
                    radius: 6,
                  ),
                  const SizedBox(height: 8),
                  const ShimmerEffect.rectangular(
                    height: 10,
                    width: 20,
                    radius: 2,
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 32),

        // Insight Card
        const ShimmerEffect.rectangular(
          height: 80,
          width: double.infinity,
          radius: 16,
        ),
      ],
    );
  }

  Widget _buildGoalCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerEffect.rectangular(height: 16, width: 16, radius: 4),
              const SizedBox(width: 8),
              const ShimmerEffect.rectangular(height: 10, width: 60, radius: 2),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerEffect.rectangular(height: 24, width: 40, radius: 4),
        ],
      ),
    );
  }
}
