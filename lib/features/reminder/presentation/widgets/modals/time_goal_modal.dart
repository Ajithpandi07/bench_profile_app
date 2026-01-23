import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../reminder/presentation/widgets/primary_button.dart';
import '../../../../../core/services/app_theme.dart';

class TimeGoalModal extends StatefulWidget {
  final TimeOfDay? initialTime;
  final String? initialGoal;
  final String unit;
  final bool showGoal;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<String> onGoalChanged;
  final VoidCallback onConfirm;

  const TimeGoalModal({
    super.key,
    this.initialTime,
    this.initialGoal,
    required this.unit,
    this.showGoal = true,
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

    // Ensure initial values are sent back immediately
    widget.onTimeChanged(_time);

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
          Center(
            child: Text(
              widget.showGoal ? 'Set Time & Goal' : 'Set Time',
              style: const TextStyle(
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
          Center(
            child: GestureDetector(
              onTap: _showTimePicker,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Today',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _time.format(context).split(' ')[0], // hh:mm part
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _time.period == DayPeriod.am ? 'AM' : 'PM',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF131313),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showGoal) ...[
            const SizedBox(height: 24),
            const Text(
              'Goal',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goalController,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter goal or instruction',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      widget.unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
