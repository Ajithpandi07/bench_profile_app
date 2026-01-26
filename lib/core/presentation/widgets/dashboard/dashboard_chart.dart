import 'package:flutter/material.dart';

class DashboardChartItem {
  final String label;
  final double value;
  final bool isHighlight;

  DashboardChartItem({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });
}

class DashboardChart extends StatelessWidget {
  final List<DashboardChartItem> items;
  final double maxVal;
  final int gridLines;
  final double chartHeight;
  final Color highlightColor;
  final Color barBackgroundColor;
  final String Function(double)? formatValue;
  final Function(int)? onBarTap;

  const DashboardChart({
    super.key,
    required this.items,
    required this.maxVal,
    this.gridLines = 5,
    this.chartHeight = 250,
    this.highlightColor = const Color(0xFFE93448),
    this.barBackgroundColor = const Color(0xFFFFEBEB),
    this.formatValue,
    this.onBarTap,
    this.fitAll = false,
  });

  final bool fitAll;

  // Reserved space for labels and highlights
  static const double _topPadding = 24.0;
  static const double _bottomPadding = 32.0;

  @override
  Widget build(BuildContext context) {
    // Safety check for empty items
    if (items.isEmpty) {
      return Center(
        child: Text('No data', style: TextStyle(color: Colors.grey.shade400)),
      );
    }

    // Ensure maxVal is valid
    final safeMaxVal = maxVal <= 0 ? 100.0 : maxVal;
    final double step = safeMaxVal / (gridLines - 1);

    return SizedBox(
      height: chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Y-Axis
          Padding(
            padding: const EdgeInsets.only(
              top: _topPadding,
              bottom: _bottomPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(gridLines, (index) {
                final value = safeMaxVal - (step * index);
                final label = formatValue != null
                    ? formatValue!(value)
                    : value.toInt().toString();
                return Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          // Chart Area
          Expanded(
            child: Stack(
              children: [
                // Grid Background
                Padding(
                  padding: const EdgeInsets.only(
                    top: _topPadding,
                    bottom: _bottomPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(gridLines, (index) {
                      return Row(
                        children: List.generate(
                          40, // Number of dashed lines
                          (i) => Expanded(
                            child: Container(
                              color: i % 2 == 0
                                  ? Colors.grey.shade300
                                  : Colors.transparent,
                              height: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Bars
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Heuristic: Scroll if item width would be too small
                      // e.g. < 24px per item
                      final widthPerItem = constraints.maxWidth / items.length;
                      final isScrollable = !fitAll && widthPerItem < 28;

                      if (isScrollable) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: items
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => GestureDetector(
                                      onTap: () => onBarTap?.call(entry.key),
                                      behavior: HitTestBehavior.opaque,
                                      child: _buildBarItem(
                                        entry.value,
                                        safeMaxVal,
                                        isScrollable: true,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: items
                              .asMap()
                              .entries
                              .map(
                                (entry) => Expanded(
                                  child: GestureDetector(
                                    onTap: () => onBarTap?.call(entry.key),
                                    behavior: HitTestBehavior.opaque,
                                    child: _buildBarItem(
                                      entry.value,
                                      safeMaxVal,
                                      isScrollable: false,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(
    DashboardChartItem item,
    double safeMaxVal, {
    bool isScrollable = false,
  }) {
    // Calculate available height for bars
    final plottingHeight = chartHeight - _topPadding - _bottomPadding;
    final heightFactor = (item.value / safeMaxVal).clamp(0.0, 1.0);

    // Dynamic width
    double barWidth = 30;
    if (isScrollable) {
      if (items.length > 20)
        barWidth = 12;
      else
        barWidth = 20;
    } else {
      // Expanded view
      if (items.length > 10) barWidth = 12;
    }

    final displayValue = formatValue != null
        ? formatValue!(item.value)
        : item.value.toInt().toString();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (item.isHighlight)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(20),
            ),
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(
              displayValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          // If not highlight, we don't necessarily need to reserve the full top padding space
          // ABOVE the bar stack, because the bar stack grows from bottom.
          // But if we want the bar to be clickable or consistent...
          // Actually, MainAxisAlignment.end pushes everything down.
          // We just need to make sure we don't exceed the chart area.
          const SizedBox.shrink(),

        Container(
          width: barWidth,
          height: plottingHeight * heightFactor,
          decoration: BoxDecoration(
            color: item.isHighlight ? highlightColor : barBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),

        // Fixed height for Label area to align with Grid Bottom
        SizedBox(
          height: _bottomPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: item.isHighlight
                        ? highlightColor
                        : Colors.grey.shade400,
                    fontSize: 10,
                    fontWeight: item.isHighlight
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
