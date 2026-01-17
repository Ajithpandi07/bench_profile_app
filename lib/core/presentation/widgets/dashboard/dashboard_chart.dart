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
          Column(
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
          const SizedBox(width: 12),
          // Chart Area
          Expanded(
            child: Stack(
              children: [
                // Grid Background
                Column(
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
    final heightFactor = (item.value / safeMaxVal).clamp(0.0, 1.0);

    // Dynamic width
    double barWidth = 30;
    if (isScrollable) {
      if (items.length > 20)
        barWidth = 12;
      else
        barWidth = 20;
    } else {
      // Expanded view, let width be flexible but cap it visually
      // if fewer items (e.g. 7), bar looks thick. ok.
      if (items.length > 10) barWidth = 12; // Yearly view
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
          const SizedBox(height: 20), // Placeholder space

        Container(
          width: barWidth,
          height:
              (chartHeight * 0.7) *
              heightFactor, // Use % of total chart height for bars
          // Note: The original had fixed height 180. Here we use prop of chartHeight
          // Let's settle on a max bar height logic.
          // IF chartHeight is 250, - labels etc. relative.
          // Let's use simple flexible container or fixed height calculation.
          // Best is to use height factor on a constrained container.
          constraints: BoxConstraints(
            maxHeight: chartHeight * 0.75, // Leave room for labels
            minHeight: 0,
          ),
          decoration: BoxDecoration(
            color: item.isHighlight ? highlightColor : barBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.label,
            style: TextStyle(
              color: item.isHighlight ? highlightColor : Colors.grey.shade400,
              fontSize: 10,
              fontWeight: item.isHighlight
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
