import 'package:flutter/material.dart';
import 'steps/add_details_step.dart';
import 'steps/set_schedule_step.dart';
import 'steps/review_reminder_step.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';

class AddReminderModal extends StatefulWidget {
  final int initialStep;
  final String? initialName;
  final String? initialCategory;
  final String? initialQuantity;
  final String? initialUnit;
  final String? initialScheduleType;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool initialSmartReminder;

  const AddReminderModal({
    super.key,
    this.initialStep = 0,
    this.initialName,
    this.initialCategory,
    this.initialQuantity,
    this.initialUnit,
    this.initialScheduleType,
    this.initialStartDate,
    this.initialEndDate,
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
    context.read<ReminderBloc>().add(
          AddReminder(
            name: _nameController.text,
            category: _selectedCategory,
            quantity: _quantityController.text,
            unit: _unitController.text,
            scheduleType: _scheduleType,
            startDate: _startDate,
            endDate: _endDate,
            smartReminder: _isSmartReminder,
          ),
        );
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
                  startDate: _startDate,
                  endDate: _endDate,
                  isSmartReminder: _isSmartReminder,
                  onTypeChanged: (val) => setState(() => _scheduleType = val),
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
                  startDate: _startDate,
                  endDate: _endDate,
                  smartReminder: _isSmartReminder,
                  onConfirm: _saveReminder,
                  onBack: _prevStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
