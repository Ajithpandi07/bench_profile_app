import 'package:flutter/material.dart';
import 'steps/add_details_step.dart';
import 'steps/set_schedule_step.dart';
import 'steps/review_reminder_step.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';

class AddReminderModal extends StatefulWidget {
  const AddReminderModal({super.key});

  @override
  State<AddReminderModal> createState() => _AddReminderModalState();
}

class _AddReminderModalState extends State<AddReminderModal> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1: Details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  String _selectedCategory = 'Water';

  // Step 2: Schedule
  String _scheduleType = 'Daily';
  DateTime _startDate = DateTime.now();
  DateTime _endDate =
      DateTime.now().add(const Duration(days: 30)); // Default 1 month
  bool _isSmartReminder = false;

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
