import 'package:flutter/material.dart';
import 'steps/add_details_step.dart';
import 'steps/set_schedule_step.dart';
import 'steps/review_reminder_step.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';

class AddReminderModal extends StatefulWidget {
  final int initialStep;
  final String? reminderId; // Add this
  final String? initialName;
  final String? initialCategory;
  final String? initialQuantity;
  final String? initialUnit;
  final String? initialScheduleType;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialTime; // Add this
  final bool initialSmartReminder;

  const AddReminderModal({
    super.key,
    this.initialStep = 0,
    this.reminderId, // Add this
    this.initialName,
    this.initialCategory,
    this.initialQuantity,
    this.initialUnit,
    this.initialScheduleType,
    this.initialStartDate,
    this.initialEndDate,
    this.initialTime, // Add this
    this.initialSmartReminder = false,
  });

  @override
  State<AddReminderModal> createState() => _AddReminderModalState();
}

class _AddReminderModalState extends State<AddReminderModal> {
  late int _currentStep;
  late PageController _pageController;

  // Step 1: Details
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late String _selectedCategory;

  // Step 2: Schedule
  late String _scheduleType;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isSmartReminder;
  List<int> _daysOfWeek = [];
  int _dayOfMonth = 1;
  TimeOfDay? _selectedTime;

