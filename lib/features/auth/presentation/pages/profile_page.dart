import 'package:flutter/material.dart';
import '../../../health_metrics/domain/entities/health_metrics.dart';
import '../../../health_metrics/presentation/widgets/circular_score_card.dart';

class ProfilePage extends StatelessWidget {
  final HealthMetrics metrics;
  const ProfilePage({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(radius: 28, backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Metrics source: ${metrics.source}', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 180,
                  child: CircularScoreCard(metrics: metrics, showQuickActions: false),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(children: [Icon(Icons.favorite, color: Colors.redAccent), const SizedBox(width: 8), const Text('Heart')]),
                          const SizedBox(height: 8),
                          Text(metrics.heartRate != null ? '${metrics.heartRate!.toStringAsFixed(1)} bpm' : 'N/A', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('This is a lightweight profile placeholder. You can extend this with user-editable fields, avatar upload, and account settings.'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync is available from the Dashboard')));
                        }, child: const Text('Sync'))
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
