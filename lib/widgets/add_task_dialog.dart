import 'package:flutter/material.dart';
import '../models/task_duration.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskDuration _selectedDuration = TaskDuration.once;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
            ),
            const SizedBox(height: 16),
            
            // Duration selection
            DropdownButtonFormField<TaskDuration>(
              initialValue: _selectedDuration,
              decoration: const InputDecoration(
                labelText: 'Duration',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: TaskDuration.values.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(duration.displayName),
                );
              }).toList(),
              onChanged: (TaskDuration? value) {
                setState(() {
                  _selectedDuration = value ?? TaskDuration.once;
                  if (_selectedDuration != TaskDuration.custom) {
                    _endDate = null;
                  }
                });
              },
            ),
            
            // End date picker for custom duration
            if (_selectedDuration == TaskDuration.custom) ...[
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _endDate != null 
                      ? 'End Date: ${_formatDate(_endDate!)}'
                      : 'Select End Date',
                ),
                leading: const Icon(Icons.event),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _endDate = picked;
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isNotEmpty) {
              if (_selectedDuration == TaskDuration.custom && _endDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select an end date for custom duration'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop(<String, dynamic>{
                'title': title,
                'description': _descController.text.trim(),
                'duration': _selectedDuration.value,
                'endDate': _endDate?.toIso8601String(),
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
