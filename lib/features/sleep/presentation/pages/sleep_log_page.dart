import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
  late DateTime _minAllowedDate;
  late DateTime _maxAllowedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final referenceDate = widget.initialDate;
    final previousDay = referenceDate.subtract(const Duration(days: 1));

    // Define Bounds: Day-1 12:00 PM to Day 11:59 AM
    _minAllowedDate = DateTime(
      previousDay.year,
      previousDay.month,
      previousDay.day,
      12,
      0,
    );
    _maxAllowedDate = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      11,
      59,
    );

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
      _quality = _calculateQuality(_startDateTime, _endDateTime);
    }
  }

  int _calculateQuality(DateTime start, DateTime end) {
    // 8 hours = 480 minutes
    final duration = end.difference(start).inMinutes;
    return ((duration / 480) * 100).clamp(0, 100).toInt();
  }

  // Helper to restrict date selection to the valid window
  DateTime _clampDateTime(DateTime dt) {
    if (dt.isBefore(_minAllowedDate)) return _minAllowedDate;
    if (dt.isAfter(_maxAllowedDate)) return _maxAllowedDate;
    return dt;
  }

  // Helper to maintain reasonable duration logic when times change
  void _updateDuration() {
    if (_endDateTime.isBefore(_startDateTime)) {
      if (_endDateTime.day == _startDateTime.day) {
        _endDateTime = _endDateTime.add(const Duration(days: 1));
      }
    }
    // Ensure final times never exceed bounds
    _startDateTime = _clampDateTime(_startDateTime);
    _endDateTime = _clampDateTime(_endDateTime);
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

        // Apply Clamping
        _startDateTime = _clampDateTime(_startDateTime);
        _endDateTime = _clampDateTime(_endDateTime);

        _updateDuration();
        _quality = _calculateQuality(_startDateTime, _endDateTime);
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

      // Enforce Bounds
      updatedTime = _clampDateTime(updatedTime);

      if (isStart) {
        // Calculate original duration to attempt preservation
        final duration = _endDateTime.difference(_startDateTime);
        _startDateTime = updatedTime;
        // Potential new end time
        DateTime proposedEnd = updatedTime.add(duration);
        // Clamp end time if it exceeds bounds (prevent pushing end beyond limit)
        if (proposedEnd.isAfter(_maxAllowedDate)) {
          proposedEnd = _maxAllowedDate;
        }

        // Validation: Ensure Start != End (min 5 mins)
        if (proposedEnd.difference(_startDateTime).inMinutes.abs() < 5) {
          // Revert or adjust?
          // Since we are shifting, this usually happens if hitting bounds.
          // Let's just return and NOT update if it results in collision.
          return;
        }
        _endDateTime = proposedEnd;
      } else {
        // Validation: Ensure Start != End (min 5 mins)
        if (updatedTime.difference(_startDateTime).inMinutes.abs() < 5) {
          return;
        }
        _endDateTime = updatedTime;
      }

      _updateDuration();
      _quality = _calculateQuality(_startDateTime, _endDateTime);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sleep'),
        leading: BackButton(
          color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.black,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Theme.of(context).primaryColor,
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
            setState(() => _isSaving = false);
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
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Circular Timer
              Container(
                height: 380,
                width: 380,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
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
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                PrimaryButton(text: 'Save', onPressed: _saveLog),

              if (widget.existingLog != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _deleteLog,
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Delete Sleep Record',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
    if (_isSaving) return;

    if (_endDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Wait, you haven\'t woken up yet! Sleep cannot end in the future.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    setState(() {
      _isSaving = true;
    });

    final log = SleepLog(
      id:
          widget.existingLog?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _startDateTime,
      endTime: _endDateTime,
      quality: _quality,
      notes: widget.existingLog?.notes,
    );
    context.read<SleepBloc>().add(
      LogSleep(log, previousLog: widget.existingLog),
    );
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (isBedtime
                                ? Theme.of(context).primaryColor
                                : Colors.orange)
                            .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isBedtime
                        ? Theme.of(context).primaryColor
                        : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor.withOpacity(0.8),
                    letterSpacing: 1.0,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily:
                          'Poppins', // Ensuring font consistency if needed
                    ),
                  ),
                  TextSpan(
                    text: DateFormat(' a').format(time).toLowerCase(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getDateLabel(time),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
