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
    _selected = DateTime(widget.initialDate.year, widget.initialDate.month,
        widget.initialDate.day);
    _dates =
        _generateDates(widget.initialDate, widget.daysBefore, widget.daysAfter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  List<DateTime> _generateDates(DateTime center, int before, int after) {
    final List<DateTime> dates = [];
    for (int i = -before; i <= after; i++) {
      final d = DateTime(center.year, center.month, center.day)
          .add(Duration(days: i));
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
    const itemWidth = 46.0;
    const separatorWidth = 12.0;
    final target = (index * (itemWidth + separatorWidth)) -
        (MediaQuery.of(context).size.width / 2) +
        (itemWidth / 2);
    final max = _scrollController.position.hasContentDimensions
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    _scrollController.animateTo(
      target.clamp(0, max),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
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
          const primaryColor = Color(0xFFEE374D);

          return GestureDetector(
            onTap: () => _onTap(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.white,
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
                          : (isToday ? primaryColor : Colors.grey.shade500),
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
                        decoration: const BoxDecoration(
                          color: primaryColor,
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
