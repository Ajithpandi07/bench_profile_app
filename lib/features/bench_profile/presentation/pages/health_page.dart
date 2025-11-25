import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/health_bloc.dart';
import '../bloc/health_state.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bench Profile Health'),
      ),
      body: BlocBuilder<HealthBloc, HealthState>(
        builder: (context, state) {
          if (state is HealthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HealthLoaded) {
            return Center(
              child: Text(
                'Steps: ${state.metrics.steps}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            );
          } else if (state is HealthFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Fetching health status...'));
        },
      ),
    );
  }
}