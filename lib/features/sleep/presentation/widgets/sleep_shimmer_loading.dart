import 'package:flutter/material.dart';

class SleepShimmerLoading extends StatelessWidget {
  const SleepShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 100, height: 20, color: Colors.grey[200]),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Big Duration
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Container(width: 80, height: 60, color: Colors.grey[200]),
                    const SizedBox(width: 8),
                    Container(width: 40, height: 30, color: Colors.grey[200]),
                  ],
                ),
                const SizedBox(height: 24),
                // Times
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 12,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 24,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 12,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 24,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ],
      ),
    );
  }
}
