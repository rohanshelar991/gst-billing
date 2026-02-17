import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/client_record.dart';
import '../models/company_record.dart';
import '../models/invoice_record.dart';
import '../models/product_record.dart';
import '../models/recurring_invoice_record.dart';
import '../models/report_record.dart';
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

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _companiesCollection(String uid) {
    return _userDoc(uid).collection('companies');
  }

  DocumentReference<Map<String, dynamic>> _companyDoc(
    String uid,
    String companyId,
  ) {
    return _companiesCollection(uid).doc(companyId);
  }

  CollectionReference<Map<String, dynamic>> _clientsCollection(
    String uid,
    String companyId,
  ) {
    return _companyDoc(uid, companyId).collection('clients');
  }

  CollectionReference<Map<String, dynamic>> _productsCollection(
    String uid,
    String companyId,
  ) {
    return _companyDoc(uid, companyId).collection('products');
  }

  CollectionReference<Map<String, dynamic>> _invoicesCollection(
    String uid,
    String companyId,
  ) {
    return _companyDoc(uid, companyId).collection('invoices');
  }

  CollectionReference<Map<String, dynamic>> _remindersCollection(
    String uid,
    String companyId,
  ) {
    return _companyDoc(uid, companyId).collection('reminders');
  }

  CollectionReference<Map<String, dynamic>> _recurringInvoicesCollection(
    String uid,
    String companyId,
  ) {
    return _companyDoc(uid, companyId).collection('recurringInvoices');
  }

  CollectionReference<Map<String, dynamic>> _analyticsCollection(
    String uid,
    String companyId,
  ) {
    return _companyDoc(uid, companyId).collection('analytics');
  }

  CollectionReference<Map<String, dynamic>> _activityCollection(String uid) {
    return _userDoc(uid).collection('activityLogs');
  }

  CollectionReference<Map<String, dynamic>> _legacyClientsCollection(
    String uid,
  ) {
    return _userDoc(uid).collection('clients');
  }

  CollectionReference<Map<String, dynamic>> _legacyProductsCollection(
    String uid,
  ) {
    return _userDoc(uid).collection('products');
  }

  CollectionReference<Map<String, dynamic>> _legacyInvoicesCollection(
    String uid,
  ) {
    return _userDoc(uid).collection('invoices');
  }

  CollectionReference<Map<String, dynamic>> _legacyRemindersCollection(
    String uid,
  ) {
    return _userDoc(uid).collection('reminders');
  }

  String _requireUid() {
    final String? uid = _authService.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No authenticated user found.');
    }
    return uid;
  }

  bool _isAdminRole(String role) {
    final String value = role.trim().toLowerCase();
    return value == 'admin' || value == 'owner';
  }

  Future<String?> _resolveActiveCompanyId(
    String uid,
    Map<String, dynamic>? userData,
  ) async {
    final dynamic rawActiveCompanyId = userData?['activeCompanyId'];
    if (rawActiveCompanyId is String && rawActiveCompanyId.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> activeCompany =
          await _companyDoc(uid, rawActiveCompanyId).get();
      if (activeCompany.exists) {
        return rawActiveCompanyId;
      }
    }

    final QuerySnapshot<Map<String, dynamic>> companies =
        await _companiesCollection(uid).limit(1).get();
    if (companies.docs.isNotEmpty) {
      final String firstCompanyId = companies.docs.first.id;
      await _userDoc(uid).set(<String, dynamic>{
        'activeCompanyId': firstCompanyId,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      return firstCompanyId;
    }

    final String createdCompanyId = await _createInitialCompany(uid, userData);
    await _userDoc(uid).set(<String, dynamic>{
      'activeCompanyId': createdCompanyId,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
    return createdCompanyId;
  }

  Stream<String?> _streamActiveCompanyIdForUid(String uid) {
    return _userDoc(uid).snapshots().asyncMap((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      return _resolveActiveCompanyId(uid, snapshot.data());
    });
  }

  Future<String> _requireCompanyId(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> user = await _userDoc(
      uid,
    ).get();
    final String? resolvedCompanyId = await _resolveActiveCompanyId(
      uid,
      user.data(),
    );
    if (resolvedCompanyId == null || resolvedCompanyId.isEmpty) {
      throw StateError('No active company found.');
    }
    return resolvedCompanyId;
  }

  Future<T> _withActiveCompany<T>(
    Future<T> Function(String uid, String companyId) action,
  ) async {
    final String uid = _requireUid();
    final String companyId = await _requireCompanyId(uid);
    return action(uid, companyId);
  }

  Future<String> _createInitialCompany(
    String uid,
    Map<String, dynamic>? userData,
  ) async {
    final String name =
        (userData?['businessName'] as String?)?.trim().isNotEmpty == true
        ? (userData?['businessName'] as String).trim()
        : (userData?['name'] as String?)?.trim().isNotEmpty == true
        ? (userData?['name'] as String).trim()
        : 'Primary Business';
    final String gstNumber = (userData?['gstin'] as String? ?? '').trim();
    final String email = (userData?['email'] as String? ?? '').trim();
    final String phone = (userData?['phone'] as String? ?? '').trim();

    final DocumentReference<Map<String, dynamic>> companyRef =
        _companiesCollection(uid).doc();
    await companyRef.set(<String, dynamic>{
      'name': name,
      'gstNumber': gstNumber,
      'address': '',
      'state': '',
      'logoUrl': '',
      'invoicePrefix': 'INV',
      'bankDetails': '',
      'email': email,
      'phone': phone,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    await _migrateLegacyDataToCompany(uid, companyRef.id);
    return companyRef.id;
  }

  Future<void> _migrateLegacyDataToCompany(String uid, String companyId) async {
    await _copyLegacyCollection(
      source: _legacyClientsCollection(uid),
      destination: _clientsCollection(uid, companyId),
    );
    await _copyLegacyCollection(
      source: _legacyProductsCollection(uid),
      destination: _productsCollection(uid, companyId),
    );
    await _copyLegacyCollection(
      source: _legacyInvoicesCollection(uid),
      destination: _invoicesCollection(uid, companyId),
    );
    await _copyLegacyCollection(
      source: _legacyRemindersCollection(uid),
      destination: _remindersCollection(uid, companyId),
    );
  }

  Future<void> _copyLegacyCollection({
    required CollectionReference<Map<String, dynamic>> source,
    required CollectionReference<Map<String, dynamic>> destination,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await source.get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final DocumentSnapshot<Map<String, dynamic>> existing = await destination
          .doc(doc.id)
          .get();
      if (existing.exists) {
        continue;
      }
      await destination.doc(doc.id).set(doc.data(), SetOptions(merge: true));
    }
  }

  Future<void> _logActivity({
    required String uid,
    required String companyId,
    required String action,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    try {
      await _activityCollection(uid).add(<String, dynamic>{
        'companyId': companyId,
        'action': action,
        'metadata': metadata,
        'timestamp': Timestamp.now(),
      });
    } catch (_) {}
  }

  Stream<Map<String, dynamic>?> streamUserProfile() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<Map<String, dynamic>?>.value(null);
      }
      return _userDoc(user.uid).snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> snapshot) => snapshot.data(),
      );
    });
  }

  Stream<String?> streamUserRole() {
    return streamUserProfile().map((Map<String, dynamic>? map) {
      final String role = (map?['role'] as String? ?? 'admin').trim();
      if (role.isEmpty) {
        return 'admin';
      }
      return role;
    });
  }

  Future<String> getCurrentUserRole() async {
    final String uid = _requireUid();
    final DocumentSnapshot<Map<String, dynamic>> user = await _userDoc(
      uid,
    ).get();
    final String role = (user.data()?['role'] as String? ?? 'admin').trim();
    return role.isEmpty ? 'admin' : role;
  }

  Stream<List<CompanyRecord>> streamCompanies() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<CompanyRecord>>.value(const <CompanyRecord>[]);
      }
      return _companiesCollection(user.uid)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
            return snapshot.docs.map((
              QueryDocumentSnapshot<Map<String, dynamic>> doc,
            ) {
              return CompanyRecord.fromMap(id: doc.id, map: doc.data());
            }).toList();
          });
    });
  }

  Stream<String?> streamActiveCompanyId() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<String?>.value(null);
      }
      return _streamActiveCompanyIdForUid(user.uid);
    });
  }

  Stream<CompanyRecord?> streamActiveCompany() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<CompanyRecord?>.value(null);
      }
      return _streamActiveCompanyIdForUid(user.uid).asyncExpand((companyId) {
        if (companyId == null || companyId.isEmpty) {
          return Stream<CompanyRecord?>.value(null);
        }
        return _companyDoc(user.uid, companyId).snapshots().map((
          DocumentSnapshot<Map<String, dynamic>> snapshot,
        ) {
          final Map<String, dynamic>? data = snapshot.data();
          if (data == null) {
            return null;
          }
          return CompanyRecord.fromMap(id: snapshot.id, map: data);
        });
      });
    });
  }

  Stream<Map<String, dynamic>?> streamCompanyProfile() {
    return streamActiveCompany().map((CompanyRecord? company) {
      return company?.toMap();
    });
  }

  Future<String> addCompany({
    required String name,
    required String gstNumber,
    required String address,
    required String state,
    required String logoUrl,
    required String bankDetails,
    required String invoicePrefix,
  }) async {
    final String uid = _requireUid();
    final DocumentReference<Map<String, dynamic>> companyRef =
        _companiesCollection(uid).doc();
    await companyRef.set(<String, dynamic>{
      'name': name.trim(),
      'gstNumber': gstNumber.trim().toUpperCase(),
      'address': address.trim(),
      'state': state.trim(),
      'logoUrl': logoUrl.trim(),
      'bankDetails': bankDetails.trim(),
      'invoicePrefix': invoicePrefix.trim().isEmpty
          ? 'INV'
          : invoicePrefix.trim().toUpperCase(),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    final DocumentSnapshot<Map<String, dynamic>> user = await _userDoc(
      uid,
    ).get();
    final String? activeCompanyId = user.data()?['activeCompanyId'] as String?;
    if (activeCompanyId == null || activeCompanyId.isEmpty) {
      await setActiveCompany(companyRef.id);
    }
    await _logActivity(
      uid: uid,
      companyId: companyRef.id,
      action: 'company_created',
      metadata: <String, dynamic>{'name': name.trim()},
    );
    return companyRef.id;
  }

  Future<void> updateCompany({
    required String companyId,
    required String name,
    required String gstNumber,
    required String address,
    required String state,
    required String logoUrl,
    required String bankDetails,
    required String invoicePrefix,
  }) async {
    final String uid = _requireUid();
    await _companyDoc(uid, companyId).set(<String, dynamic>{
      'name': name.trim(),
      'gstNumber': gstNumber.trim().toUpperCase(),
      'address': address.trim(),
      'state': state.trim(),
      'logoUrl': logoUrl.trim(),
      'bankDetails': bankDetails.trim(),
      'invoicePrefix': invoicePrefix.trim().isEmpty
          ? 'INV'
          : invoicePrefix.trim().toUpperCase(),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
    await _logActivity(
      uid: uid,
      companyId: companyId,
      action: 'company_updated',
      metadata: <String, dynamic>{'name': name.trim()},
    );
  }

  Future<void> deleteCompany({required String companyId}) async {
    final String uid = _requireUid();
    final String role = await getCurrentUserRole();
    if (!_isAdminRole(role)) {
      throw StateError('Only admin users can delete companies.');
    }

    final QuerySnapshot<Map<String, dynamic>> companies =
        await _companiesCollection(uid).get();
    if (companies.docs.length <= 1) {
      throw StateError('At least one company must remain.');
    }

    await _companyDoc(uid, companyId).delete();
    final DocumentSnapshot<Map<String, dynamic>> user = await _userDoc(
      uid,
    ).get();
    final String? activeCompanyId = user.data()?['activeCompanyId'] as String?;
    if (activeCompanyId == companyId) {
      final QuerySnapshot<Map<String, dynamic>> remainingCompanies =
          await _companiesCollection(uid).limit(1).get();
      if (remainingCompanies.docs.isNotEmpty) {
        await setActiveCompany(remainingCompanies.docs.first.id);
      }
    }
    await _logActivity(
      uid: uid,
      companyId: companyId,
      action: 'company_deleted',
    );
  }

  Future<void> setActiveCompany(String companyId) async {
    final String uid = _requireUid();
    await _userDoc(uid).set(<String, dynamic>{
      'activeCompanyId': companyId,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> saveBusinessProfile({
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String gstin,
    String address = '',
    String state = '',
    String logoUrl = '',
    String bankDetails = '',
    String invoicePrefix = 'INV',
  }) async {
    final String uid = _requireUid();
    final String companyId = await _requireCompanyId(uid);

    await _userDoc(uid).set(<String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'businessName': businessName.trim(),
      'gstin': gstin.trim().toUpperCase(),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await _companyDoc(uid, companyId).set(<String, dynamic>{
      'name': businessName.trim(),
      'gstNumber': gstin.trim().toUpperCase(),
      'address': address.trim(),
      'state': state.trim(),
      'logoUrl': logoUrl.trim(),
      'bankDetails': bankDetails.trim(),
      'invoicePrefix': invoicePrefix.trim().isEmpty
          ? 'INV'
          : invoicePrefix.trim().toUpperCase(),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await _logActivity(
      uid: uid,
      companyId: companyId,
      action: 'company_profile_updated',
      metadata: <String, dynamic>{'businessName': businessName.trim()},
    );
  }

  Stream<List<ClientRecord>> streamClients() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<ClientRecord>>.value(const <ClientRecord>[]);
      }
      return _streamActiveCompanyIdForUid(user.uid).asyncExpand((companyId) {
        if (companyId == null || companyId.isEmpty) {
          return Stream<List<ClientRecord>>.value(const <ClientRecord>[]);
        }
        return _clientsCollection(
          user.uid,
          companyId,
        ).orderBy('createdAt', descending: true).snapshots().map((
          QuerySnapshot<Map<String, dynamic>> snapshot,
        ) {
          return snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final Map<String, dynamic> map = doc.data();
            return ClientRecord(
              id: doc.id,
              name: map['name'] as String? ?? '',
              email: map['email'] as String? ?? '',
              phone: map['phone'] as String? ?? '',
              gstin: map['gstin'] as String? ?? '',
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
          }).toList();
        });
      });
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
    await _withActiveCompany((String uid, String companyId) async {
      await _clientsCollection(uid, companyId).add(<String, dynamic>{
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
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'client_created',
        metadata: <String, dynamic>{'name': name.trim()},
      );
    });
  }

  Future<void> updateClient({
    required String clientId,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String gstin,
    required String state,
    required double creditLimit,
  }) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _clientsCollection(
        uid,
        companyId,
      ).doc(clientId).set(<String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim().toLowerCase(),
        'address': address.trim(),
        'gstin': gstin.trim().toUpperCase(),
        'state': state.trim(),
        'segment': state.trim(),
        'creditLimit': creditLimit,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'client_updated',
        metadata: <String, dynamic>{'clientId': clientId},
      );
    });
  }

  Future<void> deleteClient({required String clientId}) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _clientsCollection(uid, companyId).doc(clientId).delete();
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'client_deleted',
        metadata: <String, dynamic>{'clientId': clientId},
      );
    });
  }

  Stream<List<ProductRecord>> streamProducts() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<ProductRecord>>.value(const <ProductRecord>[]);
      }
      return _streamActiveCompanyIdForUid(user.uid).asyncExpand((companyId) {
        if (companyId == null || companyId.isEmpty) {
          return Stream<List<ProductRecord>>.value(const <ProductRecord>[]);
        }
        return _productsCollection(user.uid, companyId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
              return snapshot.docs.map((
                QueryDocumentSnapshot<Map<String, dynamic>> doc,
              ) {
                return ProductRecord.fromMap(id: doc.id, map: doc.data());
              }).toList();
            });
      });
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
    await _withActiveCompany((String uid, String companyId) async {
      await _productsCollection(uid, companyId).add(<String, dynamic>{
        'name': name.trim(),
        'hsnCode': hsnCode.trim(),
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'gstRate': gstRate,
        'stockQuantity': stockQuantity,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'product_created',
        metadata: <String, dynamic>{'name': name.trim()},
      );
    });
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String hsnCode,
    required double costPrice,
    required double sellingPrice,
    required double gstRate,
    required int stockQuantity,
  }) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _productsCollection(
        uid,
        companyId,
      ).doc(productId).set(<String, dynamic>{
        'name': name.trim(),
        'hsnCode': hsnCode.trim(),
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'gstRate': gstRate,
        'stockQuantity': stockQuantity,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'product_updated',
        metadata: <String, dynamic>{'productId': productId},
      );
    });
  }

  Future<void> deleteProduct({required String productId}) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _productsCollection(uid, companyId).doc(productId).delete();
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'product_deleted',
        metadata: <String, dynamic>{'productId': productId},
      );
    });
  }

  Stream<List<InvoiceRecord>> streamInvoices() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<InvoiceRecord>>.value(const <InvoiceRecord>[]);
      }
      return _streamActiveCompanyIdForUid(user.uid).asyncExpand((companyId) {
        if (companyId == null || companyId.isEmpty) {
          return Stream<List<InvoiceRecord>>.value(const <InvoiceRecord>[]);
        }
        return _invoicesCollection(user.uid, companyId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
              return snapshot.docs.map((
                QueryDocumentSnapshot<Map<String, dynamic>> doc,
              ) {
                return InvoiceRecord.fromMap(id: doc.id, map: doc.data());
              }).toList();
            });
      });
    });
  }

  Map<String, double> calculateTaxBreakdown({
    required double taxableAmount,
    required double gstRate,
    required String companyState,
    required String clientState,
  }) {
    if (taxableAmount <= 0 || gstRate <= 0) {
      return const <String, double>{
        'cgst': 0,
        'sgst': 0,
        'igst': 0,
        'totalTax': 0,
      };
    }
    final String company = companyState.trim().toLowerCase();
    final String client = clientState.trim().toLowerCase();
    final bool sameState =
        company.isNotEmpty && client.isNotEmpty && company == client;
    final double totalTax = taxableAmount * (gstRate / 100);
    if (sameState) {
      return <String, double>{
        'cgst': totalTax / 2,
        'sgst': totalTax / 2,
        'igst': 0,
        'totalTax': totalTax,
      };
    }
    return <String, double>{
      'cgst': 0,
      'sgst': 0,
      'igst': totalTax,
      'totalTax': totalTax,
    };
  }

  Future<String> _companyState(String uid, String companyId) async {
    final DocumentSnapshot<Map<String, dynamic>> company = await _companyDoc(
      uid,
      companyId,
    ).get();
    return (company.data()?['state'] as String? ?? '').trim();
  }

  Future<String> _clientState(
    String uid,
    String companyId,
    String clientId,
  ) async {
    if (clientId.trim().isEmpty) {
      return '';
    }
    final DocumentSnapshot<Map<String, dynamic>> client =
        await _clientsCollection(uid, companyId).doc(clientId.trim()).get();
    return (client.data()?['state'] as String? ?? '').trim();
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
    String clientState = '',
  }) async {
    await _withActiveCompany((String uid, String companyId) async {
      final String companyState = await _companyState(uid, companyId);
      final String resolvedClientState = clientState.trim().isNotEmpty
          ? clientState.trim()
          : await _clientState(uid, companyId, clientId);
      final double effectiveGstRate = gstPercent > 0 ? gstPercent : 0;
      final Map<String, double> taxBreakdown = calculateTaxBreakdown(
        taxableAmount: subtotal,
        gstRate: effectiveGstRate,
        companyState: companyState,
        clientState: resolvedClientState,
      );
      final double calculatedTax = taxBreakdown['totalTax'] ?? 0;
      final double effectiveTax = effectiveGstRate > 0
          ? calculatedTax
          : totalGST;
      final double effectiveTotal =
          subtotal + effectiveTax - (subtotal * (discountPercent / 100));
      final double paidAmount = paymentStatus.toLowerCase() == 'paid'
          ? effectiveTotal
          : 0;
      final double balanceAmount = math.max(0, effectiveTotal - paidAmount);
      final String resolvedStatus = balanceAmount == 0
          ? 'Paid'
          : paidAmount > 0
          ? 'Partial'
          : paymentStatus;
      final String resolvedGstType = (taxBreakdown['igst'] ?? 0) > 0
          ? 'IGST'
          : (effectiveTax == 0 ? 'No GST' : 'CGST+SGST');

      await _invoicesCollection(uid, companyId).add(<String, dynamic>{
        'invoiceNumber': invoiceNumber.trim(),
        'clientId': clientId.trim(),
        'clientName': clientName.trim(),
        'clientState': resolvedClientState,
        'companyState': companyState,
        'items': items,
        'subtotal': subtotal,
        'totalGST': effectiveTax,
        'totalAmount': effectiveTotal,
        'paymentStatus': resolvedStatus,
        'status': resolvedStatus,
        'dueDate': Timestamp.fromDate(dueDate),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'discountPercent': discountPercent,
        'gstPercent': effectiveGstRate,
        'gstType': resolvedGstType.isEmpty ? gstType : resolvedGstType,
        'taxBreakdown': <String, dynamic>{
          'cgst': taxBreakdown['cgst'] ?? 0,
          'sgst': taxBreakdown['sgst'] ?? 0,
          'igst': taxBreakdown['igst'] ?? 0,
          'totalTax': effectiveTax,
        },
        'notes': notes,
        'tags': tags,
        'timelineStep': timelineStep,
        'paidAmount': paidAmount,
        'balanceAmount': balanceAmount,
        'paymentDate': paidAmount > 0 ? Timestamp.now() : null,
        'paymentMethod': paidAmount > 0 ? 'cash' : '',
        'paymentHistory': <Map<String, dynamic>>[],
        'pdfUrl': '',
      });

      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'invoice_created',
        metadata: <String, dynamic>{
          'invoiceNumber': invoiceNumber.trim(),
          'totalAmount': effectiveTotal,
        },
      );
    });
  }

  Future<void> updateInvoicePaymentStatus({
    required String invoiceId,
    required String paymentStatus,
  }) async {
    await _withActiveCompany((String uid, String companyId) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _invoicesCollection(uid, companyId).doc(invoiceId).get();
      final Map<String, dynamic> map = snapshot.data() ?? <String, dynamic>{};
      final double totalAmount = (map['totalAmount'] as num?)?.toDouble() ?? 0;
      final double paidAmount = paymentStatus.toLowerCase() == 'paid'
          ? totalAmount
          : (map['paidAmount'] as num?)?.toDouble() ?? 0;
      final double balanceAmount = paymentStatus.toLowerCase() == 'paid'
          ? 0
          : math.max(0, totalAmount - paidAmount);

      final int timelineStep = switch (paymentStatus) {
        'Paid' => 3,
        'Pending' => 1,
        'Overdue' => 1,
        'Partial' => 2,
        _ => 0,
      };
      await _invoicesCollection(
        uid,
        companyId,
      ).doc(invoiceId).set(<String, dynamic>{
        'paymentStatus': paymentStatus,
        'status': paymentStatus,
        'timelineStep': timelineStep,
        'paidAmount': paidAmount,
        'balanceAmount': balanceAmount,
        'paymentDate': paymentStatus.toLowerCase() == 'paid'
            ? Timestamp.now()
            : map['paymentDate'],
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'invoice_status_updated',
        metadata: <String, dynamic>{
          'invoiceId': invoiceId,
          'status': paymentStatus,
        },
      );
    });
  }

  Future<void> recordInvoicePayment({
    required String invoiceId,
    required double amount,
    required String method,
    DateTime? paymentDate,
  }) async {
    await _withActiveCompany((String uid, String companyId) async {
      final DocumentReference<Map<String, dynamic>> invoiceRef =
          _invoicesCollection(uid, companyId).doc(invoiceId);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await invoiceRef
          .get();
      final Map<String, dynamic> map = snapshot.data() ?? <String, dynamic>{};
      final double totalAmount = (map['totalAmount'] as num?)?.toDouble() ?? 0;
      final double currentPaidAmount =
          (map['paidAmount'] as num?)?.toDouble() ?? 0;
      final double nextPaidAmount = math.min(
        totalAmount,
        currentPaidAmount + amount,
      );
      final double balanceAmount = math.max(0, totalAmount - nextPaidAmount);
      final String status = balanceAmount == 0
          ? 'Paid'
          : (nextPaidAmount > 0 ? 'Partial' : 'Pending');

      final List<dynamic> history =
          (map['paymentHistory'] as List<dynamic>?) ?? <dynamic>[];
      history.add(<String, dynamic>{
        'amount': amount,
        'method': method.trim().isEmpty ? 'cash' : method.trim().toLowerCase(),
        'date': Timestamp.fromDate(paymentDate ?? DateTime.now()),
      });

      await invoiceRef.set(<String, dynamic>{
        'paidAmount': nextPaidAmount,
        'balanceAmount': balanceAmount,
        'paymentStatus': status,
        'status': status,
        'paymentDate': Timestamp.fromDate(paymentDate ?? DateTime.now()),
        'paymentMethod': method.trim(),
        'paymentHistory': history,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'payment_received',
        metadata: <String, dynamic>{
          'invoiceId': invoiceId,
          'amount': amount,
          'method': method.trim(),
        },
      );
    });
  }

  Future<void> deleteInvoice({required String invoiceId}) async {
    await _withActiveCompany((String uid, String companyId) async {
      final String role = await getCurrentUserRole();
      if (!_isAdminRole(role)) {
        throw StateError('Only admin users can delete invoices.');
      }
      await _invoicesCollection(uid, companyId).doc(invoiceId).delete();
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'invoice_deleted',
        metadata: <String, dynamic>{'invoiceId': invoiceId},
      );
    });
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
    final String generatedItemId = 'calc-${now.microsecondsSinceEpoch}';

    final double subtotal = pricePerPiece * quantity;
    final double discountAmount = subtotal * (discountPercent / 100);
    final double afterDiscount = subtotal - discountAmount;
    final double markupAmount = afterDiscount * (markupPercent / 100);
    final double taxable = afterDiscount + markupAmount;
    final double gstAmount = taxable * (gstRate / 100);
    final double totalAmount = taxable + gstAmount;

    await addInvoice(
      invoiceNumber: invoiceNumber,
      clientId: 'direct_sale',
      clientName: 'Direct Sale',
      items: <Map<String, dynamic>>[
        <String, dynamic>{
          'productId': generatedItemId,
          'name': 'Calculated Item',
          'quantity': quantity,
          'price': pricePerPiece,
          'gstRate': gstRate,
          'gstAmount': gstAmount,
          'total': totalAmount,
        },
      ],
      subtotal: taxable,
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

  Stream<List<RecurringInvoiceRecord>> streamRecurringInvoices() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<RecurringInvoiceRecord>>.value(
          const <RecurringInvoiceRecord>[],
        );
      }
      return _streamActiveCompanyIdForUid(user.uid).asyncExpand((companyId) {
        if (companyId == null || companyId.isEmpty) {
          return Stream<List<RecurringInvoiceRecord>>.value(
            const <RecurringInvoiceRecord>[],
          );
        }
        return _recurringInvoicesCollection(
          user.uid,
          companyId,
        ).orderBy('nextInvoiceDate', descending: false).snapshots().map((
          QuerySnapshot<Map<String, dynamic>> snapshot,
        ) {
          return snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            return RecurringInvoiceRecord.fromMap(id: doc.id, map: doc.data());
          }).toList();
        });
      });
    });
  }

  Future<void> addRecurringInvoice({
    required String clientId,
    required String clientName,
    required List<Map<String, dynamic>> items,
    required String frequency,
    required DateTime nextInvoiceDate,
    required bool autoGenerate,
  }) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _recurringInvoicesCollection(uid, companyId).add(<String, dynamic>{
        'clientId': clientId.trim(),
        'clientName': clientName.trim(),
        'items': items,
        'frequency': frequency.trim().toLowerCase(),
        'nextInvoiceDate': Timestamp.fromDate(nextInvoiceDate),
        'autoGenerate': autoGenerate,
        'isPaused': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'recurring_invoice_created',
        metadata: <String, dynamic>{'clientId': clientId.trim()},
      );
    });
  }

  Future<void> updateRecurringInvoice({
    required String recurringId,
    required String frequency,
    required DateTime nextInvoiceDate,
    required bool autoGenerate,
    required bool isPaused,
  }) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _recurringInvoicesCollection(
        uid,
        companyId,
      ).doc(recurringId).set(<String, dynamic>{
        'frequency': frequency.trim().toLowerCase(),
        'nextInvoiceDate': Timestamp.fromDate(nextInvoiceDate),
        'autoGenerate': autoGenerate,
        'isPaused': isPaused,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'recurring_invoice_updated',
        metadata: <String, dynamic>{'recurringId': recurringId},
      );
    });
  }

  Future<void> deleteRecurringInvoice({required String recurringId}) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _recurringInvoicesCollection(
        uid,
        companyId,
      ).doc(recurringId).delete();
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'recurring_invoice_deleted',
        metadata: <String, dynamic>{'recurringId': recurringId},
      );
    });
  }

  Future<void> processRecurringInvoicesForToday() async {
    await _withActiveCompany((String uid, String companyId) async {
      final DateTime today = DateTime.now();
      final QuerySnapshot<Map<String, dynamic>> recurringSnapshot =
          await _recurringInvoicesCollection(uid, companyId).get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> recurringDoc
          in recurringSnapshot.docs) {
        final Map<String, dynamic> map = recurringDoc.data();
        final bool autoGenerate = map['autoGenerate'] as bool? ?? false;
        final bool paused = map['isPaused'] as bool? ?? false;
        if (!autoGenerate || paused) {
          continue;
        }

        final DateTime nextDate = _parseDate(map['nextInvoiceDate']);
        final DateTime normalizedNextDate = DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day,
        );
        final DateTime normalizedToday = DateTime(
          today.year,
          today.month,
          today.day,
        );
        if (normalizedNextDate.isAfter(normalizedToday)) {
          continue;
        }

        final List<Map<String, dynamic>> items =
            ((map['items'] as List<dynamic>?) ?? <dynamic>[])
                .map(
                  (dynamic item) =>
                      (item as Map<Object?, Object?>).cast<String, dynamic>(),
                )
                .toList();
        double subtotal = 0;
        double gstRate = 0;
        for (final Map<String, dynamic> item in items) {
          final double quantity =
              (item['quantity'] as num?)?.toDouble() ??
              (item['qty'] as num?)?.toDouble() ??
              0;
          final double price = (item['price'] as num?)?.toDouble() ?? 0;
          subtotal += quantity * price;
          gstRate = (item['gstRate'] as num?)?.toDouble() ?? gstRate;
        }
        final double totalGst = subtotal * (gstRate / 100);
        final double totalAmount = subtotal + totalGst;

        await addInvoice(
          invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
          clientId: map['clientId'] as String? ?? '',
          clientName: map['clientName'] as String? ?? '',
          items: items,
          subtotal: subtotal,
          totalGST: totalGst,
          totalAmount: totalAmount,
          paymentStatus: 'Pending',
          dueDate: today.add(const Duration(days: 7)),
          gstPercent: gstRate,
          tags: const <String>['recurring'],
          notes: 'Auto-generated from recurring invoice.',
          timelineStep: 1,
        );

        final String frequency = (map['frequency'] as String? ?? 'monthly')
            .trim()
            .toLowerCase();
        final DateTime updatedNextDate = _nextInvoiceDate(
          normalizedNextDate,
          frequency,
        );
        await _recurringInvoicesCollection(
          uid,
          companyId,
        ).doc(recurringDoc.id).set(<String, dynamic>{
          'lastGeneratedAt': Timestamp.now(),
          'nextInvoiceDate': Timestamp.fromDate(updatedNextDate),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }
    });
  }

  Stream<List<ReminderRecord>> streamReminders() {
    return _authService.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<ReminderRecord>>.value(const <ReminderRecord>[]);
      }
      return _streamActiveCompanyIdForUid(user.uid).asyncExpand((companyId) {
        if (companyId == null || companyId.isEmpty) {
          return Stream<List<ReminderRecord>>.value(const <ReminderRecord>[]);
        }
        return _remindersCollection(user.uid, companyId)
            .orderBy('dueDate', descending: false)
            .snapshots()
            .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
              return snapshot.docs.map((
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
              }).toList();
            });
      });
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
    await _withActiveCompany((String uid, String companyId) async {
      await _remindersCollection(uid, companyId).add(<String, dynamic>{
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
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'reminder_created',
        metadata: <String, dynamic>{'title': title},
      );
    });
  }

  Future<void> updateReminderEnabled({
    required String reminderId,
    required bool enabled,
  }) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _remindersCollection(uid, companyId).doc(reminderId).set(
        <String, dynamic>{'enabled': enabled, 'updatedAt': Timestamp.now()},
        SetOptions(merge: true),
      );
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'reminder_toggled',
        metadata: <String, dynamic>{
          'reminderId': reminderId,
          'enabled': enabled,
        },
      );
    });
  }

  Future<void> updateReminderStatus({
    required String reminderId,
    required String status,
  }) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _remindersCollection(uid, companyId).doc(reminderId).set(
        <String, dynamic>{'status': status, 'updatedAt': Timestamp.now()},
        SetOptions(merge: true),
      );
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'reminder_status_updated',
        metadata: <String, dynamic>{'reminderId': reminderId, 'status': status},
      );
    });
  }

  Future<void> deleteReminder({required String reminderId}) async {
    await _withActiveCompany((String uid, String companyId) async {
      await _remindersCollection(uid, companyId).doc(reminderId).delete();
      await _logActivity(
        uid: uid,
        companyId: companyId,
        action: 'reminder_deleted',
        metadata: <String, dynamic>{'reminderId': reminderId},
      );
    });
  }

  Future<void> recordAnalyticsEvent({
    required String event,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    try {
      final String uid = _requireUid();
      final String companyId = await _requireCompanyId(uid);
      await _analyticsCollection(uid, companyId).add(<String, dynamic>{
        'event': event,
        'payload': payload,
        'createdAt': Timestamp.now(),
      });
    } catch (_) {}
  }

  Stream<int> streamClientCount() {
    return streamClients().map((List<ClientRecord> clients) => clients.length);
  }

  Stream<int> streamInvoiceCount() {
    return streamInvoices().map(
      (List<InvoiceRecord> invoices) => invoices.length,
    );
  }

  Stream<double> streamTotalRevenue() {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      double value = 0;
      for (final InvoiceRecord invoice in invoices) {
        value += invoice.totalAmount;
      }
      return value;
    });
  }

  Stream<double> streamMonthlyRevenue() {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      final DateTime now = DateTime.now();
      double value = 0;
      for (final InvoiceRecord invoice in invoices) {
        final bool sameMonth =
            invoice.date.year == now.year && invoice.date.month == now.month;
        if (sameMonth) {
          value += invoice.totalAmount;
        }
      }
      return value;
    });
  }

  Stream<double> streamPendingInvoiceAmount() {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      double value = 0;
      for (final InvoiceRecord invoice in invoices) {
        if (invoice.status.toLowerCase() != 'paid') {
          final double pending = invoice.balanceAmount > 0
              ? invoice.balanceAmount
              : math.max(0, invoice.totalAmount - invoice.paidAmount);
          value += pending;
        }
      }
      return value;
    });
  }

  Stream<double> streamUnpaidAmount() => streamPendingInvoiceAmount();

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
            invoice.dueDate.isAfter(now) && invoice.dueDate.isBefore(weekEnd);
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
            invoice.dueDate.isBefore(now) &&
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

  Stream<List<ClientRecord>> streamTopClients({int limit = 3}) {
    return streamClients().map((List<ClientRecord> clients) {
      final List<ClientRecord> sorted = List<ClientRecord>.from(clients)
        ..sort(
          (ClientRecord a, ClientRecord b) =>
              b.pendingAmount.compareTo(a.pendingAmount),
        );
      if (sorted.length <= limit) {
        return sorted;
      }
      return sorted.take(limit).toList();
    });
  }

  Stream<List<MonthlyRevenuePoint>> streamMonthlyRevenueReport({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      final Map<String, Map<String, double>> monthBuckets =
          <String, Map<String, double>>{};

      for (final InvoiceRecord invoice in invoices) {
        if (!_isWithinRange(invoice.date, startDate, endDate)) {
          continue;
        }
        final String monthKey =
            '${invoice.date.year}-${invoice.date.month.toString().padLeft(2, '0')}';
        final double paidAmount = _resolvedPaidAmount(invoice);
        final double unpaidAmount = math.max(
          0,
          invoice.totalAmount - paidAmount,
        );
        final Map<String, double> bucket =
            monthBuckets[monthKey] ??
            <String, double>{'total': 0, 'paid': 0, 'unpaid': 0};
        bucket['total'] = (bucket['total'] ?? 0) + invoice.totalAmount;
        bucket['paid'] = (bucket['paid'] ?? 0) + paidAmount;
        bucket['unpaid'] = (bucket['unpaid'] ?? 0) + unpaidAmount;
        monthBuckets[monthKey] = bucket;
      }

      final List<String> keys = monthBuckets.keys.toList()..sort();
      final List<MonthlyRevenuePoint> points = <MonthlyRevenuePoint>[];
      double previousMonthRevenue = 0;
      for (final String key in keys) {
        final Map<String, double> bucket = monthBuckets[key]!;
        final double total = bucket['total'] ?? 0;
        final double paid = bucket['paid'] ?? 0;
        final double unpaid = bucket['unpaid'] ?? 0;
        final double growth = previousMonthRevenue <= 0
            ? 0
            : ((total - previousMonthRevenue) / previousMonthRevenue) * 100;

        points.add(
          MonthlyRevenuePoint(
            monthKey: key,
            totalRevenue: total,
            paidRevenue: paid,
            unpaidRevenue: unpaid,
            growthPercent: growth,
          ),
        );
        previousMonthRevenue = total;
      }
      return points;
    });
  }

  Stream<GstSummaryRecord> streamGstSummaryReport({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      double cgst = 0;
      double sgst = 0;
      double igst = 0;
      double taxable = 0;

      for (final InvoiceRecord invoice in invoices) {
        if (!_isWithinRange(invoice.date, startDate, endDate)) {
          continue;
        }
        taxable += invoice.taxableAmount;
        cgst += invoice.cgstAmount;
        sgst += invoice.sgstAmount;
        igst += invoice.igstAmount;
      }

      return GstSummaryRecord(
        cgst: cgst,
        sgst: sgst,
        igst: igst,
        totalTax: cgst + sgst + igst,
        taxableAmount: taxable,
      );
    });
  }

  Stream<List<TopClientRecord>> streamTopClientsReport({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
  }) {
    return streamInvoices().map((List<InvoiceRecord> invoices) {
      final Map<String, Map<String, dynamic>> grouped =
          <String, Map<String, dynamic>>{};

      for (final InvoiceRecord invoice in invoices) {
        if (!_isWithinRange(invoice.date, startDate, endDate)) {
          continue;
        }
        final String key = invoice.clientId.isNotEmpty
            ? invoice.clientId
            : invoice.client;
        final Map<String, dynamic> entry =
            grouped[key] ??
            <String, dynamic>{
              'clientId': invoice.clientId,
              'clientName': invoice.client,
              'invoiceCount': 0,
              'totalAmount': 0.0,
              'paidAmount': 0.0,
              'unpaidAmount': 0.0,
            };

        final double paidAmount = _resolvedPaidAmount(invoice);
        final double unpaidAmount = math.max(
          0,
          invoice.totalAmount - paidAmount,
        );

        entry['invoiceCount'] = (entry['invoiceCount'] as int) + 1;
        entry['totalAmount'] =
            (entry['totalAmount'] as double) + invoice.totalAmount;
        entry['paidAmount'] = (entry['paidAmount'] as double) + paidAmount;
        entry['unpaidAmount'] =
            (entry['unpaidAmount'] as double) + unpaidAmount;
        grouped[key] = entry;
      }

      final List<TopClientRecord> result =
          grouped.values.map((Map<String, dynamic> value) {
            return TopClientRecord(
              clientId: value['clientId'] as String? ?? '',
              clientName: value['clientName'] as String? ?? 'Unknown',
              invoiceCount: value['invoiceCount'] as int? ?? 0,
              totalAmount: (value['totalAmount'] as num?)?.toDouble() ?? 0,
              paidAmount: (value['paidAmount'] as num?)?.toDouble() ?? 0,
              unpaidAmount: (value['unpaidAmount'] as num?)?.toDouble() ?? 0,
            );
          }).toList()..sort(
            (TopClientRecord a, TopClientRecord b) =>
                b.totalAmount.compareTo(a.totalAmount),
          );

      if (result.length <= limit) {
        return result;
      }
      return result.take(limit).toList();
    });
  }

  Stream<ReminderRecord?> streamNextReminder() {
    return streamReminders().map((List<ReminderRecord> reminders) {
      final DateTime now = DateTime.now();
      final List<ReminderRecord> active =
          reminders
              .where(
                (ReminderRecord reminder) =>
                    reminder.enabled && reminder.status.toLowerCase() != 'done',
              )
              .toList()
            ..sort((ReminderRecord a, ReminderRecord b) {
              final bool aIsPast = a.dueDate.isBefore(now);
              final bool bIsPast = b.dueDate.isBefore(now);
              if (aIsPast != bIsPast) {
                return aIsPast ? 1 : -1;
              }
              return a.dueDate.compareTo(b.dueDate);
            });
      if (active.isEmpty) {
        return null;
      }
      return active.first;
    });
  }

  Future<String> exportClientsCsv() async {
    final List<ClientRecord> clients = await streamClients().first;
    final StringBuffer csv = StringBuffer()
      ..writeln('clientId,name,email,phone,address,gstin,state,creditLimit');
    for (final ClientRecord client in clients) {
      csv.writeln(
        '${_csv(client.id)},${_csv(client.name)},${_csv(client.email)},${_csv(client.phone)},'
        '${_csv(client.address)},${_csv(client.gstin)},${_csv(client.segment)},${client.creditLimit}',
      );
    }
    return csv.toString();
  }

  Future<String> exportInvoicesCsv() async {
    final List<InvoiceRecord> invoices = await streamInvoices().first;
    final StringBuffer csv = StringBuffer()
      ..writeln(
        'invoiceId,invoiceNumber,client,status,issueDate,dueDate,totalAmount,gstPercent',
      );
    for (final InvoiceRecord invoice in invoices) {
      csv.writeln(
        '${_csv(invoice.id)},${_csv(invoice.number)},${_csv(invoice.client)},${_csv(invoice.status)},'
        '${invoice.date.toIso8601String()},${invoice.dueDate.toIso8601String()},'
        '${invoice.totalAmount},${invoice.gstPercent}',
      );
    }
    return csv.toString();
  }

  Future<String> exportRevenueCsv() async {
    final List<InvoiceRecord> invoices = await streamInvoices().first;
    final Map<String, double> revenueByMonth = <String, double>{};
    final Map<String, double> unpaidByMonth = <String, double>{};
    for (final InvoiceRecord invoice in invoices) {
      final String key =
          '${invoice.date.year}-${invoice.date.month.toString().padLeft(2, '0')}';
      revenueByMonth[key] = (revenueByMonth[key] ?? 0) + invoice.totalAmount;
      final double pending = invoice.balanceAmount > 0
          ? invoice.balanceAmount
          : math.max(0, invoice.totalAmount - _resolvedPaidAmount(invoice));
      unpaidByMonth[key] = (unpaidByMonth[key] ?? 0) + pending;
    }
    final List<String> keys = revenueByMonth.keys.toList()..sort();
    final StringBuffer csv = StringBuffer()
      ..writeln('month,totalRevenue,unpaidRevenue');
    for (final String key in keys) {
      csv.writeln(
        '$key,${revenueByMonth[key] ?? 0},${unpaidByMonth[key] ?? 0}',
      );
    }
    return csv.toString();
  }

  DateTime _nextInvoiceDate(DateTime current, String frequency) {
    switch (frequency) {
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);
      case 'monthly':
      default:
        return DateTime(current.year, current.month + 1, current.day);
    }
  }

  String _csv(String value) {
    final String escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  bool _isWithinRange(DateTime value, DateTime? startDate, DateTime? endDate) {
    if (startDate != null) {
      final DateTime normalizedStart = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      if (value.isBefore(normalizedStart)) {
        return false;
      }
    }
    if (endDate != null) {
      final DateTime normalizedEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
      if (value.isAfter(normalizedEnd)) {
        return false;
      }
    }
    return true;
  }

  double _resolvedPaidAmount(InvoiceRecord invoice) {
    if (invoice.paidAmount > 0) {
      return math.min(invoice.totalAmount, invoice.paidAmount);
    }
    if (invoice.status.toLowerCase() == 'paid') {
      return invoice.totalAmount;
    }
    return 0;
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
