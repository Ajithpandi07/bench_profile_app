import 'package:flutter/material.dart';

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart Area Shimmer
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Y-Axis Lines Shimmer
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        _buildShimmerBox(width: 30, height: 10),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            height: 1,
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bars Shimmer
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    7,
                    (index) => _buildShimmerBox(
                      width: 20,
                      height: (index % 3 + 1) * 50.0,
                      radius: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Goal Cards Shimmer
        Row(
          children: [
            Expanded(child: _buildGoalCardShimmer()),
            const SizedBox(width: 16),
            Expanded(child: _buildGoalCardShimmer()),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(width: 16, height: 16),
              const SizedBox(width: 8),
              _buildShimmerBox(width: 60, height: 10),
            ],
          ),
          const SizedBox(height: 12),
          _buildShimmerBox(width: 40, height: 20),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
