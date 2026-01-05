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
  final TimeOfDay? selectedTime;
  final String selectedGoal;
  final String selectedUnit;

  // Custom Fields
  final int interval;
  final String customFrequency;
  final String recurrenceEndType;
  final int recurrenceCount;

  final ValueChanged<String> onTypeChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final ValueChanged<bool> onSmartToggle;
  final ValueChanged<List<int>> onDaysOfWeekChanged;
  final ValueChanged<int> onDayOfMonthChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<String> onGoalChanged;

  // Custom Callbacks
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<String> onCustomFrequencyChanged;
  final ValueChanged<String> onRecurrenceEndTypeChanged;
  final ValueChanged<int> onRecurrenceCountChanged;

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
    this.interval = 1,
    this.customFrequency = 'Weeks',
    this.recurrenceEndType = 'Forever',
    this.recurrenceCount = 1,
    required this.onTypeChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onSmartToggle,
    required this.onDaysOfWeekChanged,
    required this.onDayOfMonthChanged,
    required this.onTimeChanged,
    required this.onGoalChanged,
    required this.onIntervalChanged,
    required this.onCustomFrequencyChanged,
    required this.onRecurrenceEndTypeChanged,
    required this.onRecurrenceCountChanged,
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
              width: double.infinity,
              height: 37,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(229, 231, 235, 0.3),
                borderRadius: BorderRadius.circular(18.5),
              ),
              child: Row(
                children: ['Daily', 'Weekly', 'Monthly', 'Custom']
                    .map(
                      (type) => Expanded(
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
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Selectors based on Type
            if (scheduleType == 'Custom') ...[
              _buildCustomScheduleOptions(context),
            ] else ...[
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
            ],

            // Show simplified Duration & Time/Goal if not custom, OR if custom handles its own duration
            if (scheduleType != 'Custom') ...[
              // Time & Goal Section
              const Text(
                'Time', // Changed from Time & Goal
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildTimeGoalCard(context),
              const SizedBox(height: 24),

              // Duration (Simplified to Repeat Until)
              const Text(
                'Repeat Until',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildDatePicker(
                context,
                'Select Date',
                endDate,
                onEndDateChanged,
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Custom view includes duration options inline? Or below?
              // Based on design:
              // Frequency (Dropdown)
              // Every [X] [Unit](s)
              // Weekday bubbles (if weekly)
              // Repeats summary text?

              // Logic to show "Recurs every X weeks on Mondays"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20), // Pill shape
                ),
                child: Center(
                  child: Text(
                    _getRecurrenceSummary(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Custom Duration Section
              const Text(
                'Duration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                'When to end report',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildCustomDurationOptions(context),

              const SizedBox(height: 24),
              const Text(
                'Time', // Changed from Time & Goal
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildTimeGoalCard(context),
              const SizedBox(height: 24),
            ],

            // Reminder Setting - REMOVED
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

  Widget _buildCustomScheduleOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frequency Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequency',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Base unit of time',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: customFrequency, // 'Weekly', 'Daily', 'Monthly'
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.red,
                    ),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    items: ['Daily', 'Weekly', 'Monthly'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value == 'Weekly'
                            ? 'Weeks'
                            : (value == 'Monthly'
                                  ? 'Months'
                                  : 'Days'), // Normalize to plural unit
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onCustomFrequencyChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Interval Selector (Every X)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Every', style: TextStyle(color: Colors.grey)),
                Container(
                  width: 60,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: TextEditingController(text: interval.toString())
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: interval.toString().length),
                      ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      final i = int.tryParse(val);
                      if (i != null && i > 0) onIntervalChanged(i);
                    },
                  ),
                ),
                Text(
                  '${customFrequency == 'Weeks' ? 'Week(s)' : (customFrequency == 'Months' ? 'Month(s)' : 'Day(s)')}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Weekday selector if Frequency is Weeks
          if (customFrequency == 'Weeks') ...[
            _buildWeekDaySelector(
              isSmall: true,
            ), // Pass flag to use smaller bubbles
          ],
          if (customFrequency == 'Months') ...[_buildMonthDaySelector()],
        ],
      ),
    );
  }

  String _getRecurrenceSummary() {
    String unit = customFrequency == 'Weeks'
        ? 'weeks'
        : (customFrequency == 'Months' ? 'months' : 'days');
    String summary = 'This reminder repeats every $interval $unit';
    if (customFrequency == 'Weeks' && daysOfWeek.isNotEmpty) {
      summary += ' on ${_getDaysString()}';
    }
    return '$summary.';
  }

  String _getDaysString() {
    // Map daysOfWeek to names
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    // 1=Mon
    if (daysOfWeek.length == 7) return 'every day';
    return daysOfWeek.map((d) => days[d - 1].substring(0, 3)).join(', ');
  }

  Widget _buildCustomDurationOptions(BuildContext context) {
    return Column(
      children: [
        _buildDurationOption(
          title: 'Forever',
          isSelected: recurrenceEndType == 'Forever',
          onTap: () => onRecurrenceEndTypeChanged('Forever'),
        ),
        _buildDurationOption(
          title: 'Until',
          isSelected: recurrenceEndType == 'Until',
          onTap: () => onRecurrenceEndTypeChanged('Until'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${endDate.year}-${endDate.month}-${endDate.day}',
              style: const TextStyle(fontSize: 12),
            ),
            // Simplified date display, wire up picker if needed
          ),
          onChildTap: () async {
            // Show date picker
            // Reuse existing date picker logic but for endDate specifically
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
                    initialDateTime: endDate,
                    mode: CupertinoDatePickerMode.date,
                    use24hFormat: true,
                    onDateTimeChanged: (DateTime newDate) {
                      onEndDateChanged(newDate);
                    },
                  ),
                ),
              ),
            );
          },
        ),
        _buildDurationOption(
          title: 'Specific number of times',
          isSelected: recurrenceEndType == 'Count',
          onTap: () => onRecurrenceEndTypeChanged('Count'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller:
                      TextEditingController(text: recurrenceCount.toString())
                        ..selection = TextSelection.fromPosition(
                          TextPosition(
                            offset: recurrenceCount.toString().length,
                          ),
                        ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final i = int.tryParse(val);
                    if (i != null && i > 0) onRecurrenceCountChanged(i);
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Occurrences',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? child,
    VoidCallback? onChildTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                if (child != null && isSelected) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap:
                        onChildTap, // Intercept tap specifically for the child control
                    child: child,
                  ),
                ],
              ],
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: isSelected ? 5 : 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Time & Goal Section
  // This section was previously a method _buildTimeGoalCard, now inlined and modified.
  Widget _buildTimeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time', // Changed from Time & Goal
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _buildTimeGoalCard(context),
      ],
    );
  }

  Widget _buildTimeGoalCard(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 144),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: (selectedGoal.isNotEmpty && selectedTime != null)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Remind me at ${selectedTime!.format(context)} to take $selectedGoal $selectedUnit',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: PrimaryButton(
                      text: 'Edit Time',
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
                            showGoal: false,
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
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set this quantity and get reminders to take it at specific times.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: PrimaryButton(
                      text: 'Set Time',
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
                            showGoal: false,
                            onTimeChanged: onTimeChanged,
                            onGoalChanged: onGoalChanged,
                            onConfirm: () {},
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWeekDaySelector({bool isSmall = false}) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    // 1=Mon, ..., 7=Sun.
    // Index map: 0(S)->7, 1(M)->1, 2(T)->2, 3(W)->3, 4(T)->4, 5(F)->5, 6(S)->6
    final dayValues = [7, 1, 2, 3, 4, 5, 6];

    final size = isSmall ? 32.0 : 40.0;
    final fontSize = isSmall ? 10.0 : 12.0;

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
            width: size,
            height: size,
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
                fontSize: fontSize,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthDaySelector() {
    return Container(
      width: double.infinity,
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

  Widget _buildDatePicker(
    BuildContext context,
    String hint,
    DateTime date,
    ValueChanged<DateTime> onChanged,
  ) {
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
        width: double.infinity,
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
