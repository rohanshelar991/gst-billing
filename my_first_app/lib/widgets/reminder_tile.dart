import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.priority,
    required this.enabled,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final String type;
  final String priority;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  Color _typeColor() {
    switch (type.toLowerCase()) {
      case 'gst':
        return Colors.orange;
      case 'invoice':
        return primaryBlue;
      case 'income tax':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  Color _priorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color typeColor = _typeColor();
    final Color priorityColor = _priorityColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.alarm_outlined, color: typeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$priority Priority',
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}
