import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/reminder_list_shimmer.dart';
import '../../domain/entities/reminder.dart';

import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_state.dart';
import '../bloc/reminder_event.dart';
import '../widgets/add_reminder_modal.dart';
import '../../../../../core/presentation/widgets/app_date_selector.dart';

import '../widgets/reminder_item_card.dart';

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
              size: 28,
            ),
            onPressed: () => _openAddModal(context),
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Theme.of(context).primaryColor,
              size: 26,
            ),
            onPressed: () {},
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

                      // 1. Separate Standard vs Custom
                      final standardReminders = reminders
                          .where((r) => r.isStandard)
                          .toList();
                      final customReminders = reminders
                          .where((r) => !r.isStandard)
                          .toList();

                      // 2. Group Standard Reminders
                      final meals = standardReminders
                          .where(
                            (r) =>
                                r.category.toLowerCase() == 'meal' ||
                                r.category.toLowerCase() == 'food',
                          )
                          .toList();
                      meals.sort((a, b) => _compareTime(a.time, b.time));

                      final activities = standardReminders
                          .where((r) => r.category.toLowerCase() == 'activity')
                          .toList();
                      activities.sort((a, b) => _compareTime(a.time, b.time));

                      final waters = standardReminders
                          .where((r) => r.category.toLowerCase() == 'hydration')
                          .toList();
                      waters.sort((a, b) => _compareTime(a.time, b.time));

                      final sleep = standardReminders
                          .where((r) => r.category.toLowerCase() == 'sleep')
                          .toList();

                      // 3. Find Upcoming Meal
                      final now = DateTime.now(); // Or generic 'now' logic
                      // Note: 'reminders' are already filtered by _selectedDate in Bloc for skipped dates?
                      // Wait, standard reminders exist every day, but Bloc filters based on 'skippedDates'.
                      // If it's in 'state.reminders', it's active for this day.

                      // We want upcoming time relative to Now for TODAY.
                      // If seeing future date, 'upcoming' conceptually means 'first one'?
                      // Let's stick to "Least upcoming time" meaning "Next closest time"
                      // If selectedDate != today, maybe just show the first one?
                      Reminder? upcomingMeal;
                      if (_selectedDate.day == now.day &&
                          _selectedDate.month == now.month &&
                          _selectedDate.year == now.year) {
                        // Find first meal after current time
                        final currentTimeVal = now.hour * 60 + now.minute;
                        for (final m in meals) {
                          if (m.time == null) continue;
                          final t = _parseTime(m.time!);
                          if (t > currentTimeVal) {
                            upcomingMeal = m;
                            break;
                          }
                        }
                        // If no meal left today, maybe show Breakfast for tomorrow? Or null?
                        // Showing null is safer.
                      } else {
                        // Future/Past date: Show the first meal of the day
                        if (meals.isNotEmpty) upcomingMeal = meals.first;
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          if (upcomingMeal != null) ...[
                            Text(
                              'Upcoming Meal',
                              style: TextStyle(
                                fontSize: 16, // Smaller than 18
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildStandardReminderCard(
                              context,
                              upcomingMeal,
                              isUpcoming: true,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Meals List
                          _buildSectionHeader(context, 'Meals'),
                          ...meals.map(
                            (r) => _buildStandardReminderCard(context, r),
                          ),
                          const SizedBox(height: 24),

                          // Activity List
                          _buildSectionHeader(context, 'Activity'),
                          ...activities.map(
                            (r) => _buildStandardReminderCard(context, r),
                          ),
                          const SizedBox(height: 24),

                          // Water List
                          _buildSectionHeader(context, 'Water'),
                          // Water might have many items. Grid or List?
                          // User said "water reminder for every 2 hrs". List is fine but long.
                          // Let's use a Wrap or just list items. List is standard.
                          ...waters.map(
                            (r) => _buildStandardReminderCard(context, r),
                          ),
                          const SizedBox(height: 24),

                          // Sleep List
                          if (sleep.isNotEmpty) ...[
                            _buildSectionHeader(context, 'Sleep'),
                            ...sleep.map(
                              (r) => _buildStandardReminderCard(context, r),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Custom List
                          if (customReminders.isNotEmpty) ...[
                            _buildSectionHeader(context, 'My Reminders'),
                            ...customReminders.map(
                              (r) => _buildCustomReminderCard(context, r),
                            ),
                            const SizedBox(height: 24),
                          ],
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

  int _compareTime(String? t1, String? t2) {
    if (t1 == null) return -1;
    if (t2 == null) return 1;
    return _parseTime(t1).compareTo(_parseTime(t2));
  }

  int _parseTime(String t) {
    final firstTime = t.split(',').first.trim();
    final parts = firstTime.split(':');
    if (parts.length != 2) return 0;
    try {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
    );
  }

  void _openAddModal(
    BuildContext context, {
    String? category,
    Reminder? reminder,
  }) {
    final reminderBloc = context.read<ReminderBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: reminderBloc,
        child: AddReminderModal(
          initialCategory: category ?? reminder?.category ?? 'Custom',
          reminderId: reminder?.id,
          initialName: reminder?.name,
          initialQuantity: reminder?.quantity,
          initialUnit: reminder?.unit,
          initialScheduleType: reminder?.scheduleType,
          initialStartDate: reminder?.startDate,
          initialEndDate: reminder?.endDate,
          initialTime: reminder?.time,
          initialSmartReminder: reminder?.smartReminder ?? false,
          initialInterval: reminder?.interval,
          initialCustomFrequency: reminder?.customFrequency,
          initialRecurrenceEndType: reminder?.recurrenceEndType,
          initialRecurrenceCount: reminder?.recurrenceCount,
        ),
      ),
    );
  }

  Widget _buildStandardReminderCard(
    BuildContext context,
    Reminder reminder, {
    bool isUpcoming = false,
  }) {
    // Check if skipped
    // Note: 'state.reminders' returns ONLY enabled reminders if we filter inside Bloc by skipped dates?
    // Let's check Bloc logic:
    // Bloc filters: if (selectedDate.isBefore(start) || selectedDate.isAfter(end)) return false;
    // Bloc logic for ToggleReminderForDate ADDS/REMOVES from 'skippedDates'.
    // BUT the Bloc logic currently DOES NOT filter out skipped dates from the emitted list?
    // Let's re-read Bloc: "Skipped dates handled by UI" line 60.
    // So we MUST check skipped dates here.

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ReminderItemCard(
        title: reminder.name,
        subtitle: isUpcoming
            ? 'Next scheduled meal'
            : '${reminder.quantity} ${reminder.unit}',
        scheduleType: 'Daily',
        time: reminder.time,
        icon: _getIconForCategory(reminder.category),
        color: _getColorForCategory(reminder.category),
        isEnabled: isEnabled,
        onToggle: (val) {
          _toggleReminder(context, reminder, val);
        },
      ),
    );
  }

  Widget _buildCustomReminderCard(BuildContext context, Reminder reminder) {
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ReminderItemCard(
        title: reminder.category.isEmpty
            ? 'Custom Reminder'
            : reminder.category,
        subtitle: reminder.name,
        scheduleType: reminder.scheduleType,
        time: reminder.time,
        icon: _getIconForCategory(reminder.category),
        color: _getColorForCategory(reminder.category),
        isEnabled: isEnabled,
        onTap: () => _openAddModal(context, reminder: reminder),
        onToggle: (val) {
          _toggleReminder(context, reminder, val);
        },
      ),
    );
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
        return Colors.deepPurple; // Changed from pink to deepPurple for sleep
      case 'medication':
        return Colors.red;
      default:
        return Theme.of(context).primaryColor;
    }
  }
}
