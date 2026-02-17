import 'package:cloud_firestore/cloud_firestore.dart';

class ProductRecord {
  const ProductRecord({
    required this.id,
    required this.name,
    required this.hsnCode,
    required this.costPrice,
    required this.sellingPrice,
    required this.gstRate,
    required this.stockQuantity,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String hsnCode;
  final double costPrice;
  final double sellingPrice;
  final double gstRate;
  final int stockQuantity;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'hsnCode': hsnCode,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'gstRate': gstRate,
      'stockQuantity': stockQuantity,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProductRecord.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return ProductRecord(
      id: id,
      name: map['name'] as String? ?? '',
      hsnCode: map['hsnCode'] as String? ?? '',
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0,
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 0,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(map['createdAt']),
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
