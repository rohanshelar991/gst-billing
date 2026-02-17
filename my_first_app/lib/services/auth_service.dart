import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String businessName,
    required String gstin,
    String role = 'owner',
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

    final User? user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await _createUserProfile(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
        businessName: businessName,
        gstin: gstin,
        role: role,
      );
    }

    return credential;
  }

  Future<void> _createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String businessName,
    required String gstin,
    required String role,
  }) async {
    await _firestore.collection('users').doc(uid).set(<String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'businessName': businessName.trim(),
      'gstin': gstin.trim().toUpperCase(),
      'createdAt': Timestamp.now(),
      'role': role,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> logout() => _auth.signOut();
}
