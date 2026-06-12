// lib/src/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  // ── Admin bypass credentials ────────────────────────────────────────────────
  static const String _adminEmail = 'prosenjit@gmail.com';
  static const String _adminPassword = '123456';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new clinical professional
  Future<String?> signUp({
    required String email,
    required String password,
    required String role, // 'doctor', 'radiologist', 'researcher'
    required String name,
    String? institution,
    String? specialization,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return 'Unexpected error: user is null';

      // Create user profile in Firestore - email verification is the only requirement
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set({
        'email': email,
        'role': role,
        'name': name,
        'institution': institution ?? '',
        'specialization': specialization ?? '',
        'photoUrl': '',
        'approved': true,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'system',
      });

      // Send verification email
      await user.sendEmailVerification();

      // Sign out — must verify email first
      await _auth.signOut();

      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return _firebaseErrorMessage(e);
    } catch (e) {
      return 'Sign-up failed: $e';
    }
  }

  /// Login — checks email verification only.
  /// Admin account (prosenjit@gmail.com) bypasses verification.
  Future<String?> login(String email, String password) async {
    final isAdmin = email.trim().toLowerCase() == _adminEmail.toLowerCase() &&
        password == _adminPassword;

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) return 'Unexpected error.';

      // ── Admin bypass: skip email verification + approval ────────────────
      if (isAdmin) {
        // Ensure admin Firestore document exists with full access
        final docRef = _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'email': email.trim(),
            'role': AppConstants.roleDoctor,
            'name': 'Dr. Prosenjit (Admin)',
            'institution': 'NeuroVision AI',
            'specialization': 'System Administrator',
            'photoUrl': '',
            'approved': true,
            'isAdmin': true,
            'createdAt': FieldValue.serverTimestamp(),
            'approvedAt': FieldValue.serverTimestamp(),
            'approvedBy': 'system',
          });
        } else {
          // Ensure existing doc is approved + isAdmin
          await docRef.update({'approved': true, 'isAdmin': true});
        }
        return null; // success — skip all other checks
      }

      // ── Regular user flow ──────────────────────────────────────────────
      await user.reload();
      final fresh = _auth.currentUser;
      if (fresh == null) {
        await _auth.signOut();
        return 'Session error.';
      }

      if (!fresh.emailVerified) {
        await _auth.signOut();
        return 'Please verify your email first. Check your inbox.';
      }

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(fresh.uid)
          .get();

      if (!doc.exists) {
        await _auth.signOut();
        return 'Profile not found. Contact support.';
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      // Admin: if account doesn't exist yet in Firebase Auth, create it
      if (isAdmin &&
          (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
        return await _createAdminAccount(email.trim(), password);
      }
      return _firebaseErrorMessage(e);
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  /// Creates the admin Firebase Auth account + Firestore profile on first run.
  Future<String?> _createAdminAccount(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return 'Failed to create admin account.';

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set({
        'email': email,
        'role': AppConstants.roleDoctor,
        'name': 'Dr. Prosenjit (Admin)',
        'institution': 'NeuroVision AI',
        'specialization': 'System Administrator',
        'photoUrl': '',
        'approved': true,
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'system',
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _firebaseErrorMessage(e);
    } catch (e) {
      return 'Admin setup failed: $e';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Google Sign-In
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return 'Sign-in failed';

      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // New user - needs role assignment; default to researcher
        await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set({
          'email': user.email ?? '',
          'role': AppConstants.roleResearcher,
          'name': user.displayName ?? '',
          'institution': '',
          'specialization': '',
          'photoUrl': user.photoURL ?? '',
          'approved': true,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': 'system',
        });
        return null;
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _firebaseErrorMessage(e);
    } catch (e) {
      return 'Google sign-in failed: $e';
    }
  }

  /// Fetch current NVUser profile
  Future<NVUser?> getCurrentNVUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;
      return NVUser.fromMap(user.uid, doc.data()!);
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  /// Stream of current user profile changes
  Stream<NVUser?> nvUserStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .snapshots()
        .map((snap) => snap.exists ? NVUser.fromMap(user.uid, snap.data()!) : null);
  }

  Future<String?> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return 'Not signed in.';
    try {
      await user.sendEmailVerification();
      return null;
    } catch (e) {
      return 'Failed to resend: $e';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _firebaseErrorMessage(e);
    }
  }

  Future<String?> updateProfile({
    required String uid,
    required String name,
    required String institution,
    required String specialization,
    String? photoUrl,
  }) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
        'name': name,
        'institution': institution,
        'specialization': specialization,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
      return null;
    } catch (e) {
      return 'Update failed: $e';
    }
  }

  Future<String?> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _firebaseErrorMessage(e);
    } catch (e) {
      return 'Password update failed: $e';
    }
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return 'Invalid email address.';
      case 'user-disabled': return 'Account disabled. Contact support.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return 'Invalid email or password.';
      case 'email-already-in-use': return 'Email already registered.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'too-many-requests': return 'Too many attempts. Please try later.';
      default: return e.message ?? 'Authentication error.';
    }
  }
}
