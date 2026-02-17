import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'auth_service.dart';

class MessagingService {
  MessagingService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    required AuthService authService,
  }) : _messagingOverride = messaging,
       _firestoreOverride = firestore,
       _authService = authService;

  final FirebaseMessaging? _messagingOverride;
  final FirebaseFirestore? _firestoreOverride;
  final AuthService _authService;

  StreamSubscription<String>? _tokenSubscription;
  bool _initialized = false;

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final String? initialToken = await _messaging.getToken();
    await _saveToken(initialToken);

    _tokenSubscription = _messaging.onTokenRefresh.listen((String token) {
      _saveToken(token);
    });
  }

  Future<void> _saveToken(String? token) async {
    final String? uid = _authService.currentUser?.uid;
    if (uid == null || token == null || token.isEmpty) {
      return;
    }

    await _firestore.collection('users').doc(uid).set(<String, dynamic>{
      'fcmToken': token,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
  }
}
