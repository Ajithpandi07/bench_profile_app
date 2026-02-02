import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../reminder/presentation/widgets/primary_button.dart';
import '../../domain/entities/sleep_log.dart';
import '../bloc/bloc.dart';
import '../widgets/circular_sleep_timer.dart';
import '../../../../core/utils/snackbar_utils.dart';

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
      23,
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

    // Check for local Health Connect data (SLEEP_SESSION)
    // using the new Bloc event that queries Isar directly without platform fetch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingLog == null) {
        context.read<SleepBloc>().add(
          CheckLocalHealthConnectData(widget.initialDate),
        );
      }
    });
  }

  // Helper method to show dialog, triggered by BlocListener state change
  void _showHealthConnectDialog(SleepLog draft) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sleep Data Found'),
        content: Text(
          'We found sleep data from Health Connect (${DateFormat('h:mm a').format(draft.startTime)} - ${DateFormat('h:mm a').format(draft.endTime)}). Would you like to use it?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SleepBloc>().add(IgnoreSleepDraft(draft.id));
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _startDateTime = draft.startTime;
                _endDateTime = draft.endTime;
                _quality = draft.quality;
              });
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
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

      // 1. Calculate the hour difference to detect midnight "wraparound"
      final int hourDelta = newTime.hour - oldTime.hour;

      DateTime updatedTime = newTime;

      // Logic: If the jump is more than 12 hours, the user likely
      // dragged the slider across the 12/0 marker.
      if (hourDelta < -12) {
        // Dragged forward across midnight (e.g., 23:00 -> 01:00)
        updatedTime = DateTime(
          oldTime.year,
          oldTime.month,
          oldTime.day + 1,
          newTime.hour,
          newTime.minute,
        );
      } else if (hourDelta > 12) {
        // Dragged backward across midnight (e.g., 01:00 -> 23:00)
        updatedTime = DateTime(
          oldTime.year,
          oldTime.month,
          oldTime.day - 1,
          newTime.hour,
          newTime.minute,
        );
      } else {
        // Same day, just update hour/minute but keep the year/month/day of the oldTime (or current day context)
        // Actually, the newTime coming from CircularSleepTimer has the 'initialDate' context usually, or just raw time.
        // But we need to preserve the *current* date of the slider.
        updatedTime = DateTime(
          oldTime.year,
          oldTime.month,
          oldTime.day,
          newTime.hour,
          newTime.minute,
        );
      }

      // 2. Enforce Bounds and Min-Duration
      updatedTime = _clampDateTime(updatedTime);

      if (isStart) {
        final currentDuration = _endDateTime.difference(_startDateTime);
        _startDateTime = updatedTime;
        // Try to maintain duration unless it hits max bounds
        DateTime proposedEnd = _startDateTime.add(currentDuration);
        _endDateTime = proposedEnd.isAfter(_maxAllowedDate)
            ? _maxAllowedDate
            : proposedEnd;
      } else {
        // Ensure at least 5 mins of sleep
        if (updatedTime.difference(_startDateTime).inMinutes > 5) {
          _endDateTime = updatedTime;
        }
      }

      _quality = _calculateQuality(_startDateTime, _endDateTime);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... (appBar)
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
          } else if (state is SleepLoaded && state.healthConnectDraft != null) {
            // Check if we should ignore this draft (e.g. if we already have local logs)
            // The Bloc's CheckLocalHealthConnectData logic should have filtered this,
            // but the SleepLoaded state might persist.
            // We only want to show it ONCE or if specifically appropriate.
            // Since we trigger the check in initState/postFrameCallback, likely we want to show it.

            // Avoid showing if existingLog is being edited (though the check logic guards this too)
            if (widget.existingLog == null && state.logs.isEmpty) {
              // Wait a bit to not block UI rendering?
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showHealthConnectDialog(state.healthConnectDraft!);
              });
            }
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
            showModernSnackbar(
              context,
              'Selection overlaps with existing log (${DateFormat('h:mm a').format(log.startTime)} - ${DateFormat('h:mm a').format(log.endTime)})',
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