  // Custom Fields
  int _interval = 1;
  String _customFrequency = 'Weeks'; // Weekly, Monthly
  String _recurrenceEndType = 'Forever'; // Forever, Until, Count
  int _recurrenceCount = 1;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: widget.initialStep);

    _nameController = TextEditingController(text: widget.initialName ?? '');
    _quantityController = TextEditingController(
      text: widget.initialQuantity ?? '',
    );
    _unitController = TextEditingController(text: widget.initialUnit ?? '');
    _selectedCategory = widget.initialCategory ?? 'Water';

    _scheduleType = widget.initialScheduleType ?? 'Daily';
    _startDate = widget.initialStartDate ?? DateTime.now();
    _endDate =
        widget.initialEndDate ?? DateTime.now().add(const Duration(days: 30));
    _isSmartReminder = widget.initialSmartReminder;

    // Initialize Time
    if (widget.initialTime != null) {
      try {
        if (widget.initialTime!.toLowerCase().contains('pm') ||
            widget.initialTime!.toLowerCase().contains('am')) {
          final timeParts = widget.initialTime!.split(' ');
          final hm = timeParts[0].split(':');
          int h = int.parse(hm[0]);
          final m = int.parse(hm[1]);
          if (timeParts[1].toLowerCase() == 'pm' && h != 12) h += 12;
          if (timeParts[1].toLowerCase() == 'am' && h == 12) h = 0;
          _selectedTime = TimeOfDay(hour: h, minute: m);
        } else {
          final parts = widget.initialTime!.split(':');
          if (parts.length == 2) {
            _selectedTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        }
      } catch (e) {
        print("Error parsing time: $e");
        _selectedTime = null;
      }
    } else {
      _selectedTime = null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 1 && _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set a time and goal')),
        );
        return;
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _saveReminder() {
    final formattedTime = _selectedTime != null
        ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '';

    // Logic to determine recurrence parameters based on scheduleType
    // If Custom, use custom values. If Standard (Daily/Weekly/Monthly), map if needed or leave null.
    // For simplicity, we pass custom values if type is Custom.
    final bool isCustom = _scheduleType == 'Custom';

    final bloc = context.read<ReminderBloc>();
    if (widget.reminderId != null) {
      bloc.add(
        UpdateReminder(
          id: widget.reminderId!,
          name: _nameController.text,
          category: _selectedCategory,
          quantity: _quantityController.text,
          unit: _unitController.text,
          scheduleType: _scheduleType,
          daysOfWeek:
              (_scheduleType == 'Weekly' ||
                  (isCustom && _customFrequency == 'Weeks'))
              ? _daysOfWeek
              : null,
          dayOfMonth:
              (_scheduleType == 'Monthly' ||
                  (isCustom && _customFrequency == 'Months'))
              ? _dayOfMonth
              : null,
          time: formattedTime,
          startDate: _startDate,
          endDate: _endDate,
          smartReminder: _isSmartReminder,
          interval: isCustom ? _interval : null,
          customFrequency: isCustom ? _customFrequency : null,
          recurrenceEndType: isCustom ? _recurrenceEndType : null,
          recurrenceCount: isCustom ? _recurrenceCount : null,
        ),
      );
    } else {
      bloc.add(
        AddReminder(
          name: _nameController.text,
          category: _selectedCategory,
          quantity: _quantityController.text,
          unit: _unitController.text,
          scheduleType: _scheduleType,
          daysOfWeek:
              (_scheduleType == 'Weekly' ||
                  (isCustom && _customFrequency == 'Weeks'))
              ? _daysOfWeek
              : null,
          dayOfMonth:
              (_scheduleType == 'Monthly' ||
                  (isCustom && _customFrequency == 'Months'))
              ? _dayOfMonth
              : null,
          time: formattedTime,
          startDate: _startDate,
          endDate: _endDate,
          smartReminder: _isSmartReminder,
          interval: isCustom ? _interval : null,
          customFrequency: isCustom ? _customFrequency : null,
          recurrenceEndType: isCustom ? _recurrenceEndType : null,
          recurrenceCount: isCustom ? _recurrenceCount : null,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AddDetailsStep(
                  nameController: _nameController,
                  quantityController: _quantityController,
                  unitController: _unitController,
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (val) =>
                      setState(() => _selectedCategory = val),
                  onNext: _nextStep,
                ),
                SetScheduleStep(
                  scheduleType: _scheduleType,
                  daysOfWeek: _daysOfWeek,
                  dayOfMonth: _dayOfMonth,
                  selectedTime: _selectedTime,
                  selectedGoal: _quantityController.text,
                  selectedUnit: _unitController.text,
                  startDate: _startDate,
                  endDate: _endDate,
                  isSmartReminder: _isSmartReminder,

                  // Custom Fields
                  interval: _interval,
                  customFrequency: _customFrequency,
                  recurrenceEndType: _recurrenceEndType,
                  recurrenceCount: _recurrenceCount,

                  onTypeChanged: (val) => setState(() => _scheduleType = val),
                  onDaysOfWeekChanged: (val) =>
                      setState(() => _daysOfWeek = val),
                  onDayOfMonthChanged: (val) =>
                      setState(() => _dayOfMonth = val),
                  onTimeChanged: (val) => setState(() => _selectedTime = val),
                  onGoalChanged: (val) =>
                      setState(() => _quantityController.text = val),
                  onStartDateChanged: (val) => setState(() => _startDate = val),
                  onEndDateChanged: (val) => setState(() => _endDate = val),
                  onSmartToggle: (val) =>
                      setState(() => _isSmartReminder = val),

                  onIntervalChanged: (val) => setState(() => _interval = val),
                  onCustomFrequencyChanged: (val) =>
                      setState(() => _customFrequency = val),
                  onRecurrenceEndTypeChanged: (val) =>
                      setState(() => _recurrenceEndType = val),
                  onRecurrenceCountChanged: (val) =>
                      setState(() => _recurrenceCount = val),

                  onNext: _nextStep,
                  onBack: _prevStep,
                ),
                ReviewReminderStep(
                  name: _nameController.text,
                  category: _selectedCategory,
                  quantity: _quantityController.text,
                  unit: _unitController.text,
                  scheduleType: _scheduleType,
                  daysOfWeek: _daysOfWeek,
                  dayOfMonth: _dayOfMonth,
                  time: _selectedTime?.format(context),
                  startDate: _startDate,
                  endDate: _endDate,
                  smartReminder: _isSmartReminder,
                  onConfirm: _saveReminder,
                  onBack: _prevStep,
                  onEditSchedule: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _currentStep = 0);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
