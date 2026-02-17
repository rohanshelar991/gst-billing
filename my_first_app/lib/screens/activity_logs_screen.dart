import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity_log_record.dart';
import '../services/firestore_service.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  final List<String> _filters = <String>[
    'All',
    'Billing',
    'Clients',
    'Products',
    'Reminders',
    'Company',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(ActivityLogRecord item) {
    final String action = item.action.toLowerCase();
    switch (_filter) {
      case 'Billing':
        return action.contains('invoice') ||
            action.contains('payment') ||
            action.contains('recurring');
      case 'Clients':
        return action.contains('client');
      case 'Products':
        return action.contains('product');
      case 'Reminders':
        return action.contains('reminder');
      case 'Company':
        return action.contains('company') || action.contains('profile');
      case 'All':
      default:
        return true;
    }
  }

  IconData _iconForAction(String action) {
    final String value = action.toLowerCase();
    if (value.contains('invoice')) {
      return Icons.receipt_long_outlined;
    }
    if (value.contains('payment')) {
      return Icons.payments_outlined;
    }
    if (value.contains('client')) {
      return Icons.people_outline;
    }
    if (value.contains('product')) {
      return Icons.inventory_2_outlined;
    }
    if (value.contains('reminder')) {
      return Icons.notifications_active_outlined;
    }
    if (value.contains('company') || value.contains('profile')) {
      return Icons.business_outlined;
    }
    return Icons.bolt_outlined;
  }

  String _labelForAction(String action) {
    return action
        .split('_')
        .where((String value) => value.trim().isNotEmpty)
        .map((String part) {
          final String value = part.trim().toLowerCase();
          return value.substring(0, 1).toUpperCase() + value.substring(1);
        })
        .join(' ');
  }

  String _timeAgo(DateTime value) {
    final Duration diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) {
      return 'just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays}d ago';
    }
    final int months = (diff.inDays / 30).floor();
    return '${months}mo ago';
  }

  String _metadataPreview(Map<String, dynamic> metadata) {
    if (metadata.isEmpty) {
      return 'No metadata';
    }
    final List<String> parts = <String>[];
    metadata.forEach((String key, dynamic value) {
      if (parts.length >= 2) {
        return;
      }
      final String cleanKey = key.trim();
      final String cleanValue = '$value'.trim();
      if (cleanKey.isEmpty || cleanValue.isEmpty) {
        return;
      }
      parts.add('$cleanKey: $cleanValue');
    });
    if (parts.isEmpty) {
      return 'Metadata available';
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestore = context.read<FirestoreService?>();
    if (firestore == null) {
      return const Scaffold(
        body: Center(child: Text('Activity log service unavailable.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search activity action or metadata',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((String value) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value),
                      selected: _filter == value,
                      onSelected: (_) {
                        setState(() {
                          _filter = value;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ActivityLogRecord>>(
              stream: firestore.streamActivityLogs(limit: 180),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<ActivityLogRecord>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Failed to load activity logs: ${snapshot.error}',
                          ),
                        ),
                      );
                    }
                    final String query = _searchController.text
                        .trim()
                        .toLowerCase();
                    final List<ActivityLogRecord> logs =
                        snapshot.data ?? <ActivityLogRecord>[];
                    final List<ActivityLogRecord> filtered = logs.where((
                      ActivityLogRecord item,
                    ) {
                      if (!_matchesFilter(item)) {
                        return false;
                      }
                      if (query.isEmpty) {
                        return true;
                      }
                      return item.action.toLowerCase().contains(query) ||
                          item.metadata.values.any(
                            (dynamic value) =>
                                '$value'.toLowerCase().contains(query),
                          );
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No activity found for selected filter.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ActivityLogRecord item = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                _iconForAction(item.action),
                                size: 18,
                              ),
                            ),
                            title: Text(
                              _labelForAction(item.action),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(_metadataPreview(item.metadata)),
                            trailing: Text(
                              _timeAgo(item.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            isThreeLine: false,
                          ),
                        );
                      },
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }
}
