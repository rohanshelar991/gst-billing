import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice_record.dart';
import '../models/reminder_record.dart';
import '../services/firestore_service.dart';

class CalendarDueScreen extends StatefulWidget {
  const CalendarDueScreen({super.key});

  @override
  State<CalendarDueScreen> createState() => _CalendarDueScreenState();
}

class _CalendarDueScreenState extends State<CalendarDueScreen> {
  final DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestore = context.read<FirestoreService?>();
    if (firestore == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendar & Due Management')),
        body: const Center(child: Text('Calendar service unavailable.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar & Due Management')),
      body: StreamBuilder<List<InvoiceRecord>>(
        stream: firestore.streamInvoices(),
        builder: (BuildContext context, AsyncSnapshot<List<InvoiceRecord>> invoiceSnapshot) {
          return StreamBuilder<List<ReminderRecord>>(
            stream: firestore.streamReminders(),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<ReminderRecord>> reminderSnapshot,
                ) {
                  final List<InvoiceRecord> invoices =
                      invoiceSnapshot.data ?? <InvoiceRecord>[];
                  final List<ReminderRecord> reminders =
                      reminderSnapshot.data ?? <ReminderRecord>[];
                  final Map<int, List<_DueEvent>> events = _buildEvents(
                    invoices: invoices,
                    reminders: reminders,
                  );
                  final List<_DueEvent> selectedEvents =
                      events[_selectedDay] ?? <_DueEvent>[];
                  final int daysInMonth = DateUtils.getDaysInMonth(
                    _month.year,
                    _month.month,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  '${_month.month}/${_month.year}',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: daysInMonth,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        mainAxisSpacing: 6,
                                        crossAxisSpacing: 6,
                                      ),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final int day = index + 1;
                                        final bool selected =
                                            day == _selectedDay;
                                        final List<_DueEvent> dayEvents =
                                            events[day] ?? <_DueEvent>[];

                                        return InkWell(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedDay = day;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: selected
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.16)
                                                  : null,
                                              border: Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).dividerColor,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text(
                                                  '$day',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (dayEvents.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 2,
                                                        ),
                                                    child: Wrap(
                                                      spacing: 2,
                                                      children: dayEvents.map((
                                                        _DueEvent event,
                                                      ) {
                                                        return Container(
                                                          width: 5,
                                                          height: 5,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color:
                                                                    _eventColor(
                                                                      event
                                                                          .type,
                                                                    ),
                                                              ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            _legendDot('Invoice Due', Colors.red),
                            const SizedBox(width: 8),
                            _legendDot('Reminder', Colors.purple),
                            const SizedBox(width: 8),
                            _legendDot('Tax', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Due items for $_selectedDay/${_month.month}/${_month.year}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (selectedEvents.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: const <Widget>[
                                  Icon(Icons.event_available_outlined),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No due items on selected date.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final _DueEvent event in selectedEvents)
                            Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _eventColor(
                                    event.type,
                                  ).withValues(alpha: 0.16),
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: _eventColor(event.type),
                                  ),
                                ),
                                title: Text(event.title),
                                subtitle: Text(event.type),
                              ),
                            ),
                      ],
                    ),
                  );
                },
          );
        },
      ),
    );
  }

  Map<int, List<_DueEvent>> _buildEvents({
    required List<InvoiceRecord> invoices,
    required List<ReminderRecord> reminders,
  }) {
    final Map<int, List<_DueEvent>> events = <int, List<_DueEvent>>{};
    for (final InvoiceRecord invoice in invoices) {
      if (invoice.dueDate.year != _month.year ||
          invoice.dueDate.month != _month.month) {
        continue;
      }
      events
          .putIfAbsent(invoice.dueDate.day, () => <_DueEvent>[])
          .add(
            _DueEvent(
              type: 'Invoice Due',
              title: '${invoice.number} • ${invoice.client}',
            ),
          );
    }
    for (final ReminderRecord reminder in reminders) {
      if (reminder.dueDate.year != _month.year ||
          reminder.dueDate.month != _month.month) {
        continue;
      }
      events
          .putIfAbsent(reminder.dueDate.day, () => <_DueEvent>[])
          .add(_DueEvent(type: reminder.type, title: reminder.title));
    }
    return events;
  }

  Color _eventColor(String type) {
    switch (type.toLowerCase()) {
      case 'invoice due':
      case 'invoice':
        return Colors.red;
      case 'gst':
      case 'reminder':
        return Colors.purple;
      case 'income tax':
      case 'tax':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _legendDot(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _DueEvent {
  const _DueEvent({required this.type, required this.title});

  final String type;
  final String title;
}
