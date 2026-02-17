import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringInvoiceRecord {
  const RecurringInvoiceRecord({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.items,
    required this.frequency,
    required this.nextInvoiceDate,
    required this.autoGenerate,
    required this.isPaused,
    required this.createdAt,
    required this.updatedAt,
    required this.lastGeneratedAt,
  });

  final String id;
  final String clientId;
  final String clientName;
  final List<Map<String, dynamic>> items;
  final String frequency;
  final DateTime nextInvoiceDate;
  final bool autoGenerate;
  final bool isPaused;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastGeneratedAt;

  factory RecurringInvoiceRecord.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return RecurringInvoiceRecord(
      id: id,
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      items: ((map['items'] as List<dynamic>?) ?? <dynamic>[])
          .map(
            (dynamic item) =>
                (item as Map<Object?, Object?>).cast<String, dynamic>(),
          )
          .toList(),
      frequency: map['frequency'] as String? ?? 'monthly',
      nextInvoiceDate: _parseDate(map['nextInvoiceDate']),
      autoGenerate: map['autoGenerate'] as bool? ?? false,
      isPaused: map['isPaused'] as bool? ?? false,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      lastGeneratedAt: map['lastGeneratedAt'] == null
          ? null
          : _parseDate(map['lastGeneratedAt']),
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
