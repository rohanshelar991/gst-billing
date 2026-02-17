class ReminderRecord {
  const ReminderRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.priority,
    required this.enabled,
    required this.message,
    required this.dueDate,
    required this.channel,
    required this.clientName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String type;
  final String status;
  final String priority;
  final bool enabled;
  final String message;
  final DateTime dueDate;
  final String channel;
  final String clientName;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderRecord copyWith({
    String? id,
    String? title,
    String? type,
    String? status,
    String? priority,
    bool? enabled,
    String? message,
    DateTime? dueDate,
    String? channel,
    String? clientName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      message: message ?? this.message,
      dueDate: dueDate ?? this.dueDate,
      channel: channel ?? this.channel,
      clientName: clientName ?? this.clientName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'type': type,
      'status': status,
      'priority': priority,
      'enabled': enabled,
      'message': message,
      'dueDate': dueDate.toIso8601String(),
      'channel': channel,
      'clientName': clientName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReminderRecord.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return ReminderRecord(
      id: id,
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'General',
      status: map['status'] as String? ?? 'Pending',
      priority: map['priority'] as String? ?? 'Low',
      enabled: map['enabled'] as bool? ?? true,
      message: map['message'] as String? ?? '',
      dueDate: _readDate(map['dueDate']),
      channel: map['channel'] as String? ?? 'SMS',
      clientName: map['clientName'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
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

  static List<ReminderRecord> seed() {
    return <ReminderRecord>[
      ReminderRecord(
        id: 'rem_1',
        title: 'GST Return Due',
        type: 'GST',
        status: 'Pending',
        priority: 'High',
        enabled: true,
        message: 'Dear Client, your GST filing reminder is due on 20th Feb.',
        dueDate: DateTime(2026, 2, 20),
        channel: 'SMS',
        clientName: 'Apex Interiors',
        createdAt: DateTime(2026, 2, 15),
        updatedAt: DateTime(2026, 2, 16),
      ),
      ReminderRecord(
        id: 'rem_2',
        title: 'Invoice Follow-up',
        type: 'Invoice',
        status: 'Scheduled',
        priority: 'Medium',
        enabled: true,
        message: 'Dear Client, your invoice of ₹12,000 is due on 25th April.',
        dueDate: DateTime(2026, 2, 22),
        channel: 'WhatsApp',
        clientName: 'Urban Pulse Media',
        createdAt: DateTime(2026, 2, 16),
        updatedAt: DateTime(2026, 2, 16),
      ),
      ReminderRecord(
        id: 'rem_3',
        title: 'Advance Tax Payment',
        type: 'Income Tax',
        status: 'Pending',
        priority: 'High',
        enabled: false,
        message: 'Income tax installment due this week.',
        dueDate: DateTime(2026, 2, 25),
        channel: 'Email',
        clientName: 'Nova Fabricators',
        createdAt: DateTime(2026, 2, 12),
        updatedAt: DateTime(2026, 2, 15),
      ),
      ReminderRecord(
        id: 'rem_4',
        title: 'Client Renewal Alert',
        type: 'Invoice',
        status: 'Done',
        priority: 'Low',
        enabled: true,
        message: 'Dear Client, service renewal discussion reminder.',
        dueDate: DateTime(2026, 2, 28),
        channel: 'Call',
        clientName: 'Skyline Traders',
        createdAt: DateTime(2026, 2, 9),
        updatedAt: DateTime(2026, 2, 14),
      ),
    ];
  }
}
