import 'package:flutter/material.dart';

class CalendarDueScreen extends StatefulWidget {
  const CalendarDueScreen({super.key});

  @override
  State<CalendarDueScreen> createState() => _CalendarDueScreenState();
}

class _CalendarDueScreenState extends State<CalendarDueScreen> {
  final DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;

  final Map<int, List<Map<String, String>>> _events =
      <int, List<Map<String, String>>>{
        5: <Map<String, String>>[
          <String, String>{
            'type': 'Invoice Due',
            'title': 'INV-2031 Payment Follow-up',
          },
        ],
        11: <Map<String, String>>[
          <String, String>{'type': 'GST Due', 'title': 'GSTR-1 Filing'},
        ],
        18: <Map<String, String>>[
          <String, String>{
            'type': 'Tax Filing',
            'title': 'Advance Tax Submission',
          },
        ],
        25: <Map<String, String>>[
          <String, String>{'type': 'Invoice Due', 'title': 'INV-2035 Due Date'},
          <String, String>{'type': 'GST Due', 'title': 'GSTR-3B Due'},
        ],
      };

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final List<Map<String, String>> selectedEvents =
        _events[_selectedDay] ?? <Map<String, String>>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar & Due Management')),
      body: SingleChildScrollView(
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                      itemBuilder: (BuildContext context, int index) {
                        final int day = index + 1;
                        final bool selected = day == _selectedDay;
                        final List<Map<String, String>> dayEvents =
                            _events[day] ?? <Map<String, String>>[];

                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _selectedDay = day;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.16)
                                  : null,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Wrap(
                                      spacing: 2,
                                      children: dayEvents.map((
                                        Map<String, String> event,
                                      ) {
                                        return Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _eventColor(event['type']!),
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
                _legendDot('GST Due', Colors.purple),
                const SizedBox(width: 8),
                _legendDot('Tax Filing', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Due items for $_selectedDay/${_month.month}/${_month.year}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                      Expanded(child: Text('No due items on selected date.')),
                    ],
                  ),
                ),
              )
            else
              for (final Map<String, String> event in selectedEvents)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _eventColor(
                        event['type']!,
                      ).withValues(alpha: 0.16),
                      child: Icon(
                        Icons.calendar_today,
                        color: _eventColor(event['type']!),
                      ),
                    ),
                    title: Text(event['title']!),
                    subtitle: Text(event['type']!),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'Invoice Due':
        return Colors.red;
      case 'GST Due':
        return Colors.purple;
      case 'Tax Filing':
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
