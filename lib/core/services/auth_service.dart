import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailPassword({
    required String identifier,
    required String password,
    bool allowAdmin = false,
    bool adminOnly = false,
  }) async {
    try {
      final email = await _resolveEmailForLogin(identifier.trim());
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );

      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _auth.signOut();
          throw Exception('Profil utilisateur introuvable dans Firestore.');
        }
        final userData = userDoc.data() ?? <String, dynamic>{};
        final role = (userData['role'] ?? '').toString().trim().toLowerCase();

        if (adminOnly && role != 'admin') {
          await _auth.signOut();
          throw Exception('Cette entree est reservee a l administration.');
        }

        if (!allowAdmin && role == 'admin') {
          await _auth.signOut();
          throw Exception(
            'Les admins doivent utiliser la connexion securisee admin.',
          );
        }

        if (userData['isBlocked'] == true) {
          await _auth.signOut();
          throw Exception('Ce compte a ete bloque par l administration.');
        }

        final token = await _readFcmTokenSafely();
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastLoginAtIso': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        if (role == 'provider' && userData['isApproved'] == true) {
          await _firestore.collection('providers').doc(user.uid).set({
            'uid': user.uid,
            'fullName': (userData['fullName'] ?? '').toString(),
            'phone': (userData['phone'] ?? '').toString(),
            'email': (userData['email'] ?? email).toString(),
            'avatarText': _avatarText((userData['fullName'] ?? '').toString()),
            'isApproved': true,
          }, SetOptions(merge: true));
        }
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Email ou numero invalide.');
        case 'user-not-found':
          throw Exception('Aucun utilisateur avec cet email ou numero.');
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Identifiant ou mot de passe incorrect.');
        case 'too-many-requests':
          throw Exception('Trop de tentatives. Reessayez plus tard.');
        default:
          throw Exception(e.message ?? 'Connexion impossible.');
      }
    } on FirebaseException catch (e) {
      throw Exception(_firebaseAccessMessage(e));
    } on Exception {
      rethrow;
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
    Uint8List? providerVehicleImageBytes,
    String? providerVehicleImageName,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phone.trim());
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;
      final token = await _readFcmTokenSafely();
      String? vehicleImageUrl;

      if (role == 'provider' && providerVehicleImageBytes != null) {
        vehicleImageUrl = await _uploadProviderVehicleImage(
          uid: uid,
          bytes: providerVehicleImageBytes,
          fileName: providerVehicleImageName,
        );
      }

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName.trim(),
        'phone': normalizedPhone,
        'email': email.trim(),
        'role': role,
        'isApproved': role == 'provider' ? false : true,
        'createdAtIso': DateTime.now().toIso8601String(),
        'updatedAtIso': DateTime.now().toIso8601String(),
        'fcmToken': token,
        if (vehicleImageUrl != null) 'providerVehicleImageUrl': vehicleImageUrl,
      });

      if (role == 'provider') {
        await _firestore.collection('providers').doc(uid).set({
          'uid': uid,
          'fullName': fullName.trim(),
          'phone': normalizedPhone,
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
          'createdAtIso': DateTime.now().toIso8601String(),
          'updatedAtIso': DateTime.now().toIso8601String(),
          'position': {
            'lat': 36.7538,
            'lng': 3.0588,
          },
          'vehicleImageUrl': vehicleImageUrl ?? '',
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
    } on FirebaseException catch (e) {
      throw Exception(_firebaseAccessMessage(e));
    } catch (_) {
      throw Exception('Inscription impossible.');
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Email invalide.');
        case 'user-not-found':
          throw Exception('Aucun compte trouve avec cet email.');
        case 'too-many-requests':
          throw Exception('Trop de tentatives. Reessayez plus tard.');
        default:
          throw Exception(
            e.message ?? 'Impossible d envoyer le lien de reinitialisation.',
          );
      }
    } catch (_) {
      throw Exception('Impossible d envoyer le lien de reinitialisation.');
    }
  }

  String _firebaseAccessMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Acces refuse par les regles de securite. Contactez l administrateur.';
      case 'unavailable':
        return 'Connexion internet indisponible. Verifiez le reseau puis reessayez.';
      case 'deadline-exceeded':
        return 'Connexion trop lente. Reessayez dans quelques instants.';
      default:
        return e.message ?? 'Operation Firebase impossible.';
    }
  }

  Future<String?> _readFcmTokenSafely() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<String> _uploadProviderVehicleImage({
    required String uid,
    required Uint8List bytes,
    String? fileName,
  }) async {
    final safeName = (fileName ?? 'vehicle.jpg').replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    final ref = _storage.ref().child(
        'providers/$uid/vehicle_${DateTime.now().millisecondsSinceEpoch}_$safeName');

    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return ref.getDownloadURL();
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
    return (data?['role'] ?? 'customer').toString().trim().toLowerCase();
  }

  Future<String> _resolveEmailForLogin(String identifier) async {
    if (identifier.contains('@')) {
      return identifier;
    }

    final normalizedPhone = _normalizePhone(identifier);
    final phoneQuery = await _firestore
        .collection('users')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (phoneQuery.docs.isNotEmpty) {
      final email = (phoneQuery.docs.first.data()['email'] ?? '').toString();
      if (email.isNotEmpty) return email;
    }

    throw Exception('Aucun utilisateur avec cet email ou numero.');
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\s+'), '');
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
