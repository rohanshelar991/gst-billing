import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder_record.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<String> _filters = <String>['All', 'Pending', 'Scheduled', 'Done'];
  String _selectedFilter = 'All';

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

  String _dateLabel(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openAddReminderSheet() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController invoiceIdController = TextEditingController(
      text: 'invoice_manual',
    );
    final TextEditingController clientIdController = TextEditingController(
      text: 'client_manual',
    );
    final TextEditingController clientNameController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    String status = 'Scheduled';
    String type = 'Invoice';
    String priority = 'Medium';
    String channel = 'WhatsApp';
    bool enabled = true;
    DateTime dueDate = DateTime.now().add(const Duration(days: 2));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
                return Container(
                  margin: const EdgeInsets.only(top: 22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 42,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).dividerColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Create Reminder',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saved in users/{uid}/reminders',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                prefixIcon: Icon(Icons.alarm_add_outlined),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextFormField(
                                    controller: invoiceIdController,
                                    decoration: const InputDecoration(
                                      labelText: 'Invoice ID',
                                      prefixIcon: Icon(
                                        Icons.receipt_long_outlined,
                                      ),
                                    ),
                                    validator: (String? value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter invoice ID';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: clientIdController,
                                    decoration: const InputDecoration(
                                      labelText: 'Client ID',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                    validator: (String? value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter client ID';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: clientNameController,
                              decoration: const InputDecoration(
                                labelText: 'Client Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: status,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      prefixIcon: Icon(Icons.flag_outlined),
                                    ),
                                    items: const <DropdownMenuItem<String>>[
                                      DropdownMenuItem<String>(
                                        value: 'Pending',
                                        child: Text('Pending'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Scheduled',
                                        child: Text('Scheduled'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Done',
                                        child: Text('Done'),
                                      ),
                                    ],
                                    onChanged: (String? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setModalState(() {
                                        status = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: type,
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),
                                    items: const <DropdownMenuItem<String>>[
                                      DropdownMenuItem<String>(
                                        value: 'Invoice',
                                        child: Text('Invoice'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'GST',
                                        child: Text('GST'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Income Tax',
                                        child: Text('Income Tax'),
                                      ),
                                    ],
                                    onChanged: (String? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setModalState(() {
                                        type = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: priority,
                                    decoration: const InputDecoration(
                                      labelText: 'Priority',
                                      prefixIcon: Icon(
                                        Icons.priority_high_outlined,
                                      ),
                                    ),
                                    items: const <DropdownMenuItem<String>>[
                                      DropdownMenuItem<String>(
                                        value: 'High',
                                        child: Text('High'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Medium',
                                        child: Text('Medium'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Low',
                                        child: Text('Low'),
                                      ),
                                    ],
                                    onChanged: (String? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setModalState(() {
                                        priority = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: channel,
                                    decoration: const InputDecoration(
                                      labelText: 'Channel',
                                      prefixIcon: Icon(Icons.campaign_outlined),
                                    ),
                                    items: const <DropdownMenuItem<String>>[
                                      DropdownMenuItem<String>(
                                        value: 'WhatsApp',
                                        child: Text('WhatsApp'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'SMS',
                                        child: Text('SMS'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Email',
                                        child: Text('Email'),
                                      ),
                                    ],
                                    onChanged: (String? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setModalState(() {
                                        channel = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                      context: context,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 1),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                      initialDate: dueDate,
                                    );
                                if (pickedDate == null) {
                                  return;
                                }
                                setModalState(() {
                                  dueDate = pickedDate;
                                });
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Due Date',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                                child: Text(_dateLabel(dueDate)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: messageController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Message',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.message_outlined),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter message';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: enabled,
                              onChanged: (bool value) {
                                setModalState(() {
                                  enabled = value;
                                });
                              },
                              title: const Text('Enable reminder'),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final FirestoreService firestoreService =
                                      context.read<FirestoreService>();
                                  final AnalyticsService analyticsService =
                                      context.read<AnalyticsService>();
                                  final NavigatorState navigator = Navigator.of(
                                    context,
                                  );
                                  try {
                                    await firestoreService.addReminder(
                                      invoiceId: invoiceIdController.text
                                          .trim(),
                                      clientId: clientIdController.text.trim(),
                                      dueDate: dueDate,
                                      status: status,
                                      reminderSent: false,
                                      title: titleController.text.trim(),
                                      type: type,
                                      priority: priority,
                                      enabled: enabled,
                                      message: messageController.text.trim(),
                                      channel: channel,
                                      clientName: clientNameController.text
                                          .trim(),
                                    );
                                    await analyticsService.logEvent(
                                      'create_reminder',
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    navigator.pop();
                                    _showMessage(
                                      'Reminder saved to Firestore.',
                                    );
                                  } catch (error) {
                                    _showMessage(
                                      'Could not save reminder: $error',
                                    );
                                  }
                                },
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Save Reminder'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
        );
      },
    );
  }

  void _showPayload(List<ReminderRecord> reminders) {
    final String payload = const JsonEncoder.withIndent('  ').convert(
      reminders
          .map(
            (ReminderRecord reminder) => <String, dynamic>{
              'id': reminder.id,
              ...reminder.toMap(),
            },
          )
          .toList(),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Reminders Firebase Payload',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          payload,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestoreService = context
        .read<FirestoreService?>();
    return StreamBuilder<List<ReminderRecord>>(
      stream:
          firestoreService?.streamReminders() ??
          Stream<List<ReminderRecord>>.value(const <ReminderRecord>[]),
      builder: (BuildContext context, AsyncSnapshot<List<ReminderRecord>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load reminders: ${snapshot.error}'),
            ),
          );
        }

        final List<ReminderRecord> reminders =
            snapshot.data ?? <ReminderRecord>[];
        final List<ReminderRecord> filtered =
            reminders.where((ReminderRecord reminder) {
              return _selectedFilter == 'All' ||
                  reminder.status == _selectedFilter;
            }).toList()..sort((ReminderRecord a, ReminderRecord b) {
              return a.dueDate.compareTo(b.dueDate);
            });

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF059669), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Reminders (Realtime)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _openAddReminderSheet,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(child: _metric('Count', '${filtered.length}')),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metric(
                            'Enabled',
                            '${filtered.where((ReminderRecord r) => r.enabled).length}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: filtered.isEmpty
                            ? null
                            : () => _showPayload(filtered),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: const Text('Payload'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Smart reminder timeline with due status',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((String filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _RemindersEmptyState(onAddReminder: _openAddReminderSheet)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ReminderRecord reminder = filtered[index];
                        final Color typeColor = _typeColor(reminder.type);
                        final Color statusColor = _statusColor(reminder.status);

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
                                        color: typeColor.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _dateLabel(reminder.dueDate),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index != filtered.length - 1)
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              reminder.title,
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              reminder.status,
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
                                      Text(reminder.message),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: <Widget>[
                                          _badge(reminder.type, typeColor),
                                          _badge(
                                            '${reminder.priority} Priority',
                                            reminder.priority.toLowerCase() ==
                                                    'high'
                                                ? Colors.red
                                                : reminder.priority
                                                          .toLowerCase() ==
                                                      'medium'
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                          _badge(reminder.channel, Colors.teal),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: <Widget>[
                                          Text(
                                            reminder.enabled
                                                ? 'Enabled'
                                                : 'Disabled',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          const Spacer(),
                                          Switch(
                                            value: reminder.enabled,
                                            onChanged: (bool value) async {
                                              final FirestoreService
                                              firestoreService = context
                                                  .read<FirestoreService>();
                                              final AnalyticsService
                                              analyticsService = context
                                                  .read<AnalyticsService>();
                                              try {
                                                await firestoreService
                                                    .updateReminderEnabled(
                                                      reminderId: reminder.id,
                                                      enabled: value,
                                                    );
                                                await analyticsService.logEvent(
                                                  'toggle_reminder',
                                                );
                                              } catch (error) {
                                                _showMessage(
                                                  'Could not update reminder: $error',
                                                );
                                              }
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
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
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
