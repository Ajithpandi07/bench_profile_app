import 'dart:math';
import 'package:flutter/material.dart';

class CircularSleepTimer extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final ValueChanged<DateTime> onStartTimeChanged;
  final ValueChanged<DateTime> onEndTimeChanged;

  const CircularSleepTimer({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  @override
  State<CircularSleepTimer> createState() => _CircularSleepTimerState();
}

class _CircularSleepTimerState extends State<CircularSleepTimer> {
  // Actually, for a sleep timer, usually it's a 12h clock face where the user drags around.
  // But distinguishing AM/PM requires keeping track of loops or just toggling.
  // Design image: "9:50 pm" (left) to "5:30 am" (right).
  // If 0 is top (12), 6 is bottom.
  // 9:50 PM is roughly 10 (top left). 5:30 AM is bottom right.
  // It looks like a standard 12-hour analog clock face.

  double _getAngleFromTime(DateTime time) {
    double hour = time.hour % 12 + time.minute / 60.0;
    // 12 hours = 2pi
    // hour / 12 * 2pi - pi/2 (to shift 0 to top)
    return (hour / 12.0) * 2 * pi - pi / 2;
  }

  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;

  DateTime _getTimeFromAngle(double angle, bool isStart) {
    // angle is -pi to pi, 0 is Right.
    // We want portion of 12 hours starting from Top (-pi/2).

    // Shift so 0 is Top
    double shifted = angle + pi / 2;
    // Now 0 is Top. Range -pi/2 to 3pi/2?
    if (shifted < 0) shifted += 2 * pi;
    // Now 0..2pi starting from Top.

    double fraction = shifted / (2 * pi);
    double totalHours = fraction * 12;

    int hour = totalHours.floor();
    int minute = ((totalHours - hour) * 60).round();
    // Snap to 5 min
    minute = (minute / 5).round() * 5;
    if (minute == 60) {
      hour++;
      minute = 0;
    }
    if (hour == 12) hour = 0; // 0-11 range for logic

    DateTime original = isStart ? widget.startTime : widget.endTime;

    // Proximity logic:
    // We have candidate hours: hour (AM) and hour+12 (PM).
    // We choose the one closest to original.

    int cand1 = hour; // AM
    int cand2 = hour + 12; // PM
    if (hour == 0) {
      cand1 = 0;
      cand2 = 12;
    } // 12 AM, 12 PM
    if (hour == 12) {
      cand1 = 0;
      cand2 = 12;
    } // Just in case logic produced 12

    int diff1 = (cand1 - original.hour).abs();
    if (diff1 > 12) diff1 = 24 - diff1;

    int diff2 = (cand2 - original.hour).abs();
    if (diff2 > 12) diff2 = 24 - diff2;

    int newHour24 = diff1 < diff2 ? cand1 : cand2;

    return DateTime(
      original.year,
      original.month,
      original.day,
      newHour24,
      minute,
    );
  }

  void _handlePanStart(Offset local, Offset center, double size) {
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final touchAngle = atan2(dy, dx); // -pi to pi

    double startAngle = _getAngleFromTime(widget.startTime); // 0 to 2pi
    double endAngle = _getAngleFromTime(widget.endTime);

    double diffStart = _angleDiff(touchAngle, startAngle);
    double diffEnd = _angleDiff(touchAngle, endAngle);

    // Threshold to grab handle
    if (diffStart < 0.5 && diffStart <= diffEnd) {
      _isDraggingStart = true;
      _isDraggingEnd = false;
    } else if (diffEnd < 0.5) {
      _isDraggingStart = false;
      _isDraggingEnd = true;
    } else {
      _isDraggingStart = false;
      _isDraggingEnd = false;
    }
  }

  void _handlePanUpdate(Offset local, Offset center, double size) {
    if (!_isDraggingStart && !_isDraggingEnd) return;

    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final angle = atan2(dy, dx);

    if (_isDraggingStart) {
      widget.onStartTimeChanged(_getTimeFromAngle(angle, true));
    } else {
      widget.onEndTimeChanged(_getTimeFromAngle(angle, false));
    }
  }

  double _angleDiff(double a, double b) {
    double diff = (a - b).abs();
    if (diff > pi) diff = 2 * pi - diff;
    return diff;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size / 2, size / 2);

        return GestureDetector(
          onPanStart: (details) {
            _handlePanStart(details.localPosition, center, size);
          },
          onPanUpdate: (details) {
            _handlePanUpdate(details.localPosition, center, size);
          },
          child: CustomPaint(
            size: Size(size, size),
            painter: SleepTimerPainter(
              startAngle: _getAngleFromTime(widget.startTime),
              endAngle: _getAngleFromTime(widget.endTime),
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center Info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bedtime
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bed, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(widget.startTime),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .black, // Changed from AppTheme.secondaryColor
                            ),
                          ),
                          Text(
                            _getAmPm(widget.startTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Wakeup
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wb_sunny,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(widget.endTime),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .black, // Changed from AppTheme.secondaryColor
                            ),
                          ),
                          Text(
                            _getAmPm(widget.endTime),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Duration
                      // Calculate diff properly wrapping days
                      Builder(
                        builder: (context) {
                          var diff = widget.endTime.difference(
                            widget.startTime,
                          );
                          if (diff.isNegative)
                            diff = widget.endTime
                                .add(const Duration(days: 1))
                                .difference(widget.startTime);
                          return Text(
                            _formatDuration(diff),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime t) {
    int h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    String m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _getAmPm(DateTime t) {
    return t.hour >= 12 ? 'pm' : 'am';
  }

  String _formatDuration(Duration d) {
    int h = d.inHours;
    int m = d.inMinutes % 60;
    return '${h}hr ${m}min';
  }
}

class SleepTimerPainter extends CustomPainter {
  final double startAngle;
  final double endAngle;

  SleepTimerPainter({required this.startAngle, required this.endAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // strokeWidth is 30. radius + 15 = outer edge.
    // To fit full width (outer edge = size.width/2), radius must be size.width/2 - 15.
    final strokeWidth = 30.0;
    final radius = size.width / 2;

    // 1. Tick Marks
    final tickPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final hourTickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Radius for ticks (inner than circle track)
    // Track inner edge is at radius - 15. So ticks at radius - 25.
    final tickRadius = radius - 25;

    for (int i = 0; i < 60; i++) {
      // Logic: 0 is top.
      double angle = (2 * pi / 60) * i - pi / 2;
      bool isHour = i % 5 == 0;

      // Skip ticks where numbers will be (12, 3, 6, 9)
      if (i == 0 || i == 15 || i == 30 || i == 45) {
        continue;
      }

      double tickLen = isHour ? 10.0 : 6.0;

      Offset p1 = Offset(
        center.dx + (tickRadius - tickLen) * cos(angle),
        center.dy + (tickRadius - tickLen) * sin(angle),
      );
      Offset p2 = Offset(
        center.dx + tickRadius * cos(angle),
        center.dy + tickRadius * sin(angle),
      );

      canvas.drawLine(p1, p2, isHour ? hourTickPaint : tickPaint);
    }

    // 2. Draw Clock Numbers
    _drawClockNumber(canvas, center, tickRadius - 15, '12', -pi / 2);
    _drawClockNumber(canvas, center, tickRadius - 15, '3', 0);
    _drawClockNumber(canvas, center, tickRadius - 15, '6', pi / 2);
    _drawClockNumber(canvas, center, tickRadius - 15, '9', pi);

    // 3. Tracks

    // Background Track (Full Circle)
    final bgTrackPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgTrackPaint);

    // Active Arc
    final paintArc = Paint()
      ..color = const Color(0xffEF5350)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double sweep = endAngle - startAngle;
    if (sweep <= 0) sweep += 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paintArc,
    );

    // Inner Dotted Arc
    _drawDottedArc(
      canvas,
      center,
      radius, // Center of track
      startAngle,
      sweep,
      Colors.white,
    );

    // 4. Handles
    _drawIconHandle(
      canvas,
      center,
      radius,
      startAngle,
      Icons.bed,
      const Color(0xffEF5350),
    );
    _drawIconHandle(
      canvas,
      center,
      radius,
      endAngle,
      Icons.wb_sunny,
      Colors.amber,
    );
  }

  void _drawDottedArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Dash/Dot logic
    final double dashWidth = 4;
    final double dashSpace = 4;
    final double circumference = 2 * pi * radius;

    // Convert dash width/space to angle
    final double dashAngle = (dashWidth / circumference) * 2 * pi;
    final double spaceAngle = (dashSpace / circumference) * 2 * pi;

    double currentAngle = startAngle;
    double remainingSweep = sweepAngle;

    while (remainingSweep > 0) {
      final double drawAngle = remainingSweep < dashAngle
          ? remainingSweep
          : dashAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        drawAngle,
        false,
        paint,
      );

      currentAngle += drawAngle + spaceAngle;
      remainingSweep -= (drawAngle + spaceAngle);
    }
  }

  void _drawClockNumber(
    Canvas canvas,
    Offset center,
    double radius,
    String text,
    double angle,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position text centered at the angle
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);
    final offset = Offset(
      x - textPainter.width / 2,
      y - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }

  void _drawIconHandle(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    IconData icon,
    Color color,
  ) {
    final handleRadius = 18.0;
    final x = center.dx + radius * cos(angle);
    final y = center.dy + radius * sin(angle);
    final pos = Offset(x, y);

    canvas.drawCircle(
      pos,
      handleRadius + 2,
      Paint()
        ..color = Colors.black12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(pos, handleRadius, Paint()..color = Colors.white);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(fontSize: 20, fontFamily: icon.fontFamily, color: color),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
