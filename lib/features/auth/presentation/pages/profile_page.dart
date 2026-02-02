import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../health_metrics/health_metrics.dart';
import '../bloc/bloc.dart';
import '../../../../core/injection_container.dart';
import '../../../reminder/presentation/bloc/reminder_bloc.dart';
import '../../../reminder/presentation/bloc/reminder_event.dart';
import '../../../reminder/presentation/pages/reminder_page.dart';

class ProfilePage extends StatelessWidget {
  final HealthMetricsSummary? metrics;

  const ProfilePage({Key? key, this.metrics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC), // Light greyish background
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.redAccent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Avatar & Info
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.2),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Text(
                                  _initials(
                                    user?.displayName ?? user?.email ?? 'U',
                                  ),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    user?.email ?? '@username',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Keep Going Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFFF8A80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Keep going!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your profile is 91% complete. Update missing info to unlock features.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Complete Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Progress Circle Placeholder
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 0.91,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        const Text(
                          '91%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Targets Section (New)
            BlocBuilder<UserProfileBloc, UserProfileState>(
              builder: (context, state) {
                if (state is UserProfileLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is UserProfileError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Error loading targets: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (state is UserProfileLoaded) {
                  final calories = state.profile.targetCalories;
                  final water = state.profile.targetWater;
                  // ignore: avoid_print
                  print(
                    'DEBUG ProfilePage: Loaded. Calories: $calories, Water: $water',
                  );

                  if (calories != null || water != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('YOUR TARGETS'),
                        const SizedBox(height: 8),
                        _buildSettingsContainer(
                          children: [
                            if (calories != null)
                              _buildSettingsTile(
                                context,
                                icon: Icons.local_fire_department,
                                iconColor: Colors.orange,
                                title: 'Daily Calories',
                                trailingText: '${calories.toInt()} kcal',
                                onTap: () {},
                                showArrow: false,
                              ),
                            if (calories != null && water != null)
                              _buildDivider(),
                            if (water != null)
                              _buildSettingsTile(
                                context,
                                icon: Icons.water_drop,
                                iconColor: Colors.blue,
                                title: 'Daily Water',
                                trailingText: '${water.toInt()} ml',
                                onTap: () {},
                                showArrow: false,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'No targets found in profile (calories/water are null).',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                }
                // Initial State
                return const SizedBox.shrink();
              },
            ),

            // 3. Statistics Card
            _buildNavigationCard(
              context,
              icon: Icons.pie_chart_outline,
              iconColor: Colors.orange,
              title: 'Statistics',
              subtitle: 'Check your activities and progress',
              onTap: () {
                // Navigate to HealthMetricsDashboard or Statistics Page
                // Assuming currently passing through, but could be specific page
              },
            ),

            const SizedBox(height: 24),

            // 4. Settings Section
            _buildSectionHeader('SETTINGS'),
            const SizedBox(height: 8),
            _buildSettingsContainer(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_none,
                  iconColor: Colors.redAccent,
                  title: 'Reminders',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider<ReminderBloc>(
                          create: (context) =>
                              sl<ReminderBloc>()..add(LoadReminders()),
                          child: const ReminderPage(
                            initialCategory: 'Activity',
                          ),
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.straighten,
                  iconColor: Colors.pinkAccent,
                  title: 'Measurement',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.scale_outlined,
                  iconColor: Colors.redAccent,
                  title: 'Unit System',
                  trailingText: 'Metric',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 5. Directory & Feedback
            _buildSectionHeader('DIRECTORY & FEEDBACK'),
            const SizedBox(height: 8),
            _buildSettingsContainer(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.map_outlined,
                  iconColor: Colors.blueAccent,
                  title: 'Bench Directory',
                  trailingIcon: Icons.open_in_new,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.amber,
                  title: 'Review Your Center',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 6. System
            _buildSectionHeader('SYSTEM'),
            const SizedBox(height: 8),
            _buildSettingsContainer(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.cleaning_services_outlined,
                  iconColor: Colors.grey,
                  title: 'Clear App Data',
                  subtitle: 'Remove all cached data and preferences',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.delete_outline,
                  iconColor: Colors.redAccent,
                  title: 'Delete Account',
                  textColor: Colors.redAccent,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.logout,
                  iconColor: Colors.grey,
                  title: 'Logout',
                  onTap: () => _confirmSignOut(context),
                  showArrow: false,
                ),
              ],
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Version 2.4.0 (Build 390)',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSettingsContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? trailingText,
    IconData? trailingIcon,
    Color? textColor,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(
                  color: Colors.blueAccent.shade200,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (trailingIcon != null)
              Icon(trailingIcon, size: 16, color: Colors.blueAccent.shade100),
            if (showArrow && trailingText == null && trailingIcon == null)
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }

  String _initials(String? s) {
    if (s == null || s.trim().isEmpty) return 'U';
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
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
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
