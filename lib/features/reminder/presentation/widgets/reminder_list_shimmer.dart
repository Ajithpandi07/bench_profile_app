import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/shimmer_loading.dart';

class ReminderListShimmer extends StatelessWidget {
  const ReminderListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
        itemCount: 4, // Match the number of standard reminders
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              width: 340,
              height: 119,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSkeleton(
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerSkeleton(width: 140, height: 16),
                        const SizedBox(height: 8),
                        const ShimmerSkeleton(width: 80, height: 14),
                        const SizedBox(height: 8),
                        const ShimmerSkeleton(width: 60, height: 14),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: ShimmerSkeleton(
                      width: 36,
                      height: 20,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
