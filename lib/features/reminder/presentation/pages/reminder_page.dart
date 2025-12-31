import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_state.dart';
import '../widgets/add_reminder_modal.dart';
import '../../../../../core/presentation/widgets/app_date_selector.dart';
import '../widgets/add_reminder_modal.dart';
import '../widgets/reminder_item_card.dart';
import '../widgets/primary_button.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  DateTime _selectedDate = DateTime.now();

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
            color: Color(0xFFEE374D), // Red title as per design
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFEE374D), size: 28),
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
                color: Color(0xFFEE374D), size: 26),
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
                  // TODO: Filter reminders by date
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
                          return ReminderItemCard(
                            title: reminder.name.isNotEmpty
                                ? reminder.name
                                : 'Reminder',
                            subtitle:
                                '${reminder.quantity} ${reminder.unit} / ${_getDurationText(reminder.scheduleType)}',
                            icon: _getIconForCategory(reminder.category),
                            color: _getColorForCategory(reminder.category),
                            onEdit: () {
                              final reminderBloc = context.read<ReminderBloc>();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => BlocProvider.value(
                                  value: reminderBloc,
                                  child: AddReminderModal(
                                    initialStep: 2, // Start at Review step
                                    initialName: reminder.name,
                                    initialCategory: reminder.category,
                                    initialQuantity: reminder.quantity,
                                    initialUnit: reminder.unit,
                                    initialScheduleType: reminder.scheduleType,
                                    initialStartDate: reminder.startDate,
                                    initialEndDate: reminder.endDate,
                                    initialSmartReminder:
                                        reminder.smartReminder,
                                  ),
                                ),
                              );
                            },
                          );
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
        return const Color(0xFFEE374D);
    }
  }

  String _getDurationText(String scheduleType) {
    switch (scheduleType.toLowerCase()) {
      case 'daily':
        return 'day';
      case 'weekly':
        return 'week';
      case 'monthly':
        return 'month';
      default:
        return 'day';
    }
  }
}
