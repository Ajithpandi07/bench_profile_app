import 'package:flutter/material.dart';
import '../primary_button.dart';
import '../../../../../core/services/app_theme.dart';

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
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewCard(),
                  const SizedBox(height: 24),
                  Center(
                    child: PrimaryButton(
                      text: 'Save',
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

  Widget _buildHeader() {
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
        const Text(
          'Review Reminder',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard() {
    return Column(
      children: [
        const SizedBox(height: 30),
        // Icon Circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              _getIconForCategory(category),
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Summary Text
        Text(
          name.isNotEmpty ? name : 'Reminder',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '$category, $quantity $unit${time != null ? ' at $time' : ''}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 30),

        // Schedule Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: onEditSchedule,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Edit',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.repeat, 'Frequency', _getScheduleSummary()),
              if (time != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.access_time, 'Time', time!),
              ],
              _buildDetailRow(Icons.calendar_today_outlined, 'Start Date',
                  '${startDate.day} ${_getMonth(startDate.month)} ${startDate.year}'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quantity Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quantity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Volume remaining ($unit)',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _getScheduleSummary() {
    switch (scheduleType) {
      case 'Daily':
        return 'Every day';
      case 'Weekly':
        if (daysOfWeek == null || daysOfWeek!.isEmpty) return 'Every week';
        final days = daysOfWeek!.map((d) {
          const map = {
            1: 'Mon',
            2: 'Tue',
            3: 'Wed',
            4: 'Thu',
            5: 'Fri',
            6: 'Sat',
            7: 'Sun'
          };
          return map[d] ?? '';
        }).join(', ');
        return 'Every week on $days';
      case 'Monthly':
        if (dayOfMonth == null) return 'Every month';
        return 'Every month on Day $dayOfMonth';
      case 'As needed':
        return 'As needed';
      default:
        return scheduleType;
    }
  }

  String _getMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
