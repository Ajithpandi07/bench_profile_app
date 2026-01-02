import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../primary_button.dart';
import '../modals/time_goal_modal.dart';
import '../../../../../core/services/app_theme.dart';

class SetScheduleStep extends StatelessWidget {
  final String scheduleType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isSmartReminder;
  final List<int> daysOfWeek;
  final int dayOfMonth;
  final TimeOfDay selectedTime;
  final String selectedGoal;
  final String selectedUnit;

  final ValueChanged<String> onTypeChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final ValueChanged<bool> onSmartToggle;
  final ValueChanged<List<int>> onDaysOfWeekChanged;
  final ValueChanged<int> onDayOfMonthChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<String> onGoalChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const SetScheduleStep({
    super.key,
    required this.scheduleType,
    required this.startDate,
    required this.endDate,
    required this.isSmartReminder,
    required this.daysOfWeek,
    required this.dayOfMonth,
    required this.selectedTime,
    required this.selectedGoal,
    required this.selectedUnit,
    required this.onTypeChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onSmartToggle,
    required this.onDaysOfWeekChanged,
    required this.onDayOfMonthChanged,
    required this.onTimeChanged,
    required this.onGoalChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Stack(
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
                const Center(
                  child: Text(
                    'Set Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Question
            Text(
              'How often do you want to track this activity?',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            // Frequency Selector (Segmented)
            Container(
              width: 340,
              height: 37,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(229, 231, 235, 0.3),
                borderRadius: BorderRadius.circular(18.5),
              ),
              child: Row(
                children: ['Daily', 'Weekly', 'Monthly', 'As needed']
                    .map((type) => Expanded(
                          child: GestureDetector(
                            onTap: () => onTypeChanged(type),
                            child: Container(
                              decoration: BoxDecoration(
                                color: scheduleType == type
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: scheduleType == type
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Selectors based on Type
            if (scheduleType == 'Weekly') ...[
              const Text(
                'Repeat on',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildWeekDaySelector(),
              const SizedBox(height: 24),
            ],

            if (scheduleType == 'Monthly') ...[
              const Text(
                'Repeat on',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildMonthDaySelector(),
              const SizedBox(height: 24),
            ],

            // Time & Goal Section
            const Text(
              'Time & Goal',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              width: 340,
              height: 144,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    selectedGoal.isNotEmpty
                        ? 'Remind me at ${selectedTime.format(context)} to take $selectedGoal $selectedUnit'
                        : 'Set this quantity and get reminders to take it at specific times.',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: PrimaryButton(
                        text: 'Set Time & Goal',
                        fontSize: 14,
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => TimeGoalModal(
                              initialTime: selectedTime,
                              initialGoal: selectedGoal,
                              unit: selectedUnit,
                              onTimeChanged: onTimeChanged,
                              onGoalChanged: onGoalChanged,
                              onConfirm: () {}, // State updated via callbacks
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Duration
            const Text(
              'Duration',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildDatePicker(
                    context, 'Start Date', startDate, onStartDateChanged),
                const SizedBox(height: 12),
                _buildDatePicker(
                    context, 'End Date', endDate, onEndDateChanged),
              ],
            ),

            const SizedBox(height: 24),

            // Reminder Setting
            const Text(
              'Reminder Setting',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              width: 340,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Enable Smart Reminder',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Switch(
                    value: isSmartReminder,
                    activeColor: AppTheme.primaryColor,
                    onChanged: onSmartToggle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: PrimaryButton(
                text: 'Next',
                fontSize: 14,
                padding: EdgeInsets.zero,
                onPressed: onNext,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDaySelector() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    // 1=Mon, ..., 7=Sun.
    // Index map: 0(S)->7, 1(M)->1, 2(T)->2, 3(W)->3, 4(T)->4, 5(F)->5, 6(S)->6
    final dayValues = [7, 1, 2, 3, 4, 5, 6];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayValue = dayValues[index];
        final isSelected = daysOfWeek.contains(dayValue);
        return GestureDetector(
          onTap: () {
            final newDays = List<int>.from(daysOfWeek);
            if (isSelected) {
              if (newDays.length > 1) newDays.remove(dayValue);
            } else {
              newDays.add(dayValue);
            }
            onDaysOfWeekChanged(newDays);
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              ),
            ),
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthDaySelector() {
    return Container(
      width: 340,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: dayOfMonth,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
          items: List.generate(31, (index) {
            final day = index + 1;
            return DropdownMenuItem(
              value: day,
              child: Text(
                'Day $day of every month',
                style: const TextStyle(fontSize: 14),
              ),
            );
          }),
          onChanged: (val) {
            if (val != null) onDayOfMonthChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String hint, DateTime date,
      ValueChanged<DateTime> onChanged) {
    return InkWell(
      onTap: () async {
        showCupertinoModalPopup<void>(
          context: context,
          builder: (BuildContext context) => Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: SafeArea(
              top: false,
              child: CupertinoDatePicker(
                initialDateTime: date,
                mode: CupertinoDatePickerMode.date,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newDate) {
                  onChanged(newDate);
                },
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 340,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '$hint: ', // Added hint prefix to match context
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Icon(Icons.calendar_today_outlined,
                size: 18, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
