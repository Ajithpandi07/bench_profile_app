// lib/features/auth/presentation/pages/profile_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/core.dart';
import '../../../health_metrics/health_metrics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bloc.dart';
import '../../../../core/injection_container.dart';
import '../../../reminder/presentation/bloc/reminder_bloc.dart';
import '../../../reminder/presentation/bloc/reminder_event.dart';
import '../../../reminder/presentation/pages/reminder_page.dart';
import '../../../health_metrics/presentation/pages/health_metrics_settings_page.dart';

class ProfilePage extends StatelessWidget {
  final HealthMetricsSummary? metrics; // optional summary to show quick stats

  const ProfilePage({Key? key, this.metrics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeService = ThemeService();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: user?.photoURL == null
                    ? Text(
                        _initials(user?.displayName ?? user?.email ?? 'U'),
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
                foregroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Unknown User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '—',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit profile',
                onPressed: () {
                  // optional: show profile edit flow
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile edit not implemented'),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick stats card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: _statColumn(
                      'Steps',
                      metrics?.steps?.value.round().toString() ?? '—',
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: _statColumn(
                      'Calories',
                      metrics?.activeEnergyBurned != null
                          ? metrics!.activeEnergyBurned!.value.toStringAsFixed(
                              0,
                            )
                          : '—',
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(child: _statColumn('Sleep', '—')),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Preferences / actions
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Theme'),
                  subtitle: const Text('Toggle light/dark mode'),
                  trailing: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeService.mode,
                    builder: (context, mode, _) {
                      return PopupMenuButton<ThemeMode>(
                        initialValue: mode,
                        onSelected: (sel) => themeService.setMode(sel),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: ThemeMode.system,
                            child: const Text('System'),
                          ),
                          PopupMenuItem(
                            value: ThemeMode.light,
                            child: const Text('Light'),
                          ),
                          PopupMenuItem(
                            value: ThemeMode.dark,
                            child: const Text('Dark'),
                          ),
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_modeLabel(mode)),
                            const SizedBox(width: 8),
                            Icon(Icons.keyboard_arrow_down),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy'),
                  subtitle: const Text('Manage permissions & data'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy not implemented')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.health_and_safety_outlined),
                  title: const Text('Health Data Settings'),
                  subtitle: const Text('Manage disconnected data types'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthMetricsSettingsPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: const Text('Reminders'),
                  subtitle: const Text('Manage your daily reminders'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider<ReminderBloc>(
                          create: (context) =>
                              sl<ReminderBloc>()..add(LoadReminders()),
                          child: const ReminderPage(
                            initialCategory:
                                'Activity', // Default or make generic
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Support'),
                  subtitle: const Text('Contact us or send feedback'),
                  onTap: () {
                    // open support flow
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sign out
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            onPressed: () => _confirmSignOut(context),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              'App version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _verticalDivider() =>
      Container(width: 1, height: 44, color: Colors.grey.withOpacity(0.12));

  Widget _statColumn(String label, String value) => Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  static String _initials(String? s) {
    if (s == null || s.trim().isEmpty) return 'U';
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
      default:
        return 'System';
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // dispatch sign-out via AuthBloc
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
