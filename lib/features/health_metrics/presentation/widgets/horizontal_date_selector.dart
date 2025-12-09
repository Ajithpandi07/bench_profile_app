import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    _selected = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
    _dates = _generateDates(widget.initialDate, widget.daysBefore, widget.daysAfter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  List<DateTime> _generateDates(DateTime center, int before, int after) {
    final List<DateTime> dates = [];
    for (int i = -before; i <= after; i++) {
      final d = DateTime(center.year, center.month, center.day).add(Duration(days: i));
      dates.add(d);
    }
    return dates;
  }

  void _onTap(DateTime date) {
    setState(() => _selected = DateTime(date.year, date.month, date.day));
    widget.onDateSelected(_selected);
    _scrollToSelected();
  }

  void _scrollToSelected() {
    final index = _dates.indexWhere((d) => _sameDay(d, _selected));
    if (index == -1) return;
    const itemWidth = 80.0; // must match item size below
    final target = (index * (itemWidth + 8)) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
    final max = _scrollController.position.hasContentDimensions ? _scrollController.position.maxScrollExtent : 0.0;
    _scrollController.animateTo(
      target.clamp(0, max),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
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
      height: 96,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _sameDay(date, _selected);
          final isToday = _isToday(date);

          return GestureDetector(
            onTap: () => _onTap(date),
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : isToday
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? null : Border.all(color: Colors.grey.withOpacity(0.12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayName(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : (isToday ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dateShort(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (isToday)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(width: 6, height: 6, decoration: BoxDecoration(color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
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