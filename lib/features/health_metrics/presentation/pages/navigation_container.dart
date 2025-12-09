import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bench_profile_app/features/auth/presentation/pages/profile_page.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_bloc.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_state.dart';
import 'package:bench_profile_app/features/health_metrics/presentation/bloc/health_metrics_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import 'health_metrics_page.dart';


class NavigationContainer extends StatefulWidget {
  const NavigationContainer({super.key});

  @override
  State<NavigationContainer> createState() => _NavigationContainerState();
}

class _NavigationContainerState extends State<NavigationContainer> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const HealthMetricsPage(),
    const _ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          _selectedIndex == 0 ? 'Health Metrics' : 'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          if (_selectedIndex == 0) // Only show on Health Metrics tab
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // The HealthMetricsPage's state holds the currently selected date.
                // A better approach would be to manage the selected date in the BLoC.
                // For now, we will just refetch for today.
                context.read<HealthMetricsBloc>().add(GetMetricsForDate(DateTime.now()));
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(SignOutRequested());
              // The AuthWrapper will handle navigation automatically.
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            activeIcon: Icon(Icons.monitor_heart),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Optional: Style your navigation bar
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
/// A wrapper for the profile tab that provides HealthMetrics to the ProfilePage.
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthMetricsBloc, HealthMetricsState>(
      builder: (context, state) {
        if (state is HealthMetricsLoaded) {
          return ProfilePage(metrics: state.metrics);
        }
        if (state is HealthMetricsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is HealthMetricsError) {
          return Center(child: Text('Could not load profile data: ${state.message}'));
        }
        // For initial / empty
        return const Center(child: Text('No health data available. Visit the dashboard to fetch it.'));
      },
    );
  }
}

