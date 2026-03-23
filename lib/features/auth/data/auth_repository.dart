import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap(_mapUser);
  }

  AppUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      currencyCode: 'USD',
      firstName: '',
      lastName: '',
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String currencyCode,
    required String firstName,
    required String lastName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _users.doc(credential.user!.uid).set({
      'email': email,
      'currencyCode': currencyCode,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<AppUser?> _mapUser(User? user) async {
    if (user == null) {
      return null;
    }

    try {
      final snapshot = await _users.doc(user.uid).get();
      final data = snapshot.data();

      return AppUser(
        id: user.uid,
        email: user.email ?? data?['email'] as String? ?? '',
        currencyCode: data?['currencyCode'] as String? ?? 'USD',
        firstName: data?['firstName'] as String? ?? '',
        lastName: data?['lastName'] as String? ?? '',
      );
    } on FirebaseException {
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        currencyCode: 'USD',
        firstName: '',
        lastName: '',
      );
    }
  }

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }
}
