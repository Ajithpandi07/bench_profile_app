import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/reminder_list_shimmer.dart';
import '../../domain/entities/reminder.dart';

import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_state.dart';
import '../bloc/reminder_event.dart';
import '../../../../../core/presentation/widgets/app_date_selector.dart';

import '../widgets/reminder_item_card.dart';
import '../widgets/reminder_empty_state.dart';
import '../widgets/add_reminder_modal.dart';
import '../widgets/primary_button.dart';

import '../../../../core/utils/snackbar_utils.dart';

class ReminderPage extends StatefulWidget {
  final String? initialCategory; // Added support for initialCategory

  const ReminderPage({super.key, this.initialCategory});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<ReminderBloc>().add(
      LoadReminders(selectedDate: _selectedDate),
    );
    // Ensure notifications are in sync with the DB
    context.read<ReminderBloc>().add(RescheduleAllNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color:
                  Theme.of(context).appBarTheme.foregroundColor ?? Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Reminder',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).primaryColor,
              size: 26,
            ),
            onPressed: () => _openAddModal(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is ReminderOperationSuccess) {
            showModernSnackbar(context, state.message);
          } else if (state is ReminderError) {
            showModernSnackbar(context, state.message, isError: true);
          }
        },
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 2),
              // App Date Selector (Shared)
              AppDateSelector(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                  context.read<ReminderBloc>().add(
                    LoadReminders(selectedDate: date),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Reminders List
              Expanded(
                child: BlocBuilder<ReminderBloc, ReminderState>(
                  builder: (context, state) {
                    if (state is ReminderLoading) {
                      return const ReminderListShimmer();
                    } else if (state is ReminderLoaded) {
                      final reminders = state.reminders;

                      final dispReminders = reminders.toList();

                      if (dispReminders.isEmpty) {
                        return ReminderEmptyState(
                          onAdd: () => _openAddModal(context),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 10,
                        ),
                        children: [
                          ...dispReminders.map(
                            (r) => _buildStandardReminderCard(context, r),
                          ),
                          const SizedBox(height: 32),
                          PrimaryButton(
                            text: 'Add Reminder',
                            onPressed: () => _openAddModal(context),
                          ),
                          const SizedBox(height: 40),
                        ],
                      );
                    } else if (state is ReminderError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardReminderCard(BuildContext context, Reminder reminder) {
    bool isSkipped = false;
    if (reminder.skippedDates != null) {
      isSkipped = reminder.skippedDates!.any(
        (d) =>
            d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day,
      );
    }
    final isEnabled = !isSkipped;

    String title = '';
    String subtitle = '';
    String? detail1;
    String? detail2;

    final category = reminder.category.toLowerCase();
    if (category == 'water' || category == 'hydration') {
      title = 'Water Reminder';
      subtitle = 'Drink Water';
      detail1 = 'Every 2 Hrs';
    } else if (category == 'meal' || category == 'food') {
      title = 'Food Reminder';
      subtitle = 'Take Your Food';
      final mealInfo = _getUpcomingMealInfo(reminder.time);
      detail1 = mealInfo['time'] ?? '';
      detail2 = mealInfo['name'];
    } else if (category == 'activity' || category == 'workout') {
      title = 'Activity Reminder';
      subtitle = 'Time to Move';
      detail1 = _formatTime(reminder.time);
      detail2 = 'Cycling';
    } else if (category == 'sleep') {
      title = 'Sleep Reminder';
      subtitle = 'Time to Sleep';
      detail1 = _formatTime(reminder.time);
    } else {
      title = reminder.name;
      subtitle = 'Reminder';
      detail1 = _formatTime(reminder.time);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ReminderItemCard(
        title: title,
        subtitle: subtitle,
        detail1: detail1,
        detail2: detail2,
        icon: _getIconForCategory(reminder.category),
        color: _getColorForCategory(reminder.category),
        isEnabled: isEnabled,
        onToggle: (val) {
          _toggleReminder(context, reminder, val);
        },
      ),
    );
  }

  void _openAddModal(BuildContext context) {
    final reminderBloc = context.read<ReminderBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddReminderModal(),
    ).then((_) {
      // Refresh list after modal closed
      if (mounted) {
        reminderBloc.add(LoadReminders(selectedDate: _selectedDate));
      }
    });
  }

  Map<String, String> _getUpcomingMealInfo(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return {'time': '', 'name': 'Meal'};

    final now = DateTime.now();
    // Only use current time logic if selected date is TODAY
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final times = rawTime.split(',').map((e) => e.trim()).toList();
    times.sort((a, b) => _parseTime(a).compareTo(_parseTime(b)));

    String selectedTime = times.first;
    if (isToday) {
      final currentTimeVal = now.hour * 60 + now.minute;
      for (final t in times) {
        if (_parseTime(t) > currentTimeVal) {
          selectedTime = t;
          break;
        }
      }
    }

    final formattedTime = _formatSingleTime(selectedTime);

    String name = 'Meal';
    final hour = _parseTime(selectedTime) ~/ 60;
    if (hour < 11) {
      name = 'Breakfast';
    } else if (hour < 16) {
      name = 'Lunch';
    } else {
      name = 'Dinner';
    }

    return {'time': formattedTime, 'name': name};
  }

  int _parseTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return 0;
    try {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  String _formatSingleTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return t;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return t;

    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  String _formatTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return '';
    final firstTime = rawTime.split(',').first.trim();
    return _formatSingleTime(firstTime);
  }

  void _toggleReminder(
    BuildContext context,
    Reminder reminder,
    bool isEnabled,
  ) {
    context.read<ReminderBloc>().add(
      ToggleReminderForDate(
        reminder: reminder,
        date: _selectedDate,
        isEnabled: isEnabled,
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'water':
      case 'hydration':
        return Icons.water_drop;
      case 'food':
      case 'meal':
        return Icons.restaurant;
      case 'workout':
      case 'activity':
        return Icons.directions_run;
      case 'sleep':
        return Icons.bedtime;
      case 'medication':
      case 'medicine':
        return Icons.medication;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'water':
      case 'hydration':
        return Colors.blue;
      case 'food':
      case 'meal':
        return Colors.green;
      case 'workout':
      case 'activity':
        return Colors.orange;
      case 'sleep':
        return Colors.pink;
      case 'medication':
        return Colors.red;
      default:
        return Theme.of(context).primaryColor;
    }
  }
}
