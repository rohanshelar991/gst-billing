import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<Map<String, dynamic>> _reminders = <Map<String, dynamic>>[
    <String, dynamic>{
      'date': '20 Feb',
      'title': 'GST Return Due',
      'type': 'GST',
      'status': 'Pending',
      'priority': 'High',
      'enabled': true,
      'message': 'Dear Client, your GST filing reminder is due on 20th Feb.',
    },
    <String, dynamic>{
      'date': '22 Feb',
      'title': 'Invoice Follow-up',
      'type': 'Invoice',
      'status': 'Scheduled',
      'priority': 'Medium',
      'enabled': true,
      'message': 'Dear Client, your invoice of ₹12,000 is due on 25th April.',
    },
    <String, dynamic>{
      'date': '25 Feb',
      'title': 'Advance Tax Payment',
      'type': 'Income Tax',
      'status': 'Pending',
      'priority': 'High',
      'enabled': false,
      'message': 'Income tax installment due this week.',
    },
    <String, dynamic>{
      'date': '28 Feb',
      'title': 'Client Renewal Alert',
      'type': 'Invoice',
      'status': 'Done',
      'priority': 'Low',
      'enabled': true,
      'message': 'Dear Client, service renewal discussion reminder.',
    },
  ];

  void _addReminder() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Reminder'),
          content: const Text(
            'New reminder form will be integrated here later.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'gst':
        return Colors.purple;
      case 'invoice':
        return Colors.blue;
      case 'income tax':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Smart reminder timeline with due status',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add),
                label: const Text('Add Reminder'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.sms_outlined),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Auto Reminder Preview\n“Dear Client, your invoice of ₹12,000 is due on 25th April.”',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _reminders.isEmpty
              ? _RemindersEmptyState(onAddReminder: _addReminder)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _reminders.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> reminder = _reminders[index];
                    final Color typeColor = _typeColor(
                      reminder['type'] as String,
                    );
                    final Color statusColor = _statusColor(
                      reminder['status'] as String,
                    );

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 54,
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: typeColor.withValues(alpha: 0.14),
                                  border: Border.all(
                                    color: typeColor.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    reminder['date'] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              if (index != _reminders.length - 1)
                                Container(
                                  width: 2,
                                  height: 84,
                                  color: Theme.of(context).dividerColor,
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          reminder['title'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.16,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          reminder['status'] as String,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(reminder['message'] as String),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(
                                            alpha: 0.14,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          reminder['type'] as String,
                                          style: TextStyle(
                                            color: typeColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${reminder['priority']} Priority'),
                                      const Spacer(),
                                      Switch(
                                        value: reminder['enabled'] as bool,
                                        onChanged: (bool value) {
                                          setState(() {
                                            reminder['enabled'] = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RemindersEmptyState extends StatelessWidget {
  const _RemindersEmptyState({required this.onAddReminder});

  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.timeline_outlined, size: 48),
              const SizedBox(height: 8),
              const Text('No reminders in timeline yet'),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: onAddReminder,
                icon: const Icon(Icons.add),
                label: const Text('Create Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
