import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coinly/features/auth/domain/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  bool _isGoogleInitialized = false;

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
      currencyCode: '',
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

  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google Sign-In did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    await _ensureUserProfile(
      user: userCredential.user!,
      displayName: googleUser.displayName,
    );
  }

  Future<AppUser> updateCurrencyCode({
    required String userId,
    required String currencyCode,
  }) async {
    await _users.doc(userId).set({
      'currencyCode': currencyCode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final refreshed = await _mapUser(_firebaseAuth.currentUser);
    if (refreshed == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found.',
      );
    }

    return refreshed;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _ensureGoogleInitialized();
    await _googleSignIn.signOut();
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_isGoogleInitialized) {
      return;
    }

    await _googleSignIn.initialize();
    _isGoogleInitialized = true;
  }

  Future<void> _ensureUserProfile({
    required User user,
    String? displayName,
  }) async {
    final doc = _users.doc(user.uid);
    final snapshot = await doc.get();
    final data = snapshot.data();
    final parsedName = _splitName(displayName ?? user.displayName);

    await doc.set({
      'email': user.email ?? data?['email'] as String? ?? '',
      'currencyCode': data?['currencyCode'] as String? ?? '',
      'firstName': data?['firstName'] as String? ?? parsedName.$1,
      'lastName': data?['lastName'] as String? ?? parsedName.$2,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  (String, String) _splitName(String? fullName) {
    final normalized = (fullName ?? '').trim();
    if (normalized.isEmpty) {
      return ('', '');
    }

    final parts = normalized.split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
    return (firstName, lastName);
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
        currencyCode: data?['currencyCode'] as String? ?? '',
        firstName: data?['firstName'] as String? ?? '',
        lastName: data?['lastName'] as String? ?? '',
      );
    } on FirebaseException {
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        currencyCode: '',
        firstName: '',
        lastName: '',
      );
    }
  }

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }
}
