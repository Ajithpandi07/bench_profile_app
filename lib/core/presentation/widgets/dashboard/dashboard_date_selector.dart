import 'package:flutter/material.dart';

class DashboardDateSelector extends StatelessWidget {
  final List<String> views;
  final String selectedView;
  final Function(String) onSelected;
  final Color activeColor;

  const DashboardDateSelector({
    super.key,
    required this.views,
    required this.selectedView,
    required this.onSelected,
    this.activeColor = const Color(0xFFE93448),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: views.map((view) => _buildTab(view)).toList(),
      ),
    );
  }

  Widget _buildTab(String text) {
    final isSelected = selectedView == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
