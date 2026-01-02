import 'package:flutter/material.dart';
import '../primary_button.dart';
import '../../../../../core/services/app_theme.dart';

class AddDetailsStep extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final ValueChanged<String> onCategoryChanged;
  final String selectedCategory;
  final VoidCallback onNext;

  const AddDetailsStep({
    super.key,
    required this.nameController,
    required this.quantityController,
    required this.unitController,
    required this.onCategoryChanged,
    required this.selectedCategory,
    required this.onNext,
  });

  @override
  State<AddDetailsStep> createState() => _AddDetailsStepState();
}

class _AddDetailsStepState extends State<AddDetailsStep> {
  final List<String> categories = ['Water', 'Workout', 'Activity'];

  String? _nameError;
  String? _quantityError;

  @override
  void initState() {
    super.initState();
    // Clear errors when user types
    widget.nameController.addListener(() {
      if (_nameError != null) {
        setState(() => _nameError = null);
      }
    });
    widget.quantityController.addListener(() {
      if (_quantityError != null) {
        setState(() => _quantityError = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Center(
              child: Text(
                'Add Reminder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Reminder Name
            const Text(
              'Reminder Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 340,
              // Height needs to adapt to error text, removing fixed height
              // height: 40,
              child: TextField(
                controller: widget.nameController,
                decoration: InputDecoration(
                  hintText: 'eg.: Morning Water Intake',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  errorText: _nameError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...categories.map((category) {
                    final isSelected = widget.selectedCategory == category;
                    return GestureDetector(
                      onTap: () => widget.onCategoryChanged(category),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(
                                  color:
                                      isSelected ? Colors.white : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Add Category Button
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quantity
            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    width: 270,
                    // Remove fixed height to allow error text
                    // height: 40,
                    child: TextField(
                      controller: widget.quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '',
                        errorText: _quantityError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 66,
                    height:
                        48, // Adjusted height to match text field with padding
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.unitController.text.isEmpty
                            ? 'ml'
                            : widget.unitController.text,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        isExpanded: false,
                        items: ['ml', 'L', 'g', 'kg', 'min', 'hr']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            widget.unitController.text = newValue;
                            setState(() {}); // refresh UI
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text(
              'Personalize this based on your routine.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: PrimaryButton(
                text: 'Next',
                padding: EdgeInsets.zero,
                onPressed: () {
                  bool isValid = true;
                  setState(() {
                    if (widget.nameController.text.trim().isEmpty) {
                      _nameError = 'Name is required';
                      isValid = false;
                    }
                    if (widget.quantityController.text.trim().isEmpty) {
                      _quantityError = 'Quantity is required';
                      isValid = false;
                    }
                  });

                  if (isValid) {
                    widget.onNext();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
