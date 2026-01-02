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
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: widget.initialStep);

    _nameController = TextEditingController(text: widget.initialName ?? '');
    _quantityController =
        TextEditingController(text: widget.initialQuantity ?? '');
    _unitController = TextEditingController(text: widget.initialUnit ?? 'ml');
    _selectedCategory = widget.initialCategory ?? 'Water';

    _scheduleType = widget.initialScheduleType ?? 'Daily';
    _startDate = widget.initialStartDate ?? DateTime.now();
    _endDate =
        widget.initialEndDate ?? DateTime.now().add(const Duration(days: 30));
    _isSmartReminder = widget.initialSmartReminder;

    // Initialize Time
    if (widget.initialTime != null) {
      // Expect "HH:mm" (24h) or "h:mm a"
      // Ideally we use TimeOfDay.fromDateTime or parse.
      // For this app, earlier logic suggested "HH:mm".
      // Let's assume consistent format "h:mm a" (e.g. 9:00 AM) or "HH:mm".
      // The `ReviewReminderStep` shows `time` as is.
      // `SetScheduleStep` uses `TimeOfDay`.
      // Let's try to parse assuming "h:mm a" standard Flutter `format(context)` output which is locale dependent,
      // OR simple "HH:mm".
      // If the repository saves "HH:mm", we parse that.
      // Let's check `ReminderBloc` _scheduleNotification, it splits by ':'. It assumes "HH:mm" (24h) likely?
      // Wait, `_selectedTime.format(context)` returns "9:00 AM". `TimeOfDay` holds 24h internal.
      // If we saved "9:00 AM", we need to parse that back.
      // To be safe, let's look at how it's saved.
      // `time: _selectedTime.format(context),` in `_saveReminder`.
      // So it saves localized string "9:00 AM" or "21:00".
      // This is risky to parse back.
      // BETTER FIX: The `AddReminderModal` should arguably accept `TimeOfDay` or rely on a standard format.
      // For now, I will try to parse robustly.

      // Parsing "9:00 AM" manually or "14:30"
      try {
        // If contains AM/PM
        if (widget.initialTime!.toLowerCase().contains('pm') ||
            widget.initialTime!.toLowerCase().contains('am')) {
          // Basic parse for "h:mm a"
          final timeParts = widget.initialTime!.split(' ');
          final hm = timeParts[0].split(':');
          int h = int.parse(hm[0]);
          final m = int.parse(hm[1]);
          if (timeParts[1].toLowerCase() == 'pm' && h != 12) h += 12;
          if (timeParts[1].toLowerCase() == 'am' && h == 12) h = 0;
          _selectedTime = TimeOfDay(hour: h, minute: m);
        } else {
          // Assume HH:mm
          final parts = widget.initialTime!.split(':');
          if (parts.length == 2) {
            _selectedTime = TimeOfDay(
                hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
        }
      } catch (e) {
        print("Error parsing time: $e");
        _selectedTime = const TimeOfDay(hour: 9, minute: 0);
      }
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
    final formattedTime =
        '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}';

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
          daysOfWeek: _scheduleType == 'Weekly' ? _daysOfWeek : null,
          dayOfMonth: _scheduleType == 'Monthly' ? _dayOfMonth : null,
          time: formattedTime,
          startDate: _startDate,
          endDate: _endDate,
          smartReminder: _isSmartReminder,
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
          daysOfWeek: _scheduleType == 'Weekly' ? _daysOfWeek : null,
          dayOfMonth: _scheduleType == 'Monthly' ? _dayOfMonth : null,
          time: formattedTime,
          startDate: _startDate,
          endDate: _endDate,
          smartReminder: _isSmartReminder,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height *
          0.68, // Reduced height to show date selector
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle bar
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
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
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
                  time: _selectedTime.format(context),
                  startDate: _startDate,
                  endDate: _endDate,
                  smartReminder: _isSmartReminder,
                  onConfirm: _saveReminder,
                  onBack: _prevStep,
                  onEditSchedule: () {
                    // Navigate back to Details step (index 0)
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
