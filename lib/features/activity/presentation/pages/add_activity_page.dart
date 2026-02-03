import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/activity_log.dart';
import '../bloc/activity_bloc.dart';
import '../bloc/activity_event.dart';
import '../../../../core/utils/snackbar_utils.dart';

class AddActivityPage extends StatefulWidget {
  final String activityType;
  final String? customActivityName;
  final DateTime initialDate;
  final ActivityLog? existingActivity;
  final double? currentDailyTotal;
  final double? dailyTarget;

  const AddActivityPage({
    super.key,
    required this.activityType,
    this.customActivityName,
    required this.initialDate,
    this.existingActivity,
    this.currentDailyTotal,
    this.dailyTarget,
  });

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  DateTime _startTime = DateTime.now();
  int _durationHours = 0;
  int _durationMinutes = 30;
  // Approximated calories per minute based on type (simple logic for now)
  // Walking: 4, Running: 11, Cycling: 8, Swimming: 10, Tennis: 7, Yoga: 3
  double _caloriesPerMinute = 5;
  late final TextEditingController _customNameController;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingActivity != null) {
      _startTime = widget.existingActivity!.startTime;
      _durationHours = widget.existingActivity!.durationMinutes ~/ 60;
      _durationMinutes = widget.existingActivity!.durationMinutes % 60;
    } else {
      _startTime = DateTime(
        widget.initialDate.year,
        widget.initialDate.month,
        widget.initialDate.day,
        DateTime.now().hour,
      );
    }
    _isCustom = widget.activityType.toLowerCase() == 'custom';
    _customNameController = TextEditingController(
      text:
          widget.customActivityName ??
          widget.existingActivity?.customActivityName ??
          (widget.activityType.toLowerCase() == 'custom'
              ? ''
              : widget.activityType),
    );
    _updateCaloriesPerMinute();
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  void _updateCaloriesPerMinute() {
    switch (widget.activityType.toLowerCase()) {
      case 'walking':
        _caloriesPerMinute = 4.0;
        break;
      case 'running':
        _caloriesPerMinute = 11.0;
        break;
      case 'cycling':
        _caloriesPerMinute = 8.0;
        break;
      case 'swimming':
        _caloriesPerMinute = 10.0;
        break;
      case 'tennis':
        _caloriesPerMinute = 7.0;
        break;
      case 'yoga':
        _caloriesPerMinute = 3.0;
        break;
      default:
        _caloriesPerMinute = 5.0;
    }
  }

  double get _totalCalories =>
      (_durationHours * 60 + _durationMinutes) * _caloriesPerMinute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey bg
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const Text(
          'Activity',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.directions_run,
                      color: Color(0xFFE93448),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isCustom
                          ? SizedBox(
                              width: 200,
                              child: TextField(
                                controller: _customNameController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF131313),
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Activity Name',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            )
                          : Text(
                              widget.customActivityName ?? widget.activityType,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF131313),
                              ),
                            ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_totalCalories.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${_durationHours > 0 ? '$_durationHours:' : ''}${_durationMinutes.toString().padLeft(2, '0')}:00', // Mocking seconds
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Start Time Picker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                  // For now just displaying text, normally opens a date picker
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_startTime),
                      );
                      if (time != null) {
                        setState(() {
                          _startTime = DateTime(
                            _startTime.year,
                            _startTime.month,
                            _startTime.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MMM dd, h:mm a').format(_startTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFFE93448),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Duration Picker
            Container(
              padding: const EdgeInsets.all(24), // Bigger padding for duration
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duration',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hours
                      _buildDurationItem(_durationHours, 'HR', (val) {
                        setState(() => _durationHours = val);
                      }, 23),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      // Minutes
                      _buildDurationItem(_durationMinutes, 'MIN', (val) {
                        setState(() => _durationMinutes = val);
                      }, 59),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFF5F5F5),
                      side: const BorderSide(
                        color: Colors.transparent,
                      ), // Removing border as per screenshot style (looks like grey solid)
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final durationFn = Duration(
                        hours: _durationHours,
                        minutes: _durationMinutes,
                      );

                      // Check 1: Start Time in future
                      if (_startTime.isAfter(DateTime.now())) {
                        showModernSnackbar(
                          context,
                          'Cannot log activity for future time or dates',
                          isError: true,
                        );
                        return;
                      }

                      // Check Custom Name
                      if (_isCustom &&
                          _customNameController.text.trim().isEmpty) {
                        showModernSnackbar(
                          context,
                          'Please enter an activity name',
                          isError: true,
                        );
                        return;
                      }

                      // Check 2: Duration completion checks
                      final endTime = _startTime.add(durationFn);

                      if (endTime.isAfter(DateTime.now())) {
                        final validStartTime = DateTime.now().subtract(
                          durationFn,
                        );
                        final timeStr = DateFormat(
                          'h:mm a',
                        ).format(validStartTime);
                        final durationMins =
                            _durationHours * 60 + _durationMinutes;

                        showModernSnackbar(
                          context,
                          'Activity not completed. For a $durationMins min activity, start before $timeStr',
                          isError: true,
                        );
                        return;
                      }

                      final activity = ActivityLog(
                        id: widget.existingActivity?.id ?? const Uuid().v4(),
                        userId: '', // handled by repo
                        activityType: widget.activityType,
                        customActivityName: _isCustom
                            ? _customNameController.text.trim()
                            : (widget.customActivityName ??
                                  widget.existingActivity?.customActivityName),
                        startTime: _startTime,
                        durationMinutes: _durationHours * 60 + _durationMinutes,
                        caloriesBurned: _totalCalories,
                        createdAt: DateTime.now(),
                      );

                      bool wasTargetReached = false;
                      if (widget.dailyTarget != null) {
                        final current = widget.currentDailyTotal ?? 0;
                        final target = widget.dailyTarget!;
                        if ((current + _totalCalories) >= target) {
                          wasTargetReached = true;
                        }
                      }

                      if (widget.existingActivity != null) {
                        context.read<ActivityBloc>().add(
                          UpdateActivityEvent(
                            activity,
                            wasTargetReached: wasTargetReached,
                          ),
                        );
                      } else {
                        context.read<ActivityBloc>().add(
                          AddActivityEvent(
                            activity,
                            wasTargetReached: wasTargetReached,
                          ),
                        );
                      }
                      Navigator.pop(context); // Close page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE93448),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationItem(
    int value,
    String label,
    Function(int) onChanged,
    int max,
  ) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA), // Slightly different background
          borderRadius: BorderRadius.circular(12),
        ),
        child: CupertinoPicker(
          itemExtent: 40,
          onSelectedItemChanged: onChanged,
          scrollController: FixedExtentScrollController(initialItem: value),
          children: List.generate(
            max + 1,
            (index) => Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
