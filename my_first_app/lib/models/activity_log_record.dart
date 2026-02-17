import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogRecord {
  const ActivityLogRecord({
    required this.id,
    required this.companyId,
    required this.action,
    required this.metadata,
    required this.timestamp,
  });

  final String id;
  final String companyId;
  final String action;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  factory ActivityLogRecord.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return ActivityLogRecord(
      id: id,
      companyId: map['companyId'] as String? ?? '',
      action: map['action'] as String? ?? 'activity',
      metadata:
          ((map['metadata'] as Map<Object?, Object?>?) ?? <Object?, Object?>{})
              .cast<String, dynamic>(),
      timestamp: _parseDate(map['timestamp']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
