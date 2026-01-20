import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/app_theme.dart';
import '../../../reminder/presentation/widgets/primary_button.dart';
import '../../domain/entities/sleep_log.dart';
import '../bloc/bloc.dart';
import '../widgets/circular_sleep_timer.dart';

class SleepLogPage extends StatefulWidget {
  final DateTime initialDate;
  final SleepLog? existingLog;

  const SleepLogPage({super.key, required this.initialDate, this.existingLog});

  @override
  State<SleepLogPage> createState() => _SleepLogPageState();
}

class _SleepLogPageState extends State<SleepLogPage> {
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  late int _quality;

  @override
  void initState() {
    super.initState();

    if (widget.existingLog != null) {
      _startDateTime = widget.existingLog!.startTime;
      _endDateTime = widget.existingLog!.endTime;
      _quality = widget.existingLog!.quality;
    } else {
      // Default: Bedtime 11:00 PM yesterday, Wakeup 7:00 AM today (relative to initialDate)
      final referenceDate = widget.initialDate;
      final previousDay = referenceDate.subtract(const Duration(days: 1));

      _startDateTime = DateTime(
        previousDay.year,
        previousDay.month,
        previousDay.day,
        22,
        0,
      ); // 10 PM Yesterday

      // End Time: 7 AM on Initial Date
      _endDateTime = DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
        7,
        0,
      );
      _quality = 75;
    }
  }

  // Helper to maintain reasonable duration logic when times change
  void _updateDuration() {
    if (_endDateTime.isBefore(_startDateTime)) {
      if (_endDateTime.day == _startDateTime.day) {
        _endDateTime = _endDateTime.add(const Duration(days: 1));
      }
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startDateTime : _endDateTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          final today = DateTime(
            widget.initialDate.year,
            widget.initialDate.month,
            widget.initialDate.day,
            picked.hour,
            picked.minute,
          );
          final yesterday = today.subtract(const Duration(days: 1));

          // Heuristic: "Smart Day Selection"
          // Times 00:00 - 17:59 (Midnight to 6 PM) -> Assume Today (Morning sleep / Afternoon Nap)
          // Times 18:00 - 23:59 (6 PM to Midnight) -> Assume Yesterday (Night Sleep start)
          // This fixes the issue where 1 PM - 5 PM was incorrectly jumping to Yesterday.
          DateTime newStart;
          if (picked.hour < 18) {
            newStart = today;
          } else {
            newStart = yesterday;
          }

          // Smart Shift: Move End Time to preserve duration
          final currentDuration = _endDateTime.difference(_startDateTime);
          _startDateTime = newStart;
          _endDateTime = newStart.add(currentDuration);
        } else {
          // Heuristic: "Next Valid Time"
          final start = _startDateTime;
          final candidateSameDay = DateTime(
            start.year,
            start.month,
            start.day,
            picked.hour,
            picked.minute,
          );
          // If candidate is before start, it must be next day (crossing midnight)
          // or if it's explicitly the next day relative to start.
          // Simple logic: Ensure End > Start.
          if (candidateSameDay.isAfter(start)) {
            _endDateTime = candidateSameDay;
          } else {
            _endDateTime = candidateSameDay.add(const Duration(days: 1));
          }
        }

        _updateDuration();
      });
    }
  }

  void _handleTimeChange(DateTime newTime, bool isStart) {
    setState(() {
      DateTime oldTime = isStart ? _startDateTime : _endDateTime;
      DateTime updatedTime = newTime;

      // Logic: If we crossed midnight, shift the day.
      // 23 -> 0/1 (PM to AM): Day +1
      // 0/1 -> 23 (AM to PM): Day -1

      // Note: CircularSleepTimer returns 'newTime' with the SAME Y/M/D as 'oldTime' passed to it.
      // So we just need to adjust the Day of 'updatedTime'.

      if (oldTime.hour >= 18 && newTime.hour < 6) {
        // Crossed Midnight Forward (Evening -> Morning)
        updatedTime = newTime.add(const Duration(days: 1));
      } else if (oldTime.hour < 6 && newTime.hour >= 18) {
        // Crossed Midnight Backward (Morning -> Evening)
        updatedTime = newTime.subtract(const Duration(days: 1));
      }

      if (isStart) {
        final duration = _endDateTime.difference(_startDateTime);
        _startDateTime = updatedTime;
        _endDateTime = updatedTime.add(duration);
      } else {
        _endDateTime = updatedTime;
      }

      _updateDuration();
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sleep'),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: BlocListener<SleepBloc, SleepState>(
        listener: (context, state) {
          if (state is SleepOperationSuccess) {
            Navigator.pop(context, true);
          } else if (state is SleepError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Date
              Text(
                DateFormat('E, MMM d').format(widget.initialDate),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Circular Timer
              Container(
                height: 320,
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircularSleepTimer(
                  startTime: _startDateTime,
                  endTime: _endDateTime,
                  onStartTimeChanged: (val) => _handleTimeChange(val, true),
                  onEndTimeChanged: (val) => _handleTimeChange(val, false),
                ),
              ),
              const SizedBox(height: 32),

              // Manual Time Entry Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildTimeCard(
                      'BEDTIME',
                      _startDateTime,
                      () => _pickTime(true),
                      Icons.bedtime,
                      isBedtime: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeCard(
                      'WAKE UP',
                      _endDateTime,
                      () => _pickTime(false),
                      Icons.wb_sunny,
                      isBedtime: false,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              PrimaryButton(text: 'Save', onPressed: _saveLog),

              if (widget.existingLog != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _deleteLog,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEBEE), // Light red
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Delete Sleep Record',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _saveLog() {
    // 1. Check for overlapping inputs against loaded logs
    final state = context.read<SleepBloc>().state;
    if (state is SleepLoaded) {
      final newStart = _startDateTime;
      final newEnd = _endDateTime;
      // Allow 24h log rule
      if (newEnd.difference(newStart) < const Duration(hours: 24)) {
        for (var log in state.logs) {
          if (widget.existingLog != null && log.id == widget.existingLog!.id)
            continue;

          if (newStart.isBefore(log.endTime) && newEnd.isAfter(log.startTime)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Selection overlaps with existing log (${DateFormat('h:mm a').format(log.startTime)} - ${DateFormat('h:mm a').format(log.endTime)})',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }
    }

    final log = SleepLog(
      id:
          widget.existingLog?.id ??
          DateTime.now().millisecondsSinceEpoch
              .toString(), // Fix: Ensure ID is generated for new logs
      startTime: _startDateTime,
      endTime: _endDateTime,
      quality: _quality, // Hardcoded for now, could add slider
    );
    context.read<SleepBloc>().add(LogSleep(log));
  }

  // ... (rest of methods: _deleteLog, _getDateLabel, _buildTimeCard)

  void _deleteLog() {
    if (widget.existingLog != null) {
      context.read<SleepBloc>().add(DeleteSleepLog(widget.existingLog!));
    }
  }

  String _getDateLabel(DateTime date) {
    if (_isSameDay(date, widget.initialDate)) {
      return 'Today';
    } else if (_isSameDay(
      date,
      widget.initialDate.subtract(const Duration(days: 1)),
    )) {
      return 'Yesterday';
    } else if (_isSameDay(
      date,
      widget.initialDate.add(const Duration(days: 1)),
    )) {
      return 'Tomorrow';
    }
    return DateFormat('MMM d').format(date);
  }

  Widget _buildTimeCard(
    String label,
    DateTime time,
    VoidCallback onTap,
    IconData icon, {
    required bool isBedtime,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xffF7F8F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isBedtime ? AppTheme.primaryColor : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: DateFormat('h:mm').format(time),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily:
                          'Poppins', // Ensuring font consistency if needed
                    ),
                  ),
                  TextSpan(
                    text: DateFormat(' a').format(time).toLowerCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getDateLabel(time),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
