import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'dart:ui' as ui;

import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/domain.dart';
import '../bloc/bloc.dart';

class HydrationTrackerPage extends StatefulWidget {
  final DateTime? initialDate;
  const HydrationTrackerPage({super.key, this.initialDate});

  @override
  State<HydrationTrackerPage> createState() => _HydrationTrackerPageState();
}

class _HydrationTrackerPageState extends State<HydrationTrackerPage> {
  late DateTime _selectedDate;
  int _selectedSizeIndex = 1; // Default to 250ml
  String _selectedType = 'Regular';
  int _servingCount = 1;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  final List<int> _sizes = [100, 250, 350, 500];
  final List<String> _types = [
    'Regular',
    'Carbonated',
    'Zero-calorie flavored',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<HydrationBloc, HydrationState>(
      listener: (context, state) {
        if (state is HydrationSuccess) {
          showModernSnackbar(context, 'Hydration logged remotely!');

          // We also need to tell the Dashboard to update its UI "Optimistically" if possible
          // or just trust that the user refreshing will get it?
          // User asked for "dashboard updates". Since it's remote only,
          // the dashboard won't see it unless we manually inject it into HealthMetricsBloc
          // OR we refetch from remote (if dashboard fetches remote).
          //
          // Dashboard currently fetches LOCAL cache.
          // So if we save REMOTE only, Dashboard will NEVER show it unless we merge state.
          //
          // Solution: Trigger manual state update in HealthMetricsBloc via a new event or existing mechanism?
          // I'll emit a "ManualMetricAdded" event to HealthMetricsBloc if I can access it.
          // Since we are navigating back, we can pass result "true" to pop.
          Navigator.pop(context, true);
        } else if (state is HydrationFailure) {
          showModernSnackbar(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.red),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          title: const Text(
            'Hydration Tracker',
            style: TextStyle(
              color: Color(0xFF131313),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          // actions: [
          //   Padding(
          //     padding: const EdgeInsets.only(right: 16.0),
          //     child: Row(
          //       children: [
          //         const Icon(
          //           Icons.signal_cellular_alt,
          //           color: Colors.grey,
          //           size: 20,
          //         ),
          //         const SizedBox(width: 4),
          //         const Icon(Icons.wifi, color: Colors.grey, size: 20),
          //         const SizedBox(width: 4),
          //         const Icon(Icons.battery_full, color: Colors.grey, size: 20),
          //       ],
          //     ),
          //   ),
          // ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Section
                const Text(
                  'Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131313),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          DateFormat('hh:mm').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('a').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF131313),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Goal Card
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        width: 342,
                        height: 100,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(205, 234, 248, 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.local_drink,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 8), // Gap 8px
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Water',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF131313),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Daily Hydration Goal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Size Section
                const Text(
                  'Size',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131313),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_sizes.length, (index) {
                    final size = _sizes[index];
                    final isSelected = index == _selectedSizeIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSizeIndex = index),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.grey.shade300
                                : Colors.transparent,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons
                                  .local_cafe_outlined, // Placeholder for cup types
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$size ml',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 15),

                // Type Section
                const Text(
                  'Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131313),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: _types.map((type) {
                    final isSelected = type == _selectedType;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.grey.shade300
                            : Colors.grey.shade200,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF131313)
                            : Colors.grey.shade600,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),

                // Serving Section
                const Text(
                  'Serving',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131313),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [1, 2, 3].map((count) {
                    final isSelected = count == _servingCount;
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _servingCount = count),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.grey.shade300
                                  : Colors.transparent,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 25),

                // Done Button
                BlocBuilder<HydrationBloc, HydrationState>(
                  builder: (context, state) {
                    final isLoading = state is HydrationSaving;
                    return Center(
                      child: Container(
                        width: 303,
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEE374D),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              offset: Offset(0, 10),
                              blurRadius: 15,
                              spreadRadius: -3,
                            ),
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              offset: Offset(0, 4),
                              blurRadius: 6,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _saveData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ), // padding: 14px 20px 10px; - vertical avg 12? user said "14px 20px 10px" which is top-right-bottom for standard CSS? or top-horizontal-bottom? actually single line padding 14px 20px usually means vert 14 horiz 20. But user detailed "14px 20px 10px", likely top 14, horiz 20, bottom 10.
                            // I will use vertical 12 to center text roughly or exact.
                            // But SizedBox limits height to 45 anyway.
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Done',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (time != null) {
      setState(() {
        final now = DateTime.now();
        _selectedDate = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _saveData() {
    final volumeMl = _sizes[_selectedSizeIndex] * _servingCount;
    final volumeLiters = volumeMl / 1000.0;

    final log = HydrationLog(
      id: const Uuid().v4(),
      amountLiters: volumeLiters,
      timestamp: _selectedDate,
      beverageType: _selectedType,
      userId: '', // Will be filled by Repo/DataSource
    );

    // Use Hydration Bloc to save
    context.read<HydrationBloc>().add(LogHydration(log));
  }
}
