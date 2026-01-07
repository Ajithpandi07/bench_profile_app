import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';

class MealReportShimmer extends StatelessWidget {
  const MealReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            height: 65,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon placeholder
                const ShimmerSkeleton(
                  width: 36,
                  height: 36,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                const SizedBox(width: 16),
                // Text placeholder
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      ShimmerSkeleton(width: 120, height: 14),
                      SizedBox(height: 6),
                      ShimmerSkeleton(width: 80, height: 12),
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
