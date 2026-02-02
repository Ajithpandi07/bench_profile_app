import 'package:flutter/material.dart';

class ActivityTypeSelector extends StatefulWidget {
  const ActivityTypeSelector({super.key});

  @override
  State<ActivityTypeSelector> createState() => _ActivityTypeSelectorState();
}

class _ActivityTypeSelectorState extends State<ActivityTypeSelector> {
  String? _selectedActivity;

  final List<String> _activityTypes = [
    'Walking',
    'Running',
    'Cycling',
    'Swimming',
    'Tennis',
    'Yoga',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Activity Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE93448),
            ),
          ),
          const SizedBox(height: 16),
          ..._activityTypes.map((type) => _buildOption(type)),

          const SizedBox(height: 8),

          GestureDetector(
            onTap: () async {
              // Show dialog to get custom activity name
              final customName = await showDialog<String>(
                context: context,
                builder: (context) => _CustomActivityDialog(),
              );

              if (customName != null &&
                  customName.isNotEmpty &&
                  context.mounted) {
                Navigator.pop(context, {
                  'type': 'Custom',
                  'customName': customName,
                });
              }
            },
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Color(0xFFE93448)),
                  SizedBox(width: 12),
                  Text(
                    'Add Custom Activity',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Container(
              width: 306,
              height: 32,
              decoration: BoxDecoration(
                color: _selectedActivity == null
                    ? Colors.grey.shade300
                    : const Color(0xFFEE374D),
                borderRadius: BorderRadius.circular(5),
                boxShadow: _selectedActivity == null
                    ? []
                    : [
                        const BoxShadow(
                          color: Color.fromRGBO(238, 55, 77, 0.3),
                          offset: Offset(0, 4),
                          blurRadius: 9.2,
                          spreadRadius: 0,
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _selectedActivity == null
                    ? null
                    : () {
                        Navigator.pop(context, {'type': _selectedActivity});
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(306, 32),
                  fixedSize: const Size(306, 32),
                  backgroundColor: const Color(0xFFEE374D),
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildOption(String type) {
    bool isSelected = _selectedActivity == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedActivity = type),
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? const Color(0xFFE93448) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE93448)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE93448),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              type,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog for entering custom activity name
class _CustomActivityDialog extends StatefulWidget {
  @override
  State<_CustomActivityDialog> createState() => _CustomActivityDialogState();
}

class _CustomActivityDialogState extends State<_CustomActivityDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom Activity'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Enter activity name (e.g., Rock Climbing)',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.pop(context, value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context, name);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
