import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = _auth.currentUser;
      if (user != null) {
        final token = await FirebaseMessaging.instance.getToken();
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Email invalide.');
        case 'user-not-found':
          throw Exception('Aucun utilisateur avec cet email.');
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Email ou mot de passe incorrect.');
        case 'too-many-requests':
          throw Exception('Trop de tentatives. Reessayez plus tard.');
        default:
          throw Exception(e.message ?? 'Connexion impossible.');
      }
    } catch (_) {
      throw Exception('Connexion impossible.');
    }
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;
      final token = await FirebaseMessaging.instance.getToken();

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'role': role,
        'isApproved': role == 'provider' ? false : true,
        'createdAtIso': DateTime.now().toIso8601String(),
        'fcmToken': token,
      });

      if (role == 'provider') {
        await _firestore.collection('providers').doc(uid).set({
          'uid': uid,
          'fullName': fullName.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'vehicleType': '',
          'plate': '',
          'avatarText': _avatarText(fullName),
          'isApproved': false,
          'isOnline': false,
          'isBusy': false,
          'rating': 5.0,
          'ratingCount': 0,
          'missionsCompleted': 0,
          'position': {
            'lat': 36.7538,
            'lng': 3.0588,
          },
        });
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('Cet email est deja utilise.');
        case 'invalid-email':
          throw Exception('Email invalide.');
        case 'weak-password':
          throw Exception('Mot de passe trop faible.');
        default:
          throw Exception(e.message ?? 'Inscription impossible.');
      }
    } catch (_) {
      throw Exception('Inscription impossible.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;

    return AppUser.fromMap(data);
  }

  Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    return (data?['role'] ?? 'customer').toString();
  }

  String _avatarText(String fullName) {
    final parts = fullName
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .toList();

    if (parts.isEmpty) return 'PR';
    return parts.join();
  }
}