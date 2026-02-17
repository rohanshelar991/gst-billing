class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.product,
    required this.qty,
    required this.price,
  });

  final String id;
  final String product;
  final int qty;
  final double price;

  double get total => qty * price;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'product': product,
      'qty': qty,
      'price': price,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as String? ?? '',
      product: map['product'] as String? ?? '',
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.number,
    required this.client,
    required this.status,
    required this.date,
    required this.discountPercent,
    required this.gstType,
    required this.gstPercent,
    required this.timelineStep,
    required this.items,
    required this.tags,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String number;
  final String client;
  final String status;
  final DateTime date;
  final double discountPercent;
  final String gstType;
  final double gstPercent;
  final int timelineStep;
  final List<InvoiceItem> items;
  final List<String> tags;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get subtotal {
    double value = 0;
    for (final InvoiceItem item in items) {
      value += item.total;
    }
    return value;
  }

  double get discountAmount => subtotal * (discountPercent / 100);

  double get taxableAmount => subtotal - discountAmount;

  double get gstAmount => taxableAmount * (gstPercent / 100);

  double get totalAmount => taxableAmount + gstAmount;

  double get cgstAmount => gstType == 'CGST+SGST' ? gstAmount / 2 : 0;

  double get sgstAmount => gstType == 'CGST+SGST' ? gstAmount / 2 : 0;

  double get igstAmount => gstType == 'IGST' ? gstAmount : 0;

  InvoiceRecord copyWith({
    String? id,
    String? number,
    String? client,
    String? status,
    DateTime? date,
    double? discountPercent,
    String? gstType,
    double? gstPercent,
    int? timelineStep,
    List<InvoiceItem>? items,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceRecord(
      id: id ?? this.id,
      number: number ?? this.number,
      client: client ?? this.client,
      status: status ?? this.status,
      date: date ?? this.date,
      discountPercent: discountPercent ?? this.discountPercent,
      gstType: gstType ?? this.gstType,
      gstPercent: gstPercent ?? this.gstPercent,
      timelineStep: timelineStep ?? this.timelineStep,
      items: items ?? this.items,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'number': number,
      'client': client,
      'status': status,
      'date': date.toIso8601String(),
      'discountPercent': discountPercent,
      'gstType': gstType,
      'gstPercent': gstPercent,
      'timelineStep': timelineStep,
      'items': items.map((InvoiceItem item) => item.toMap()).toList(),
      'tags': tags,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InvoiceRecord.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final List<dynamic> rawItems =
        map['items'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawTags = map['tags'] as List<dynamic>? ?? <dynamic>[];

    return InvoiceRecord(
      id: id,
      number: map['number'] as String? ?? '',
      client: map['client'] as String? ?? '',
      status: map['status'] as String? ?? 'Pending',
      date: _readDate(map['date']),
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
      gstType: map['gstType'] as String? ?? 'CGST+SGST',
      gstPercent: (map['gstPercent'] as num?)?.toDouble() ?? 0,
      timelineStep: (map['timelineStep'] as num?)?.toInt() ?? 0,
      items: rawItems
          .map(
            (dynamic item) =>
                InvoiceItem.fromMap((item as Map<Object?, Object?>).cast()),
          )
          .toList(),
      tags: rawTags.map((dynamic tag) => '$tag').toList(),
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

  static List<InvoiceRecord> seed() {
    return <InvoiceRecord>[
      InvoiceRecord(
        id: 'inv_2031',
        number: 'INV-2031',
        client: 'Apex Interiors',
        status: 'Pending',
        date: DateTime(2026, 2, 12),
        discountPercent: 5,
        gstType: 'CGST+SGST',
        gstPercent: 12,
        timelineStep: 2,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item_1',
            product: 'Office Chair',
            qty: 10,
            price: 2200,
          ),
          InvoiceItem(id: 'item_2', product: 'Desk Unit', qty: 5, price: 5400),
        ],
        tags: const <String>['retainer', 'priority'],
        notes: 'Send payment reminder if not cleared by Friday.',
        createdAt: DateTime(2026, 2, 10),
        updatedAt: DateTime(2026, 2, 12),
      ),
      InvoiceRecord(
        id: 'inv_2030',
        number: 'INV-2030',
        client: 'Urban Pulse Media',
        status: 'Paid',
        date: DateTime(2026, 2, 10),
        discountPercent: 2.5,
        gstType: 'IGST',
        gstPercent: 18,
        timelineStep: 3,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item_1',
            product: 'Campaign Design',
            qty: 1,
            price: 30000,
          ),
          InvoiceItem(
            id: 'item_2',
            product: 'Ad Placement',
            qty: 2,
            price: 7600,
          ),
        ],
        tags: const <String>['marketing'],
        notes: 'Paid via bank transfer.',
        createdAt: DateTime(2026, 2, 8),
        updatedAt: DateTime(2026, 2, 10),
      ),
      InvoiceRecord(
        id: 'inv_2029',
        number: 'INV-2029',
        client: 'Nova Fabricators',
        status: 'Overdue',
        date: DateTime(2026, 2, 4),
        discountPercent: 0,
        gstType: 'CGST+SGST',
        gstPercent: 12,
        timelineStep: 1,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item_1',
            product: 'Steel Sheet',
            qty: 30,
            price: 450,
          ),
          InvoiceItem(
            id: 'item_2',
            product: 'Welding Kit',
            qty: 5,
            price: 1250,
          ),
        ],
        tags: const <String>['followup'],
        notes: 'Escalate to finance contact.',
        createdAt: DateTime(2026, 2, 2),
        updatedAt: DateTime(2026, 2, 4),
      ),
      InvoiceRecord(
        id: 'inv_2028',
        number: 'INV-2028',
        client: 'Skyline Traders',
        status: 'Pending',
        date: DateTime(2026, 1, 28),
        discountPercent: 4,
        gstType: 'No GST',
        gstPercent: 0,
        timelineStep: 1,
        items: const <InvoiceItem>[
          InvoiceItem(
            id: 'item_1',
            product: 'Packaging Box',
            qty: 120,
            price: 80,
          ),
        ],
        tags: const <String>['bulk-order'],
        notes: 'Awaiting confirmation from procurement team.',
        createdAt: DateTime(2026, 1, 25),
        updatedAt: DateTime(2026, 1, 28),
      ),
    ];
  }
}
