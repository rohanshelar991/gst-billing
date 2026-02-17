import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/client_record.dart';
import '../models/invoice_record.dart';
import '../models/product_record.dart';
import '../models/reminder_record.dart';
import 'auth_service.dart';

class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    required AuthService authService,
  }) : _firestoreOverride = firestore,
       _authService = authService;

  final FirebaseFirestore? _firestoreOverride;
  final AuthService _authService;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _clientsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('clients');
  }

  CollectionReference<Map<String, dynamic>> _productsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('products');
  }

  CollectionReference<Map<String, dynamic>> _invoicesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('invoices');
  }

  CollectionReference<Map<String, dynamic>> _remindersCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('reminders');
  }

  CollectionReference<Map<String, dynamic>> _analyticsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('analytics');
  }

  Future<void> saveBusinessProfile({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String gstin,
  }) async {
    final String uid = _requireUid();
    await _firestore.collection('users').doc(uid).set(<String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'businessName': businessName.trim(),
      'gstin': gstin.trim().toUpperCase(),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> streamUserProfile() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<Map<String, dynamic>?>.value(null);
      }
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map(
            (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
                snapshot.data(),
          );
    });
  }

  Stream<List<ClientRecord>> streamClients() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<ClientRecord>>.value(const <ClientRecord>[]);
      }
      return _clientsCollection(user.uid).snapshots().map(
        (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
          QueryDocumentSnapshot<Map<String, dynamic>> doc,
        ) {
          final Map<String, dynamic> map = doc.data();
          return ClientRecord(
            id: doc.id,
            name: map['name'] as String? ?? '',
            email: map['email'] as String? ?? '',
            phone: map['phone'] as String? ?? '',
            pendingAmount: (map['pendingAmount'] as num?)?.toDouble() ?? 0,
            invoices: (map['invoices'] as num?)?.toInt() ?? 0,
            isActive: map['isActive'] as bool? ?? true,
            segment:
                map['segment'] as String? ??
                map['state'] as String? ??
                'Corporate',
            creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0,
            usedCredit: (map['usedCredit'] as num?)?.toDouble() ?? 0,
            history: ((map['history'] as List<dynamic>?) ?? <dynamic>[])
                .map((dynamic value) => '$value')
                .toList(),
            address: map['address'] as String? ?? '',
            notes: map['notes'] as String? ?? '',
            createdAt: _parseDate(map['createdAt']),
            updatedAt: _parseDate(map['updatedAt']),
          );
        }).toList(),
      );
    });
  }

  Future<void> addClient({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String gstin,
    required String state,
    required double creditLimit,
  }) async {
    final String uid = _requireUid();
    await _clientsCollection(uid).add(<String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim().toLowerCase(),
      'address': address.trim(),
      'gstin': gstin.trim().toUpperCase(),
      'state': state.trim(),
      'creditLimit': creditLimit,
      'createdAt': Timestamp.now(),
      'pendingAmount': 0.0,
      'invoices': 0,
      'isActive': true,
      'segment': state.trim(),
      'usedCredit': 0.0,
      'history': <String>[],
      'notes': '',
      'updatedAt': Timestamp.now(),
    });
    await recordAnalyticsEvent(
      event: 'client_created',
      payload: <String, dynamic>{'state': state.trim()},
    );
  }

  Stream<List<ProductRecord>> streamProducts() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<ProductRecord>>.value(const <ProductRecord>[]);
      }
      return _productsCollection(user.uid).snapshots().map(
        (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
          QueryDocumentSnapshot<Map<String, dynamic>> doc,
        ) {
          return ProductRecord.fromMap(id: doc.id, map: doc.data());
        }).toList(),
      );
    });
  }

  Future<void> addProduct({
    required String name,
    required String hsnCode,
    required double costPrice,
    required double sellingPrice,
    required double gstRate,
    required int stockQuantity,
  }) async {
    final String uid = _requireUid();
    await _productsCollection(uid).add(<String, dynamic>{
      'name': name.trim(),
      'hsnCode': hsnCode.trim(),
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'gstRate': gstRate,
      'stockQuantity': stockQuantity,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    await recordAnalyticsEvent(
      event: 'product_created',
      payload: <String, dynamic>{'gstRate': gstRate},
    );
  }

  Stream<List<InvoiceRecord>> streamInvoices() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<InvoiceRecord>>.value(const <InvoiceRecord>[]);
      }
      return _invoicesCollection(user.uid).snapshots().map(
        (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
          QueryDocumentSnapshot<Map<String, dynamic>> doc,
        ) {
          final Map<String, dynamic> map = doc.data();
          final List<dynamic> rawItems =
              map['items'] as List<dynamic>? ?? <dynamic>[];
          final List<InvoiceItem> items = rawItems.map((dynamic item) {
            final Map<String, dynamic> itemMap = (item as Map<Object?, Object?>)
                .cast<String, dynamic>();
            return InvoiceItem(
              id:
                  itemMap['productId'] as String? ??
                  itemMap['id'] as String? ??
                  '',
              product:
                  itemMap['name'] as String? ??
                  itemMap['product'] as String? ??
                  '',
              qty:
                  (itemMap['quantity'] as num?)?.toInt() ??
                  (itemMap['qty'] as num?)?.toInt() ??
                  0,
              price: (itemMap['price'] as num?)?.toDouble() ?? 0,
            );
          }).toList();

          final String status =
              map['paymentStatus'] as String? ??
              map['status'] as String? ??
              'Pending';
          final int timelineStep =
              (map['timelineStep'] as num?)?.toInt() ??
              switch (status) {
                'Paid' => 3,
                'Pending' => 1,
                'Overdue' => 1,
                _ => 0,
              };

          return InvoiceRecord(
            id: doc.id,
            number:
                map['invoiceNumber'] as String? ??
                map['number'] as String? ??
                'INV',
            client:
                map['clientName'] as String? ??
                map['client'] as String? ??
                map['clientId'] as String? ??
                'Unknown Client',
            status: status,
            date: _parseDate(map['createdAt'] ?? map['date']),
            discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0,
            gstType: map['gstType'] as String? ?? 'CGST+SGST',
            gstPercent: (map['gstPercent'] as num?)?.toDouble() ?? 0,
            timelineStep: timelineStep,
            items: items,
            tags: ((map['tags'] as List<dynamic>?) ?? <dynamic>[])
                .map((dynamic value) => '$value')
                .toList(),
            notes: map['notes'] as String? ?? '',
            createdAt: _parseDate(map['createdAt']),
            updatedAt: _parseDate(map['updatedAt']),
          );
        }).toList(),
      );
    });
  }

  Future<void> addInvoice({
    required String invoiceNumber,
    required String clientId,
    required String clientName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double totalGST,
    required double totalAmount,
    required String paymentStatus,
    required DateTime dueDate,
    double discountPercent = 0,
    double gstPercent = 0,
    String gstType = 'CGST+SGST',
    String notes = '',
    List<String> tags = const <String>[],
    int timelineStep = 1,
  }) async {
    final String uid = _requireUid();
    await _invoicesCollection(uid).add(<String, dynamic>{
      'invoiceNumber': invoiceNumber.trim(),
      'clientId': clientId.trim(),
      'clientName': clientName.trim(),
      'items': items,
      'subtotal': subtotal,
      'totalGST': totalGST,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'discountPercent': discountPercent,
      'gstPercent': gstPercent,
      'gstType': gstType,
      'notes': notes,
      'tags': tags,
      'timelineStep': timelineStep,
    });
    await recordAnalyticsEvent(
      event: 'invoice_created',
      payload: <String, dynamic>{'totalAmount': totalAmount},
    );
  }

  Future<void> addInvoiceFromCalculator({
    required double pricePerPiece,
    required double quantity,
    required double gstRate,
    required String gstType,
    required double discountPercent,
    required double markupPercent,
  }) async {
    final DateTime now = DateTime.now();
    final String invoiceNumber = 'INV-${now.millisecondsSinceEpoch}';

    final double subtotal = pricePerPiece * quantity;
    final double discountAmount = subtotal * (discountPercent / 100);
    final double afterDiscount = subtotal - discountAmount;
    final double markupAmount = afterDiscount * (markupPercent / 100);
    final double taxable = afterDiscount + markupAmount;
    final double gstAmount = taxable * (gstRate / 100);
    final double totalAmount = taxable + gstAmount;

    await addInvoice(
      invoiceNumber: invoiceNumber,
      clientId: 'walkin',
      clientName: 'Walk-in Client',
      items: <Map<String, dynamic>>[
        <String, dynamic>{
          'productId': 'calculator_item',
          'name': 'Calculator Item',
          'quantity': quantity,
          'price': pricePerPiece,
          'gstRate': gstRate,
          'gstAmount': gstAmount,
          'total': totalAmount,
        },
      ],
      subtotal: subtotal,
      totalGST: gstAmount,
      totalAmount: totalAmount,
      paymentStatus: 'Pending',
      dueDate: now.add(const Duration(days: 7)),
      discountPercent: discountPercent,
      gstPercent: gstRate,
      gstType: gstType,
      notes: 'Created from calculator quick action.',
      tags: const <String>['calculator'],
      timelineStep: 1,
    );
  }

  Stream<List<ReminderRecord>> streamReminders() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<ReminderRecord>>.value(const <ReminderRecord>[]);
      }
      return _remindersCollection(user.uid).snapshots().map(
        (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
          QueryDocumentSnapshot<Map<String, dynamic>> doc,
        ) {
          final Map<String, dynamic> map = doc.data();
          return ReminderRecord(
            id: doc.id,
            title: map['title'] as String? ?? 'Reminder',
            type: map['type'] as String? ?? 'Invoice',
            status: map['status'] as String? ?? 'Pending',
            priority: map['priority'] as String? ?? 'Medium',
            enabled: map['enabled'] as bool? ?? true,
            message: map['message'] as String? ?? '',
            dueDate: _parseDate(map['dueDate']),
            channel: map['channel'] as String? ?? 'SMS',
            clientName:
                map['clientName'] as String? ??
                map['clientId'] as String? ??
                '',
            createdAt: _parseDate(map['createdAt']),
            updatedAt: _parseDate(map['updatedAt']),
          );
        }).toList(),
      );
    });
  }

  Future<void> addReminder({
    required String invoiceId,
    required String clientId,
    required DateTime dueDate,
    required String status,
    required bool reminderSent,
    String title = 'Invoice Reminder',
    String type = 'Invoice',
    String priority = 'Medium',
    bool enabled = true,
    String message = '',
    String channel = 'WhatsApp',
    String clientName = '',
  }) async {
    final String uid = _requireUid();
    await _remindersCollection(uid).add(<String, dynamic>{
      'invoiceId': invoiceId.trim(),
      'clientId': clientId.trim(),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'reminderSent': reminderSent,
      'title': title,
      'type': type,
      'priority': priority,
      'enabled': enabled,
      'message': message,
      'channel': channel,
      'clientName': clientName,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    await recordAnalyticsEvent(
      event: 'reminder_created',
      payload: <String, dynamic>{'status': status},
    );
  }

  Future<void> updateReminderEnabled({
    required String reminderId,
    required bool enabled,
  }) async {
    final String uid = _requireUid();
    await _remindersCollection(uid).doc(reminderId).set(<String, dynamic>{
      'enabled': enabled,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> recordAnalyticsEvent({
    required String event,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    try {
      final String uid = _requireUid();
      await _analyticsCollection(uid).add(<String, dynamic>{
        'event': event,
        'payload': payload,
        'createdAt': Timestamp.now(),
      });
    } catch (error) {
      debugPrint('Analytics record failed: $error');
    }
  }

  Stream<int> streamClientCount() {
    return streamClients().map((List<ClientRecord> clients) => clients.length);
  }

  Stream<double> streamPendingInvoiceAmount() {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      double value = 0;
      for (final InvoiceRecord invoice in invoices) {
        if (invoice.status.toLowerCase() != 'paid') {
          value += invoice.totalAmount;
        }
      }
      return value;
    });
  }

  Stream<int> streamPendingInvoiceCount() {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      int count = 0;
      for (final InvoiceRecord invoice in invoices) {
        if (invoice.status.toLowerCase() != 'paid') {
          count++;
        }
      }
      return count;
    });
  }

  Stream<int> streamUpcomingDueCount() {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      final DateTime now = DateTime.now();
      final DateTime weekEnd = now.add(const Duration(days: 7));
      int count = 0;
      for (final InvoiceRecord invoice in invoices) {
        final bool dueSoon =
            invoice.date.isAfter(now) && invoice.date.isBefore(weekEnd);
        if (dueSoon && invoice.status.toLowerCase() != 'paid') {
          count++;
        }
      }
      return count;
    });
  }

  Stream<int> streamOverdueInvoiceCount() {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      final DateTime now = DateTime.now();
      int count = 0;
      for (final InvoiceRecord invoice in invoices) {
        final bool overdue =
            invoice.date.isBefore(now) &&
            invoice.status.toLowerCase() != 'paid';
        if (overdue) {
          count++;
        }
      }
      return count;
    });
  }

  Stream<List<InvoiceRecord>> streamRecentInvoices({int limit = 3}) {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      final List<InvoiceRecord> sorted = List<InvoiceRecord>.from(invoices)
        ..sort((InvoiceRecord a, InvoiceRecord b) => b.date.compareTo(a.date));
      if (sorted.length <= limit) {
        return sorted;
      }
      return sorted.take(limit).toList();
    });
  }

  String _requireUid() {
    final String? uid = _authService.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No authenticated user found.');
    }
    return uid;
  }

  DateTime _parseDate(dynamic value) {
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
