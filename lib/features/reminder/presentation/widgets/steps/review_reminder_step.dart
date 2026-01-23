import 'package:flutter/material.dart';
import '../primary_button.dart';
import '../reminder_item_card.dart';

class ReviewReminderStep extends StatelessWidget {
  final String name;
  final String category;
  final String quantity;
  final String unit;
  final String scheduleType;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final String? time;
  final DateTime startDate;
  final DateTime endDate;
  final bool smartReminder;
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  final VoidCallback onEditSchedule;

  const ReviewReminderStep({
    super.key,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.scheduleType,
    this.daysOfWeek,
    this.dayOfMonth,
    this.time,
    required this.startDate,
    required this.endDate,
    required this.smartReminder,
    required this.onConfirm,
    required this.onBack,
    required this.onEditSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewCard(context),
                  const SizedBox(height: 32),
                  Center(
                    child: PrimaryButton(
                      text: 'Add Reminder',
                      fontSize: 14,
                      padding: EdgeInsets.zero,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        Text(
          'Review Reminder',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    String cardTitle = '$category Reminder';
    String actionSubtitle = name.isNotEmpty ? name : 'Time to Move';
    if (category.toLowerCase() == 'water') {
      actionSubtitle = 'Drink Water';
    }
    if (category.toLowerCase() == 'sleep') {
      actionSubtitle = 'Time to Sleep';
    }
    if (category.toLowerCase() == 'food' || category.toLowerCase() == 'meal') {
      actionSubtitle = 'Take Your Food';
    }

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF007AFF), // Mockup blue border
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ReminderItemCard(
              title: cardTitle,
              subtitle: actionSubtitle,
              detail1: time,
              icon: _getIconForCategory(category),
              color: _getColorForCategory(category),
              isEnabled: true,
              onToggle: (val) {},
            ),
          ),
        ],
      ),
    );
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
      default:
        return const Color(0xFFFF5252);
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'water':
        return Icons.water_drop;
      case 'activity':
      case 'workout':
        return Icons.directions_run;
      case 'medicine':
        return Icons.medication;
      default:
        return Icons.notifications;
    }
  }
}
