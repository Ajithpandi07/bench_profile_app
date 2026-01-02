import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../reminder/presentation/widgets/primary_button.dart';
import '../../../../../core/services/app_theme.dart';

class TimeGoalModal extends StatefulWidget {
  final TimeOfDay? initialTime;
  final String? initialGoal;
  final String unit;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<String> onGoalChanged;
  final VoidCallback onConfirm;

  const TimeGoalModal({
    super.key,
    this.initialTime,
    this.initialGoal,
    required this.unit,
    required this.onTimeChanged,
    required this.onGoalChanged,
    required this.onConfirm,
  });

  @override
  State<TimeGoalModal> createState() => _TimeGoalModalState();
}

class _TimeGoalModalState extends State<TimeGoalModal> {
  late TimeOfDay _time;
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime ?? TimeOfDay.now();
    _goalController = TextEditingController(text: widget.initialGoal ?? '');
    _goalController.addListener(() {
      widget.onGoalChanged(_goalController.text);
    });
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _showTimePicker() {
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
            initialDateTime: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              _time.hour,
              _time.minute,
            ),
            mode: CupertinoDatePickerMode.time,
            use24hFormat: false,
            onDateTimeChanged: (DateTime newDate) {
              setState(() {
                _time = TimeOfDay.fromDateTime(newDate);
              });
              widget.onTimeChanged(_time);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Set Time & Goal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Time',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showTimePicker,
            child: Container(
              width: 340,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _time.format(context),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.access_time,
                      size: 20, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Goal',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            width: 340,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _goalController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter quantity',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: PrimaryButton(
              text: 'Save',
              fontSize: 14,
              padding: EdgeInsets.zero,
              onPressed: () {
                widget.onConfirm();
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 20),
          // Padding for keyboard
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
