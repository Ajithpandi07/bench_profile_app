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
import '../../../../core/services/app_theme.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Reminder',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor, size: 28),
            onPressed: () => _openAddModal(context),
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
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
              const SizedBox(height: 24),
              // Reminders List
              Expanded(
                child: BlocBuilder<ReminderBloc, ReminderState>(
                  builder: (context, state) {
                    if (state is ReminderLoading) {
                      return const ReminderListShimmer();
                    } else if (state is ReminderLoaded) {
                      final reminders = state.reminders;

                      // 1. Identify Standard Reminders
                      final waterReminder = _findReminder(reminders, ['water']);
                      final foodReminder = _findReminder(reminders, [
                        'food',
                        'meal',
                      ]);
                      final activityReminder = _findReminder(reminders, [
                        'activity',
                        'workout',
                      ]);
                      final sleepReminder = _findReminder(reminders, ['sleep']);

                      // 2. Identify Custom Reminders (exclude used standard ones)
                      final usedIds = {
                        waterReminder?.id,
                        foodReminder?.id,
                        activityReminder?.id,
                        sleepReminder?.id,
                      };
                      final customReminders = reminders
                          .where(
                            (r) => !usedIds.contains(r.id) && r.id.isNotEmpty,
                          )
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _buildCategoryCard(
                            context,
                            'Water Reminder',
                            'Drink Water',
                            'Every 2 Hrs',
                            'Water',
                            waterReminder,
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryCard(
                            context,
                            'Food Reminder',
                            'Take Your Food',
                            'Breakfast',
                            'Food',
                            foodReminder,
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryCard(
                            context,
                            'Activity Reminder',
                            'Time to Move',
                            'Cycling',
                            'Workout',
                            activityReminder,
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryCard(
                            context,
                            'Sleep Reminder',
                            'Time to Sleep',
                            '10:30 PM',
                            'Sleep',
                            sleepReminder,
                          ),

                          if (customReminders.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Other Reminders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1617),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...customReminders.map(
                              (reminder) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildCustomReminderCard(
                                  context,
                                  reminder,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
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

  void _openAddModal(BuildContext context, {String? category}) {
    final reminderBloc = context.read<ReminderBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: reminderBloc,
        // If adding via FAB (category null), default to 'Custom'.
        // If adding via Toggle (category provided), use it.
        child: AddReminderModal(initialCategory: category ?? 'Custom'),
      ),
    );
  }

  Reminder? _findReminder(List<dynamic> reminders, List<String> categories) {
    try {
      return reminders.firstWhere((r) {
        final cat = r.category.toLowerCase();
        return categories.contains(cat);
      });
    } catch (e) {
      return null;
    }
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String subtitle,
    String defaultDetail,
    String apiCategoryCategory,
    Reminder? reminder, // Pass the specific reminder if found
  ) {
    // Check if skipped for today
    bool isSkipped = false;
    if (reminder != null && reminder.skippedDates != null) {
      isSkipped = reminder.skippedDates!.any(
        (d) =>
            d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day,
      );
    }

    final isEnabled = reminder != null && !isSkipped;

    // Construct display values
    String displaySubtitle = subtitle;
    String? timeDisplay;
    String scheduleTypeDisplay = defaultDetail;

    if (isEnabled && reminder != null) {
      if (reminder.name.isNotEmpty) displaySubtitle = reminder.name;
      scheduleTypeDisplay = reminder.scheduleType;

      // Formatting time/interval logic
      if (reminder.scheduleType == 'Specific Time') {
        timeDisplay = reminder.time;
      } else if (reminder.scheduleType == 'Interval' &&
          reminder.interval != null) {
        timeDisplay = 'Every ${reminder.interval} mins'; // Simple fallback
        if (reminder.customFrequency != null) {
          timeDisplay =
              'Every ${reminder.interval} ${reminder.customFrequency}';
        }
      } else {
        timeDisplay = reminder.time;
      }
    }

    return ReminderItemCard(
      title: title,
      subtitle: displaySubtitle,
      scheduleType: scheduleTypeDisplay,
      time: timeDisplay ?? (isEnabled && reminder != null ? reminder.time : ''),
      icon: _getIconForCategory(apiCategoryCategory),
      color: _getColorForCategory(apiCategoryCategory),
      isEnabled: isEnabled,
      onToggle: (val) {
        if (val) {
          // Turning ON
          if (reminder == null) {
            // No reminder exists, create new
            _openAddModal(context, category: apiCategoryCategory);
          } else {
            // Reminder exists but was skipped, unskip it
            context.read<ReminderBloc>().add(
              ToggleReminderForDate(
                reminder: reminder,
                date: _selectedDate,
                isEnabled: true,
              ),
            );
          }
        } else {
          // Turning OFF
          if (reminder != null) {
            // Skip for today instead of delete
            context.read<ReminderBloc>().add(
              ToggleReminderForDate(
                reminder: reminder,
                date: _selectedDate,
                isEnabled: false,
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildCustomReminderCard(BuildContext context, Reminder reminder) {
    // Check if skipped
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

    return ReminderItemCard(
      title: reminder.category.isEmpty ? 'Custom Reminder' : reminder.category,
      subtitle: reminder.name,
      scheduleType: reminder.scheduleType,
      time: reminder.time,
      icon: _getIconForCategory(reminder.category),
      color: _getColorForCategory(reminder.category),
      isEnabled: isEnabled,
      onToggle: (val) {
        if (val) {
          // Unskip
          context.read<ReminderBloc>().add(
            ToggleReminderForDate(
              reminder: reminder,
              date: _selectedDate,
              isEnabled: true,
            ),
          );
        } else {
          // Skip
          context.read<ReminderBloc>().add(
            ToggleReminderForDate(
              reminder: reminder,
              date: _selectedDate,
              isEnabled: false,
            ),
          );
        }
      },
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'water':
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
        return Colors.blue;
      case 'food':
      case 'meal':
        return Colors.green;
      case 'workout':
      case 'activity':
        return Colors.orange;
      case 'sleep':
        return Colors.pinkAccent;
      case 'medication':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }
}
