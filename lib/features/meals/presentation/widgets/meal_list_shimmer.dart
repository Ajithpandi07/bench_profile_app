import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';

class MealListShimmer extends StatelessWidget {
  const MealListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, // Background for the "card"
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerSkeleton(width: 150, height: 16),
                    SizedBox(height: 8),
                    ShimmerSkeleton(width: 100, height: 13),
                  ],
                ),
                const ShimmerSkeleton(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
