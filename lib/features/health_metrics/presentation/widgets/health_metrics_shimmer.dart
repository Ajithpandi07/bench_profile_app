import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';

class HealthMetricsListShimmer extends StatelessWidget {
  const HealthMetricsListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                ShimmerSkeleton(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerSkeleton(width: 120, height: 16),
                      SizedBox(height: 8),
                      ShimmerSkeleton(width: 80, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
