import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const AppDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<AppDateSelector> createState() => _AppDateSelectorState();
}

class _AppDateSelectorState extends State<AppDateSelector> {
  late ScrollController _scrollController;
  late List<DateTime> _days;
  DateTime? _visibleViewDate;
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _days = _getDays();
    _visibleViewDate = widget.selectedDate;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isProgrammaticScroll) return;

    // Use fixed width 338 instead of screen width logic
    final containerWidth = 338.0;
    final listPadding = 10.0;
    final availableWidth = containerWidth - (listPadding * 2);
    final itemsToShow = 7;
    final itemSlotWidth = availableWidth / itemsToShow;

    final startOffset = _scrollController.offset;
    int firstIndex = ((startOffset - listPadding) / itemSlotWidth).floor();

    // Check majority of visible items (7 items)
    // to decide which month to show.

    Map<String, int> monthCounts = {};

    for (int i = 0; i < itemsToShow; i++) {
      int idx = firstIndex + i;
      if (idx >= 0 && idx < _days.length) {
        final date = _days[idx];
        String key = "${date.year}-${date.month}";
        monthCounts[key] = (monthCounts[key] ?? 0) + 1;
      }
    }

    String? majorityKey;
    int maxCount = -1;
    monthCounts.forEach((key, count) {
      if (count > maxCount) {
        maxCount = count;
        majorityKey = key;
      }
    });

    if (majorityKey != null) {
      List<String> parts = majorityKey!.split('-');
      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]);

      final currentVisible = _visibleViewDate ?? widget.selectedDate;
      if (currentVisible.year != year || currentVisible.month != month) {
        setState(() {
          _visibleViewDate = DateTime(year, month, 1);
        });
      }
    }
  }

  void _scrollToSelected({bool animated = false}) {
    if (!_scrollController.hasClients || false == mounted) return;

    final index =
        _days.indexWhere((d) => DateUtils.isSameDay(d, widget.selectedDate));

    if (index != -1) {
      // Use fixed width 338
      final containerWidth = 338.0;
      final listPadding = 10.0;
      final availableWidth = containerWidth - (listPadding * 2);
      final itemsToShow = 7;
      final itemSlotWidth = availableWidth / itemsToShow;

      final offset =
          (index * itemSlotWidth) - (containerWidth / 2) + (itemSlotWidth / 2);

      final targetOffset =
          offset.clamp(0.0, _scrollController.position.maxScrollExtent);

      if (animated) {
        _isProgrammaticScroll = true;
        _scrollController
            .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
            .then((_) {
          if (mounted) _isProgrammaticScroll = false;
        });
      } else {
        _scrollController.jumpTo(targetOffset);
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _visibleViewDate = widget.selectedDate;
      });
    }
  }

  void _changeMonth(int offset) {
    final current = _visibleViewDate ?? widget.selectedDate;
    final newMonth = DateTime(current.year, current.month + offset, 1);

    // Find index of the first day of newMonth
    final index = _days.indexWhere((d) =>
        d.year == newMonth.year && d.month == newMonth.month && d.day == 1);

    if (index != -1) {
      final date = _days[index];
      widget.onDateSelected(date);
      // We also want to scroll to it.

      // Use fixed width 338
      final containerWidth = 338.0;
      final listPadding = 10.0;
      final availableWidth = containerWidth - (listPadding * 2);
      final itemsToShow = 7;
      final itemSlotWidth = availableWidth / itemsToShow;

      final scrollOffset =
          (index * itemSlotWidth) - (containerWidth / 2) + (itemSlotWidth / 2);

      _isProgrammaticScroll = true;
      _scrollController
          .animateTo(
        scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        if (mounted) _isProgrammaticScroll = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DateTime> _getDays() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 365));
    return List.generate(731, (index) => start.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final currentVisibleDate = _visibleViewDate ?? widget.selectedDate;
    final currentMonth = DateFormat('MMMM').format(currentVisibleDate);

    // Use fixed width 338
    final containerWidth = 338.0;
    final listPadding = 10.0;
    final availableWidth = containerWidth - (listPadding * 2);
    final itemsToShow = 7;
    final itemSlotWidth = availableWidth / itemsToShow;

    final horizontalMargin = 2.0;
    final itemWidth = itemSlotWidth - (horizontalMargin * 2);

    return Container(
      width: 338,
      height: 142,
      padding:
          const EdgeInsets.symmetric(vertical: 8), // Reduced padding further
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      size: 18, color: Colors.black87),
                  onPressed: () => _changeMonth(-1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // minimize button size
                ),
                Text(
                  currentMonth,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward,
                      size: 18, color: Colors.black87),
                  onPressed: () => _changeMonth(1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // minimize button size
                ),
              ],
            ),
          ),
          const SizedBox(height: 8), // Reduced spacing
          SizedBox(
            height: 60, // Reduced height to prevent overflow
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              padding: EdgeInsets.symmetric(horizontal: listPadding),
              itemBuilder: (context, index) {
                final date = _days[index];
                final isSelected =
                    DateUtils.isSameDay(date, widget.selectedDate);
                final isToday = DateUtils.isSameDay(date, DateTime.now());

                return GestureDetector(
                  onTap: () => widget.onDateSelected(date),
                  child: Container(
                    width: itemWidth,
                    margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFEE374D) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFFEE374D).withOpacity(0.3)
                              : Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10, // Reduced font size
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 16, // Reduced font size
                            color: isSelected ? Colors.white : Colors.black,
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
                                color: Color(0xFFEE374D),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
