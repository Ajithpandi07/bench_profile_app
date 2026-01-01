import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_state.dart';
import '../bloc/reminder_event.dart';
import '../widgets/add_reminder_modal.dart';
import '../../../../../core/presentation/widgets/app_date_selector.dart';

import '../widgets/reminder_item_card.dart';
import '../widgets/primary_button.dart';
import '../../../../core/services/app_theme.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context
        .read<ReminderBloc>()
        .add(LoadReminders(selectedDate: _selectedDate));
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
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Reminder',
          style: TextStyle(
            color: AppTheme.primaryColor, // Red title as per design
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor, size: 28),
            onPressed: () {
              final reminderBloc = context.read<ReminderBloc>();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => BlocProvider.value(
                  value: reminderBloc,
                  child: const AddReminderModal(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline,
                color: AppTheme.primaryColor, size: 26),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                  context
                      .read<ReminderBloc>()
                      .add(LoadReminders(selectedDate: date));
                },
              ),
              const SizedBox(height: 5),
              // Reminders List
              Expanded(
                child: BlocBuilder<ReminderBloc, ReminderState>(
                  builder: (context, state) {
                    if (state is ReminderLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ReminderLoaded) {
                      if (state.reminders.isEmpty) {
                        return const Center(
                          child: Text(
                            'No reminders for today',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: state.reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = state.reminders[index];
                          return Dismissible(
                              key: Key(reminder.id), // Removed !
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      title: const Text("Delete Reminder",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      content: const Text(
                                          "Are you sure you want to delete this reminder?"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text("Cancel",
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text("Delete",
                                              style: TextStyle(
                                                  color:
                                                      AppTheme.primaryColor)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.white, size: 28),
                              ),
                              onDismissed: (direction) {
                                context.read<ReminderBloc>().add(
                                    DeleteReminder(reminder.id)); // Removed !
                              },
                              child: ReminderItemCard(
                                title: reminder.name.isNotEmpty
                                    ? reminder.name
                                    : 'Reminder',
                                subtitle:
                                    '${reminder.quantity} ${reminder.unit}',
                                scheduleType: reminder.scheduleType,
                                icon: _getIconForCategory(reminder.category),
                                color: _getColorForCategory(reminder.category),
                                onEdit: () {
                                  final reminderBloc =
                                      context.read<ReminderBloc>();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => BlocProvider.value(
                                      value: reminderBloc,
                                      child: AddReminderModal(
                                        initialStep: 2, // Start at Review step
                                        reminderId: reminder.id,
                                        initialName: reminder.name,
                                        initialCategory: reminder.category,
                                        initialQuantity: reminder.quantity,
                                        initialUnit: reminder.unit,
                                        initialScheduleType:
                                            reminder.scheduleType,
                                        initialStartDate: reminder.startDate,
                                        initialEndDate: reminder.endDate,
                                        initialSmartReminder:
                                            reminder.smartReminder,
                                      ),
                                    ),
                                  );
                                },
                              ));
                        },
                      );
                    } else if (state is ReminderError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox();
                  },
                ),
              ),
              // Add Reminder Button (Bottom)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 16),
                child: Center(
                  child: PrimaryButton(
                    text: 'Add Reminder',
                    width: 306,
                    height: 32,
                    borderRadius: 5,
                    fontSize: 14,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final reminderBloc = context.read<ReminderBloc>();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => BlocProvider.value(
                          value: reminderBloc,
                          child: const AddReminderModal(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'water':
        return Icons.water_drop;
      case 'food':
        return Icons.restaurant;
      case 'workout':
      case 'activity':
        return Icons.directions_run;
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
        return Colors.green;
      case 'workout':
      case 'activity':
        return Colors.orange;
      case 'medication':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }
}
