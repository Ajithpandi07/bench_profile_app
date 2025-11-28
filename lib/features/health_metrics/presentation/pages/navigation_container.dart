import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';


class NavigationContainer extends StatefulWidget {
  const NavigationContainer({super.key});

  @override
  State<NavigationContainer> createState() => _NavigationContainerState();
}

class _NavigationContainerState extends State<NavigationContainer> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    // const DashboardPage(),
    // const _ProfileTab(),
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
          _selectedIndex == 0 ? 'Dashboard' : 'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(SignOutRequested());
              // The listener in login_page will handle navigation
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
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
// class _ProfileTab extends StatelessWidget {
//   const _ProfileTab();

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<HealthBloc, HealthState>(
//       builder: (context, state) {
//         if (state is HealthLoaded) {
//           return ProfilePage(metrics: state.metrics);
//         }
//         if (state is HealthLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (state is HealthFailure) {
//           return Center(child: Text('Could not load profile data: ${state.message}'));
//         }
//         // For AuthInitial, etc.
//         return const Center(child: Text('No health data available. Visit the dashboard to fetch it.'));
//       },
//     );
//   }

