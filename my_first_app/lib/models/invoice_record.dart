import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

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
      id: map['id'] as String? ?? map['productId'] as String? ?? '',
      product: map['product'] as String? ?? map['name'] as String? ?? '',
      qty:
          (map['qty'] as num?)?.toInt() ??
          (map['quantity'] as num?)?.toInt() ??
          0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.clientId,
    required this.number,
    required this.client,
    required this.status,
    required this.date,
    required this.dueDate,
    required this.discountPercent,
    required this.gstType,
    required this.gstPercent,
    required this.timelineStep,
    required this.items,
    required this.tags,
    required this.notes,
    required this.subtotalAmount,
    required this.gstAmountValue,
    required this.totalAmountValue,
    required this.paidAmount,
    required this.balanceAmount,
    required this.cgstAmountValue,
    required this.sgstAmountValue,
    required this.igstAmountValue,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String number;
  final String client;
  final String status;
  final DateTime date;
  final DateTime dueDate;
  final double discountPercent;
  final String gstType;
  final double gstPercent;
  final int timelineStep;
  final List<InvoiceItem> items;
  final List<String> tags;
  final String notes;
  final double subtotalAmount;
  final double gstAmountValue;
  final double totalAmountValue;
  final double paidAmount;
  final double balanceAmount;
  final double cgstAmountValue;
  final double sgstAmountValue;
  final double igstAmountValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get subtotal {
    if (subtotalAmount > 0) {
      return subtotalAmount;
    }
    double value = 0;
    for (final InvoiceItem item in items) {
      value += item.total;
    }
    return value;
  }

  double get discountAmount => subtotal * (discountPercent / 100);

  double get taxableAmount => subtotal - discountAmount;

  double get gstAmount {
    if (gstAmountValue > 0) {
      return gstAmountValue;
    }
    final double taxFromBreakdown =
        cgstAmountValue + sgstAmountValue + igstAmountValue;
    if (taxFromBreakdown > 0) {
      return taxFromBreakdown;
    }
    return taxableAmount * (gstPercent / 100);
  }

  double get totalAmount {
    if (totalAmountValue > 0) {
      return totalAmountValue;
    }
    return taxableAmount + gstAmount;
  }

  double get cgstAmount {
    if (cgstAmountValue > 0 || sgstAmountValue > 0 || igstAmountValue > 0) {
      return cgstAmountValue;
    }
    return gstType == 'CGST+SGST' ? gstAmount / 2 : 0;
  }

  double get sgstAmount {
    if (cgstAmountValue > 0 || sgstAmountValue > 0 || igstAmountValue > 0) {
      return sgstAmountValue;
    }
    return gstType == 'CGST+SGST' ? gstAmount / 2 : 0;
  }

  double get igstAmount {
    if (cgstAmountValue > 0 || sgstAmountValue > 0 || igstAmountValue > 0) {
      return igstAmountValue;
    }
    return gstType == 'IGST' ? gstAmount : 0;
  }

  InvoiceRecord copyWith({
    String? id,
    String? clientId,
    String? number,
    String? client,
    String? status,
    DateTime? date,
    DateTime? dueDate,
    double? discountPercent,
    String? gstType,
    double? gstPercent,
    int? timelineStep,
    List<InvoiceItem>? items,
    List<String>? tags,
    String? notes,
    double? subtotalAmount,
    double? gstAmountValue,
    double? totalAmountValue,
    double? paidAmount,
    double? balanceAmount,
    double? cgstAmountValue,
    double? sgstAmountValue,
    double? igstAmountValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceRecord(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      number: number ?? this.number,
      client: client ?? this.client,
      status: status ?? this.status,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      discountPercent: discountPercent ?? this.discountPercent,
      gstType: gstType ?? this.gstType,
      gstPercent: gstPercent ?? this.gstPercent,
      timelineStep: timelineStep ?? this.timelineStep,
      items: items ?? this.items,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      gstAmountValue: gstAmountValue ?? this.gstAmountValue,
      totalAmountValue: totalAmountValue ?? this.totalAmountValue,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      cgstAmountValue: cgstAmountValue ?? this.cgstAmountValue,
      sgstAmountValue: sgstAmountValue ?? this.sgstAmountValue,
      igstAmountValue: igstAmountValue ?? this.igstAmountValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'clientId': clientId,
      'number': number,
      'client': client,
      'status': status,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'discountPercent': discountPercent,
      'gstType': gstType,
      'gstPercent': gstPercent,
      'timelineStep': timelineStep,
      'items': items.map((InvoiceItem item) => item.toMap()).toList(),
      'tags': tags,
      'notes': notes,
      'subtotal': subtotal,
      'totalGST': gstAmount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'taxBreakdown': <String, dynamic>{
        'cgst': cgstAmount,
        'sgst': sgstAmount,
        'igst': igstAmount,
        'totalTax': gstAmount,
      },
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
    final Map<Object?, Object?> rawTaxBreakdown =
        (map['taxBreakdown'] as Map<Object?, Object?>?) ??
        const <Object?, Object?>{};
    final double subtotal = (map['subtotal'] as num?)?.toDouble() ?? 0;
    final double totalGST = (map['totalGST'] as num?)?.toDouble() ?? 0;
    final double totalAmount = (map['totalAmount'] as num?)?.toDouble() ?? 0;
    final double paidAmount = (map['paidAmount'] as num?)?.toDouble() ?? 0;
    final double balanceAmount =
        (map['balanceAmount'] as num?)?.toDouble() ?? 0;
    final double cgst = (rawTaxBreakdown['cgst'] as num?)?.toDouble() ?? 0;
    final double sgst = (rawTaxBreakdown['sgst'] as num?)?.toDouble() ?? 0;
    final double igst = (rawTaxBreakdown['igst'] as num?)?.toDouble() ?? 0;
    final String gstType =
        map['gstType'] as String? ??
        (igst > 0 ? 'IGST' : (totalGST > 0 ? 'CGST+SGST' : 'No GST'));
    final String status =
        map['status'] as String? ??
        map['paymentStatus'] as String? ??
        'Pending';
    final double computedTotalAmount = totalAmount > 0
        ? totalAmount
        : subtotal + totalGST;
    final double computedPaidAmount = paidAmount > 0
        ? paidAmount
        : (status.toLowerCase() == 'paid' ? computedTotalAmount : 0);
    final double computedBalanceAmount = balanceAmount > 0
        ? balanceAmount
        : math.max(0, computedTotalAmount - computedPaidAmount);

    return InvoiceRecord(
      id: id,
      clientId: map['clientId'] as String? ?? '',
      number:
          map['number'] as String? ?? map['invoiceNumber'] as String? ?? 'INV',
      client:
          map['client'] as String? ??
          map['clientName'] as String? ??
          map['clientId'] as String? ??
          '',
      status: status,
      date: _readDate(map['date'] ?? map['createdAt']),
      dueDate: _readDate(map['dueDate'] ?? map['date'] ?? map['createdAt']),
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
      gstType: gstType,
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
      subtotalAmount: subtotal,
      gstAmountValue: totalGST,
      totalAmountValue: computedTotalAmount,
      paidAmount: computedPaidAmount,
      balanceAmount: computedBalanceAmount,
      cgstAmountValue: cgst,
      sgstAmountValue: sgst,
      igstAmountValue: igst,
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
