class ClientRecord {
  const ClientRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
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

  static List<ClientRecord> seed() {
    return <ClientRecord>[
      ClientRecord(
        id: 'client_1',
        name: 'Apex Interiors',
        email: 'finance@apexinteriors.com',
        phone: '+91 98200 12345',
        pendingAmount: 27500,
        invoices: 14,
        isActive: true,
        segment: 'Corporate',
        creditLimit: 300000,
        usedCredit: 157000,
        history: const <String>['INV-2031', 'INV-2022', 'INV-2018'],
        address: 'Bandra West, Mumbai',
        notes: 'High-value client. Weekly follow-up preferred.',
        createdAt: DateTime(2025, 12, 4),
        updatedAt: DateTime(2026, 2, 12),
      ),
      ClientRecord(
        id: 'client_2',
        name: 'Urban Pulse Media',
        email: 'accounts@urbanpulse.media',
        phone: '+91 97665 30303',
        pendingAmount: 0,
        invoices: 8,
        isActive: true,
        segment: 'Retail',
        creditLimit: 150000,
        usedCredit: 38000,
        history: const <String>['INV-2030', 'INV-2024', 'INV-2017'],
        address: 'Koregaon Park, Pune',
        notes: 'Prefers WhatsApp reminders.',
        createdAt: DateTime(2025, 11, 18),
        updatedAt: DateTime(2026, 2, 10),
      ),
      ClientRecord(
        id: 'client_3',
        name: 'Nova Fabricators',
        email: 'office@novafab.in',
        phone: '+91 99871 55667',
        pendingAmount: 18750,
        invoices: 11,
        isActive: false,
        segment: 'Wholesale',
        creditLimit: 220000,
        usedCredit: 198000,
        history: const <String>['INV-2029', 'INV-2020', 'INV-2015'],
        address: 'MIDC, Nashik',
        notes: 'Needs tighter credit control.',
        createdAt: DateTime(2025, 10, 30),
        updatedAt: DateTime(2026, 2, 4),
      ),
    ];
  }
}
