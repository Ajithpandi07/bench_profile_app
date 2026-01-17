import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';

class ActivityReportShimmer extends StatelessWidget {
  const ActivityReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          // Summary Card Placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),

          // List Items
          ...List.generate(
            4,
            (index) => Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const ShimmerSkeleton(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      ShimmerSkeleton(width: 100, height: 14),
                      SizedBox(height: 6),
                      ShimmerSkeleton(width: 60, height: 12),
                    ],
                  ),
                  const Spacer(),
                  const ShimmerSkeleton(width: 60, height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
