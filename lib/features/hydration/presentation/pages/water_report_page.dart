import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/app_date_selector.dart';
import '../../../../core/services/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../reminder/presentation/widgets/primary_button.dart';
import '../../../reminder/presentation/widgets/reminder_item_card.dart'; // Reusing for consistent look
import '../bloc/bloc.dart';
import 'hydration_tracker_page.dart';

class WaterReportPage extends StatefulWidget {
  const WaterReportPage({super.key});

  @override
  State<WaterReportPage> createState() => _WaterReportPageState();
}

class _WaterReportPageState extends State<WaterReportPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    context.read<HydrationBloc>().add(LoadHydrationLogs(_selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Water Report',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<HydrationBloc, HydrationState>(
        listener: (context, state) {
          if (state is HydrationFailure) {
            showModernSnackbar(context, state.message, isError: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 2),
              // Date Selector
              AppDateSelector(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadLogs();
                },
              ),
              const SizedBox(height: 16),

              // List
              Expanded(
                child: BlocBuilder<HydrationBloc, HydrationState>(
                  builder: (context, state) {
                    if (state is HydrationLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    } else if (state is HydrationLogsLoaded) {
                      if (state.logs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No water logs for this day',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      // Sorted by latest first (descending)
                      final logs = state.logs;

                      return ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: ReminderItemCard(
                              title: '${(log.amountLiters * 1000).toInt()}ml',
                              subtitle: log.beverageType,
                              scheduleType: 'Hydration',
                              time: DateFormat('hh:mm a').format(log.timestamp),
                              icon: Icons.water_drop,
                              color: Colors.blue,
                            ),
                          );
                        },
                      );
                    } else if (state is HydrationFailure) {
                      return const Center(
                        child: Text(
                          'Failed to load logs',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Add Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: PrimaryButton(
                  text: 'Add Water',
                  onPressed: () async {
                    // Navigate to Add Hydration Page
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<HydrationBloc>(),
                          child: const HydrationTrackerPage(),
                        ),
                      ),
                    );

                    // If we come back and result is true (saved), reload.
                    if (result == true) {
                      _loadLogs();
                    }
                  },
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
