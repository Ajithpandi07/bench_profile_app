import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/domain.dart';
import '../bloc/bloc.dart';

class HydrationTrackerPage extends StatefulWidget {
  final DateTime? initialDate;
  final HydrationLog? logToEdit; // New parameter

  const HydrationTrackerPage({super.key, this.initialDate, this.logToEdit});

  @override
  State<HydrationTrackerPage> createState() => _HydrationTrackerPageState();
}

class _HydrationTrackerPageState extends State<HydrationTrackerPage> {
  // State variables for new UI
  late DateTime _selectedDate;
  int _amountMl = 200; // Default amount
  int _selectedPresetIndex = -1;

  final List<int> _presets = [100, 250, 350, 500];

  @override
  void initState() {
    super.initState();
    if (widget.logToEdit != null) {
      _selectedDate = widget.logToEdit!.timestamp;
      _amountMl = (widget.logToEdit!.amountLiters * 1000).round();
      // Check if matches preset
      if (_presets.contains(_amountMl)) {
        _selectedPresetIndex = _presets.indexOf(_amountMl);
      }
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
    }
  }

  void _updateAmount(int value) {
    setState(() {
      _amountMl = value.clamp(0, 5000); // Reasonable limits
      // If matches a preset, select it, else deselect
      if (_presets.contains(_amountMl)) {
        _selectedPresetIndex = _presets.indexOf(_amountMl);
      } else {
        _selectedPresetIndex = -1;
      }
    });
  }

  void _onPresetSelected(int index) {
    setState(() {
      _selectedPresetIndex = index;
      _amountMl = _presets[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.logToEdit != null ? 'Edit Water' : 'Water',
          style: const TextStyle(
            color: Color(0xFFEE374D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: const BackButton(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocListener<HydrationBloc, HydrationState>(
        listener: (context, state) {
          if (state is HydrationSuccess) {
            showModernSnackbar(context, 'Hydration logged remotely!');
            Navigator.pop(context, true);
          } else if (state is HydrationFailure) {
            showModernSnackbar(context, state.message, isError: true);
          }
        },
        child: SingleChildScrollView(
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
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _isToday(_selectedDate)
                              ? 'Today'
                              : DateFormat('MMM d').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('hh:mm').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEE374D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('a').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Manual Entry Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFEBF6FF,
                    ).withOpacity(0.5), // Light blue tint
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Water',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF131313),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Daily Hydration Goal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          // Amount Control
                          Row(
                            children: [
                              _buildCircleBtn(
                                Icons.remove,
                                () => _updateAmount(_amountMl - 50),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                height: 60,
                                width: 40,
                                // Placeholder for Cup Icon
                                child: const Icon(
                                  Icons.local_drink,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                              _buildCircleBtn(
                                Icons.add,
                                () => _updateAmount(_amountMl + 50),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$_amountMl ml',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF131313),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Size Presets
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
                  children: List.generate(_presets.length, (index) {
                    final size = _presets[index];
                    final isSelected = index == _selectedPresetIndex;
                    return GestureDetector(
                      onTap: () => _onPresetSelected(index),
                      child: Container(
                        width: 75,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.grey.shade300
                                : Colors.grey.shade200,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            '$size ml',
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
                    );
                  }),
                ),
                const SizedBox(height: 60),

                // Done Button
                BlocBuilder<HydrationBloc, HydrationState>(
                  builder: (context, state) {
                    final isLoading = state is HydrationSaving;
                    return Center(
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEE374D),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEE374D).withOpacity(0.3),
                              offset: const Offset(0, 10),
                              blurRadius: 20,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _saveData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
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

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 20, color: Colors.grey.shade600),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (time != null) {
      setState(() {
        final current = _selectedDate;
        _selectedDate = DateTime(
          current.year,
          current.month,
          current.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _saveData() {
    final volumeLiters = _amountMl / 1000.0;
    if (volumeLiters <= 0) {
      showModernSnackbar(context, 'Please enter a valid amount', isError: true);
      return;
    }

    final log = HydrationLog(
      id:
          widget.logToEdit?.id ??
          const Uuid().v4(), // Use existing ID if editing
      amountLiters: volumeLiters,
      timestamp: _selectedDate,
      beverageType: 'Water',
      userId:
          widget.logToEdit?.userId ??
          '', // Preserve original user ID or let empty be handled (auth usually overrides)
    );

    context.read<HydrationBloc>().add(LogHydration(log));
  }
}
