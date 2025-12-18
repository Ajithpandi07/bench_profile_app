import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bench_profile_app/core/services/app_theme.dart';

typedef OnDateSelected = void Function(DateTime date);

class HorizontalDateSelector extends StatefulWidget {
  final DateTime initialDate;
  final int daysBefore;
  final int daysAfter;
  final OnDateSelected onDateSelected;

  const HorizontalDateSelector({
    Key? key,
    required this.initialDate,
    required this.onDateSelected,
    this.daysBefore = 30,
    this.daysAfter = 30,
  }) : super(key: key);

  @override
  State<HorizontalDateSelector> createState() => _HorizontalDateSelectorState();
}

class _HorizontalDateSelectorState extends State<HorizontalDateSelector> {
  late final List<DateTime> _dates;
  late DateTime _selected;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected = DateTime(widget.initialDate.year, widget.initialDate.month,
        widget.initialDate.day);
    _dates =
        _generateDates(widget.initialDate, widget.daysBefore, widget.daysAfter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(HorizontalDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameDay(widget.initialDate, oldWidget.initialDate)) {
      if (!_sameDay(_selected, widget.initialDate)) {
        setState(() {
          _selected = widget.initialDate;
        });
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToSelected());
      }
    }
  }

  List<DateTime> _generateDates(DateTime center, int before, int after) {
    // If we want a fixed range relative to "Today", we should anchor to DateTime.now()
    // rather than shifting the window every time the user taps (confusing UX).
    // Let's verify if the user wants an infinite scroll or a fixed window.
    // Current impl shifts the window based on 'center'.
    // If the parent passes a new 'initialDate' (the selected one), the window shifts?
    // That might be jarring.
    // Assuming we keep the existing generation logic for now but ensure smooth scroll.
    final List<DateTime> dates = [];
    // Using the passed center:
    for (int i = -before; i <= after; i++) {
      final d = DateTime(center.year, center.month, center.day)
          .add(Duration(days: i));
      dates.add(d);
    }
    return dates;
  }

  void _onTap(DateTime date) {
    if (_sameDay(date, _selected)) return;
    setState(() => _selected = date);
    widget.onDateSelected(date);
    _scrollToSelected();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    final index = _dates.indexWhere((d) => _sameDay(d, _selected));
    if (index == -1) return;

    const itemWidth = 40.0; // matched to build method width
    const separatorWidth = 12.0; // matched to separatorBuilder

    // Calculate the offset to center the item
    // center of item = index * (w + sep) + w/2
    // center of screen = screenWidth / 2
    // offset = centerOfItem - centerOfScreen

    final screenWidth = MediaQuery.of(context).size.width;
    final target = (index * (itemWidth + separatorWidth)) +
        (itemWidth / 2) -
        (screenWidth / 2) +
        16; // +16 for padding correction?

    final max = _scrollController.position.maxScrollExtent;
    final min = _scrollController.position.minScrollExtent;

    _scrollController.animateTo(
      target.clamp(min, max),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  String _dayName(DateTime d) => DateFormat('E').format(d); // Mon, Tue
  String _dateShort(DateTime d) => DateFormat('d/M').format(d);
  bool _isToday(DateTime d) => _sameDay(d, DateTime.now());

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _sameDay(date, _selected);
          final isToday = _isToday(date);

          return GestureDetector(
            onTap: () => _onTap(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius:
                    BorderRadius.circular(20), // Fully rounded for width 56
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isSelected
                    ? null
                    : Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayName(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? AppTheme.primaryColor
                              : Colors.grey.shade500),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dateShort(date).split('/')[0],
                    style: TextStyle(
                      fontSize: 18,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isToday && !isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
