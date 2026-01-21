import 'package:flutter/material.dart';

import '../../domain/entities/sleep_log.dart';

enum SleepChartViewMode { weekly, monthly, yearly }

class SleepChart extends StatelessWidget {
  final List<SleepLog> logs;
  final DateTime startDate;
  final SleepChartViewMode viewMode;

  const SleepChart({
    super.key,
    required this.logs,
    required this.startDate,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Data Bins
    List<double> values = [];
    List<String> labels = [];
    double maxY = 10.0;

    if (viewMode == SleepChartViewMode.weekly) {
      // 7 Days: Mon - Sun
      values = List.filled(7, 0.0);
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (var log in logs) {
        // Normalize to date
        final logDate = DateTime(
          log.startTime.year,
          log.startTime.month,
          log.startTime.day,
        );
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        int index = logDate.difference(start).inDays;
        if (index >= 0 && index < 7) {
          double h = log.duration.inMinutes / 60.0;
          values[index] += h;
        }
      }
    } else if (viewMode == SleepChartViewMode.monthly) {
      // Days in month
      final daysInMonth = DateUtils.getDaysInMonth(
        startDate.year,
        startDate.month,
      );
      values = List.filled(daysInMonth, 0.0);
      // labels: 1, 5, 10, 15, 20, 25, 30? Or just first letters?
      // Too cramped for 30 labels.
      labels = List.generate(daysInMonth, (index) {
        int day = index + 1;
        if (day == 1 || day % 5 == 0) return '$day';
        return '';
      });

      for (var log in logs) {
        if (log.startTime.year == startDate.year &&
            log.startTime.month == startDate.month) {
          int dayIndex = log.startTime.day - 1;
          if (dayIndex >= 0 && dayIndex < daysInMonth) {
            double h = log.duration.inMinutes / 60.0;
            values[dayIndex] += h;
          }
        }
      }
    } else if (viewMode == SleepChartViewMode.yearly) {
      // 12 Months
      values = List.filled(12, 0.0);
      // Determine average or total? Usually stats show Average/Total.
      // For Yearly view, showing "Average Sleep per Night" per month is more useful than Total hours (which would be ~240h).
      // Let's compute AVERAGE daily sleep for each month.

      List<int> counts = List.filled(12, 0);

      labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

      for (var log in logs) {
        if (log.startTime.year == startDate.year) {
          int monthIndex = log.startTime.month - 1;
          if (monthIndex >= 0 && monthIndex < 12) {
            double h = log.duration.inMinutes / 60.0;
            values[monthIndex] += h;
            counts[monthIndex]++;
          }
        }
      }
      // Compute average
      for (int i = 0; i < 12; i++) {
        if (counts[i] > 0) {
          values[i] = values[i] / counts[i];
        }
      }
    }

    // Determine max Y for scale
    double maxVal = values.fold(0, (p, c) => p > c ? p : c);
    if (maxVal < 8)
      maxY = 10;
    else if (maxVal > 12)
      maxY = 14;
    else
      maxY = 12; // Cap reasonable

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // Y-Axis
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  // 0..4 -> 5 steps
                  // If maxY is 10: 10, 8, 6, 4, 2
                  double step = maxY / 5;
                  double val = maxY - (index * step);
                  if (index == 4) val = step; // bottom label
                  return Text('${val.toInt()}h', style: _labelStyle(context));
                }),
              ),
              const SizedBox(width: 16),
              // Chart Area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Grid
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                            (_) => Container(
                              height: 1,
                              color: Theme.of(context).dividerColor,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        // Bars
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceEvenly, // Space evenly relies on equal width widgets
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(values.length, (index) {
                            double val = values[index];
                            double h = (val / maxY) * constraints.maxHeight;
                            if (h > constraints.maxHeight)
                              h = constraints.maxHeight;

                            bool highlight = false;
                            // Logic for highlight: current day/month?
                            final now = DateTime.now();
                            if (viewMode == SleepChartViewMode.weekly) {
                              DateTime day = startDate.add(
                                Duration(days: index),
                              );
                              if (day.year == now.year &&
                                  day.month == now.month &&
                                  day.day == now.day)
                                highlight = true;
                            } else if (viewMode == SleepChartViewMode.monthly) {
                              if (startDate.year == now.year &&
                                  startDate.month == now.month &&
                                  (index + 1) == now.day)
                                highlight = true;
                            } else {
                              if (startDate.year == now.year &&
                                  (index + 1) == now.month)
                                highlight = true;
                            }

                            return _buildBar(context, h, highlight, viewMode);
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // X-Axis
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(labels.length, (index) {
              // For monthly, we have many empty labels?
              return SizedBox(
                width: viewMode == SleepChartViewMode.monthly ? 8 : 20,
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: _labelStyle(context, isColor: false),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(
    BuildContext context,
    double height,
    bool isHighlight,
    SleepChartViewMode mode,
  ) {
    double width = 12;
    if (mode == SleepChartViewMode.weekly) width = 24;
    if (mode == SleepChartViewMode.monthly) width = 6;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: height == 0
            ? Colors.transparent
            : (isHighlight
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context, {bool isColor = false}) {
    return TextStyle(
      color: isColor
          ? Theme.of(context).primaryColor
          : Theme.of(context).hintColor,
      fontSize: 10,
      fontWeight: isColor ? FontWeight.bold : FontWeight.normal,
    );
  }
}
