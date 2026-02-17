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

  Stream<User?> authStateChanges() {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return Stream<User?>.value(null);
    }
  }

  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

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
    String role = 'admin',
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

    final User? user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      try {
        await _createUserProfile(
          uid: user.uid,
          name: name,
          email: email,
          phone: phone,
          businessName: businessName,
          gstin: gstin,
          role: role,
        );
      } on FirebaseException catch (error) {
        try {
          await user.delete();
        } catch (_) {}
        throw FirebaseAuthException(
          code: 'profile-setup-failed',
          message:
              'Authentication succeeded but Firestore profile setup failed (${error.code}). '
              'Check Firestore setup and rules, then try again.',
        );
      }
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
