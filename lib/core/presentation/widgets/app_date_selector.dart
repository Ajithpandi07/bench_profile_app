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

  // Design constants
  static const double _itemWidth = 46.0;
  static const double _itemGap = 4.0; // Horizontal margin (2.0 * 2)
  static const int _itemsToShow = 7;

  // Derived constant for the ideal width if we want exactly 7 items visible
  // itemSlotWidth = 46 + 4 = 50.
  // idealWidth = 50 * 7 = 350. plus padding?
  // Let's stick to dynamic calculation based on available width,
  // but hinting at the preferred size.

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

    // We can't easily access the current layout width here without context constraints.
    // However, since we are in a listener, we can rely on the fact that if layout changed,
    // screen attributes might be constant.
    // Ideally, we should store the current container width from the build method
    // if we need it here, or use a fixed assumption if we enforce a fixed width.

    // For specific month detection:
    final offset = _scrollController.offset;
    // Estimate index based on an average item width if exact width is variable
    // But since we want to be precise, let's use the width we know we rendered with.
    // We can store the last calculated itemSlotWidth in a variable.

    if (_lastItemSlotWidth == 0) return;

    final listPadding = 10.0;
    int firstIndex = ((offset - listPadding) / _lastItemSlotWidth).floor();

    Map<String, int> monthCounts = {};
    for (int i = 0; i < 7; i++) {
      // Check next 7 items
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

  double _lastItemSlotWidth = 0;

  void _scrollToSelected({bool animated = false}) {
    if (!_scrollController.hasClients || !mounted) return;
    if (_lastItemSlotWidth == 0 && _lastContainerWidth == 0) {
      // If we haven't built yet, retry after frame
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToSelected(animated: animated),
      );
      return;
    }

    final index = _days.indexWhere(
      (d) => DateUtils.isSameDay(d, widget.selectedDate),
    );

    if (index != -1) {
      final containerWidth = _lastContainerWidth;
      final listPadding = 10.0; // matches padding in ListView
      final itemSlotWidth = _lastItemSlotWidth;

      // Center logic:
      // Item center = (index * slotWidth) + (slotWidth / 2)
      // View center = containerWidth / 2
      // Scroll offset = Item center - View center
      // But we have start padding 'listPadding' inside the scroll view?
      // Actually, if we pad the ListView, the content starts after padding.
      // So index 0 starts at 0 inside the scroll view + padding.
      // Let's assume standard ListView flow. padding is part of content extent.
      // If padding is symmetric horizontal:
      // Item 0 starts at `listPadding`.

      final itemCenter =
          listPadding + (index * itemSlotWidth) + (itemSlotWidth / 2);
      final offset = itemCenter - (containerWidth / 2);

      final targetOffset = offset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

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

  void _changeMonth(int offset) {
    final current = _visibleViewDate ?? widget.selectedDate;
    final newMonth = DateTime(current.year, current.month + offset, 1);

    final index = _days.indexWhere(
      (d) => d.year == newMonth.year && d.month == newMonth.month && d.day == 1,
    );

    if (index != -1) {
      final date = _days[index];
      widget.onDateSelected(date);
      // Wait for selection to process then scroll
      // Or scroll immediately
      // The _scrollToSelected will be called by didUpdateWidget if date changes?
      // No, let's force scroll here too to be snappy.

      // We need to set state to update the date locally if parent doesn't update immediately?
      // But onDateSelected usually triggers parent rebuild -> didUpdateWidget.
      // Let's just animate scroll to that index.

      final containerWidth = _lastContainerWidth;
      final listPadding = 10.0;
      final itemSlotWidth = _lastItemSlotWidth;

      final itemCenter =
          listPadding + (index * itemSlotWidth) + (itemSlotWidth / 2);
      final scrollOffset = itemCenter - (containerWidth / 2);

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
  void didUpdateWidget(covariant AppDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      if (!_isProgrammaticScroll) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToSelected(animated: true),
        );
      }
      setState(() {
        _visibleViewDate = widget.selectedDate;
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

  double _lastContainerWidth = 0;

  @override
  Widget build(BuildContext context) {
    final currentVisibleDate = _visibleViewDate ?? widget.selectedDate;
    final currentMonth = DateFormat('MMMM yyyy').format(currentVisibleDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic widths
        // We want to simulate the look of "around 7 items visible".
        // Max width could be infinity if in a scroll view, so cap it if needed.
        // But usually this widget is in a column.

        double containerWidth = constraints.maxWidth;
        // If it's unbounded (rare for width), fallback.
        if (containerWidth.isInfinite) containerWidth = 338.0;

        // If we want to strictly follow the "card" look with fixed size 338 centered:
        // Then we should constrain the inner container.
        // The user asked to fix the specific issues but keep the UI.
        // A safe bet for responsiveness: use full width but match item sizing to be reasonable.

        // HOWEVER, the user specifically copy-pasted "Use fixed width 338" multiple times.
        // This implies they WANT that fixed size card.
        // The problem is that it wasn't centered.
        // So let's Center it and use exactly 338.

        final double finalWidth = containerWidth > 338.0
            ? 338.0
            : containerWidth;

        _lastContainerWidth = finalWidth;

        final listPadding = 10.0;
        final availableListWidth = finalWidth - (listPadding * 2);

        // We want exactly 7 items visible?
        final itemsToShow = 6.5;
        final itemSlotWidth = availableListWidth / itemsToShow;
        _lastItemSlotWidth = itemSlotWidth;

        final horizontalMargin = 4.0;
        final itemWidth = itemSlotWidth - (horizontalMargin * 2);

        return Center(
          child: Container(
            width: finalWidth,
            height: 142,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6), // Light grey background
              borderRadius: BorderRadius.circular(30), // Rounded corners
              // Removed shadow for cleaner look or keep minimal?
              // Design screenshot had subtle shadow?
              // Let's keep it clean as per "card" look usually implies some elevation or distinct bg.
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Header with Month and Arrows
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderButton(
                        Icons.arrow_back,
                        () => _changeMonth(-1),
                      ),
                      Text(
                        currentMonth,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      _buildHeaderButton(
                        Icons.arrow_forward,
                        () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),

                // Date List
                SizedBox(
                  height: 65,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemExtent: itemSlotWidth,
                    itemCount: _days.length,
                    padding: EdgeInsets.symmetric(horizontal: listPadding),
                    itemBuilder: (context, index) {
                      final date = _days[index];
                      final isSelected = DateUtils.isSameDay(
                        date,
                        widget.selectedDate,
                      );
                      final isToday = DateUtils.isSameDay(date, DateTime.now());

                      return GestureDetector(
                        onTap: () => widget.onDateSelected(date),
                        child: Container(
                          width: itemWidth,
                          margin: EdgeInsets.symmetric(
                            horizontal: horizontalMargin,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEE374D)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFEE374D,
                                      ).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Dot indicator (Moved to TOP)
                              if (isToday || isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 6,
                                  ), // Add space between dot and text
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFEE374D),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),

                              // Day Name (MON, TUE)
                              Text(
                                DateFormat('EEE').format(date).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.9)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Day Number (01, 02)
                              Text(
                                DateFormat('dd').format(date),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
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
          ),
        );
      },
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }
}
