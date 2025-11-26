import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/health_metrics.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../bloc/health_state.dart';
import 'profile_page.dart';
import '../widgets/circular_score_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Post-frame callback ensures the widget tree is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check provider existence safely before reading
      final providerExists =
          context.findAncestorWidgetOfExactType<BlocProvider<HealthBloc>>() !=
              null;
      if (providerExists) {
        // Always fetch fresh data from the device on initial load.
        context.read<HealthBloc>().add(FetchHealthRequested());
      } else {
        debugPrint('HealthBloc provider not found during init; skipping fetch.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<HealthBloc, HealthState>(
          listener: (context, state) {
            if (state is HealthFailure) {
              _showPermissionDialog(context, state.message);
            }
            if (state is HealthUploadInProgress) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                    const SnackBar(content: Text('Uploading metrics...')));
            }
            if (state is HealthUploadSuccess) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                    const SnackBar(content: Text('Metrics uploaded successfully!')));
            }
            if (state is HealthUploadFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text('Upload failed: ${state.message}')));
            }
          },
          builder: (context, state) {
            final metrics = state is HealthLoaded ? state.metrics : null;
            final isLoading = state is HealthLoading;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                  CircularScoreCard(metrics: metrics),
                  const SizedBox(height: 24),
                  if (state is HealthFailure)
                    Center(
                      child: Text('Error: ${state.message}',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  if (metrics != null)
                    _buildActionsCard(context, metrics),
                  if (!isLoading && metrics == null && state is! HealthFailure)
                    const Center(child: Text('No data yet. Press Sync to fetch.')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, HealthMetrics metrics) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Source', style: Theme.of(context).textTheme.labelMedium),
                  Text(metrics.source, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(
                      'Heart: ${metrics.heartRate != null ? '${metrics.heartRate!.toStringAsFixed(1)} bpm' : 'N/A'}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProfilePage(metrics: metrics))),
                  child: const Text('Profile'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // The "Sync" button now fetches from device and then uploads.
                    context.read<HealthBloc>().add(FetchHealthRequested());
                  },
                  child: const Text('Sync'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Permissions required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<HealthBloc>().add(FetchHealthRequested());
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

                   