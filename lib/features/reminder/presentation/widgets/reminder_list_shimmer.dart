import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';

class ReminderListShimmer extends StatelessWidget {
  const ReminderListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        itemCount: 6, // Show a few placeholder items
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const ShimmerSkeleton(
                  width: 50,
                  height: 50,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerSkeleton(width: double.infinity, height: 16),
                      SizedBox(height: 8),
                      ShimmerSkeleton(width: 100, height: 12),
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
