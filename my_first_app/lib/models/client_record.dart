import 'package:cloud_firestore/cloud_firestore.dart';

class ClientRecord {
  const ClientRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.gstin,
    required this.pendingAmount,
    required this.invoices,
    required this.isActive,
    required this.segment,
    required this.creditLimit,
    required this.usedCredit,
    required this.history,
    required this.address,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String gstin;
  final double pendingAmount;
  final int invoices;
  final bool isActive;
  final String segment;
  final double creditLimit;
  final double usedCredit;
  final List<String> history;
  final String address;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get availableCredit =>
      (creditLimit - usedCredit).clamp(0, creditLimit);

  double get creditUsageRatio =>
      creditLimit == 0 ? 0 : (usedCredit / creditLimit).clamp(0.0, 1.0);

  ClientRecord copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? gstin,
    double? pendingAmount,
    int? invoices,
    bool? isActive,
    String? segment,
    double? creditLimit,
    double? usedCredit,
    List<String>? history,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      invoices: invoices ?? this.invoices,
      isActive: isActive ?? this.isActive,
      segment: segment ?? this.segment,
      creditLimit: creditLimit ?? this.creditLimit,
      usedCredit: usedCredit ?? this.usedCredit,
      history: history ?? this.history,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'gstin': gstin,
      'pendingAmount': pendingAmount,
      'invoices': invoices,
      'isActive': isActive,
      'segment': segment,
      'creditLimit': creditLimit,
      'usedCredit': usedCredit,
      'history': history,
      'address': address,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClientRecord.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final List<dynamic> rawHistory =
        map['history'] as List<dynamic>? ?? <dynamic>[];

    return ClientRecord(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      gstin: map['gstin'] as String? ?? '',
      pendingAmount: (map['pendingAmount'] as num?)?.toDouble() ?? 0,
      invoices: (map['invoices'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      segment: map['segment'] as String? ?? 'All',
      creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0,
      usedCredit: (map['usedCredit'] as num?)?.toDouble() ?? 0,
      history: rawHistory.map((dynamic value) => '$value').toList(),
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
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
