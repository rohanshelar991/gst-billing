import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyRecord {
  const CompanyRecord({
    required this.id,
    required this.name,
    required this.gstNumber,
    required this.address,
    required this.state,
    required this.logoUrl,
    required this.bankDetails,
    required this.invoicePrefix,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String gstNumber;
  final String address;
  final String state;
  final String logoUrl;
  final String bankDetails;
  final String invoicePrefix;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'gstNumber': gstNumber,
      'address': address,
      'state': state,
      'logoUrl': logoUrl,
      'bankDetails': bankDetails,
      'invoicePrefix': invoicePrefix,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CompanyRecord.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return CompanyRecord(
      id: id,
      name: map['name'] as String? ?? '',
      gstNumber: map['gstNumber'] as String? ?? '',
      address: map['address'] as String? ?? '',
      state: map['state'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      bankDetails: map['bankDetails'] as String? ?? '',
      invoicePrefix: map['invoicePrefix'] as String? ?? 'INV',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
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
