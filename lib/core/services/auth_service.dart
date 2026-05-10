import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    SharedPreferences? sharedPreferences,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _sharedPreferences = sharedPreferences;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final SharedPreferences? _sharedPreferences;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;
  User? get currentUser => _auth.currentUser;

  String? _verificationId;

  Future<String> sendPhoneOTP({
    required String phoneNumber,
    required void Function(String verificationId, int? smsCodeCount) onCodeSent,
    required void Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _normalizePhone(phoneNumber),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseException e) {
          onError(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? smsCodeCount) {
          _verificationId = verificationId;
          onCodeSent(verificationId, smsCodeCount);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      return _verificationId!;
    } on FirebaseAuthException catch (e) {
      throw Exception(_phoneAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<UserCredential?> verifyPhoneOTP({
    required String smsCode,
    String? verificationId,
  }) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId ?? _verificationId!,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw Exception(_phoneAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<void> signInWithPhoneOTP({
    required String phoneNumber,
    required String smsCode,
    String? verificationId,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId ?? _verificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);

      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _auth.signOut();
          throw Exception('Profil utilisateur introuvable dans Firestore.');
        }

        final userData = userDoc.data() ?? <String, dynamic>{};

        if (userData['isBlocked'] == true) {
          await _auth.signOut();
          throw Exception('Ce compte a ete bloque par l administration.');
        }

        final token = await _readFcmTokenSafely();
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastLoginAtIso': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_phoneAuthErrorMessage(e));
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithPhoneOTP({
    required String phoneNumber,
    required String smsCode,
    required String fullName,
    required String email,
    required String role,
    String? verificationId,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId ?? _verificationId!,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;
      final normalizedPhone = _normalizePhone(phoneNumber.trim());

      await userCredential.user!.linkWithCredential(
        EmailAuthProvider.credential(
          email: email.trim(),
          password: phoneNumber,
        ),
      );

      final token = await _readFcmTokenSafely();

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName.trim(),
        'phone': normalizedPhone,
        'email': email.trim(),
        'role': role,
        'isApproved': role == 'provider' ? false : true,
        'isBlocked': false,
        'createdAtIso': DateTime.now().toIso8601String(),
        'updatedAtIso': DateTime.now().toIso8601String(),
        'fcmToken': token,
        'authMethod': 'email_password',
      });

      await _firestore.collection('phone_lookup').doc(normalizedPhone).set({
        'email': email.trim(),
        'uid': uid,
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
          'isBlocked': false,
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
          'vehicleImageUrl': '',
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_phoneAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Sign up with phone failed: $e');
    }
  }

  Future<void> resetPasswordWithPhone({
    required String phoneNumber,
    required String smsCode,
    required String newPassword,
    String? verificationId,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId ?? _verificationId!,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);

      await userCredential.user!.updatePassword(newPassword);

      final user = userCredential.user;
      final email = (await _firestore.collection('users').doc(user!.uid).get())
          .data()?['email'] as String?;

      if (email != null && email.isNotEmpty) {
        await user.linkWithCredential(
          EmailAuthProvider.credential(email: email, password: newPassword),
        );
      }

      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_phoneAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  String _phoneAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Numero de telephone invalide.';
      case 'missing-phone-number':
        return 'Numero de telephone requis.';
      case 'invalid-verification-code':
        return 'Code OTP invalide.';
      case 'invalid-verification-id':
        return 'ID de verification invalide.';
      case 'code-expired':
        return 'Code expire. Veuillez renvoyer un nouveau code.';
      case 'too-many-requests':
        return 'Trop de tentatives. Reessayez plus tard.';
      case 'credential-already-in-use':
        return 'Ce numero est deja utilise.';
      default:
        return e.message ?? 'Erreur d authentification phone.';
    }
  }

  Future<void> sendEmailOTP({
    required String email,
    required void Function() onSent,
    required void Function(String error) onError,
  }) async {
    try {
      final otpCode =
          (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
              .toString();

      await _firestore.collection('email_otps').doc(email.trim()).set({
        'code': otpCode,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 5)),
        ),
      });

      await _sharedPreferences?.setString('email_for_signin', email.trim());
      await _sharedPreferences?.setString('email_otp_code', otpCode);

      if (kDebugMode) {
        print('DEBUG: Generated OTP code for ${email.trim()}: $otpCode');
      }

      onSent();
    } on FirebaseAuthException catch (e) {
      onError(_emailAuthErrorMessage(e));
    } catch (e) {
      onError('Failed to send email OTP: $e');
    }
  }

  Future<bool> verifyEmailOTPCode({
    required String email,
    required String otpCode,
  }) async {
    try {
      final otpDoc =
          await _firestore.collection('email_otps').doc(email.trim()).get();

      if (!otpDoc.exists) {
        return false;
      }

      final data = otpDoc.data()!;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        await _firestore.collection('email_otps').doc(email.trim()).delete();
        return false;
      }

      if (storedCode != otpCode) {
        return false;
      }

      await _firestore.collection('email_otps').doc(email.trim()).delete();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signInWithEmailOTP({
    required String email,
    required String password,
  }) async {
    throw Exception('Use signInWithEmailPassword after verifying OTP code');
  }

  Future<UserCredential?> signUpWithEmailOTP({
    required String email,
    required String otpCode,
    required String fullName,
    required String phone,
    required String role,
    required String password,
    Uint8List? providerVehicleImageBytes,
    String? providerVehicleImageName,
  }) async {
    try {
      final isValid = await verifyEmailOTPCode(email: email, otpCode: otpCode);
      if (!isValid) {
        throw Exception('Code OTP invalide ou expire.');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;
      final normalizedPhone = _normalizePhone(phone.trim());

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
        'isBlocked': false,
        'createdAtIso': DateTime.now().toIso8601String(),
        'updatedAtIso': DateTime.now().toIso8601String(),
        'fcmToken': token,
        'authMethod': 'email_password',
        if (vehicleImageUrl != null) 'providerVehicleImageUrl': vehicleImageUrl,
      });

      await _firestore.collection('phone_lookup').doc(normalizedPhone).set({
        'email': email.trim(),
        'uid': uid,
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
          'isBlocked': false,
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

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_emailAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Sign up with email failed: $e');
    }
  }

  Future<void> loginWithEmailOTP({
    required String email,
    required String otpCode,
    required String password,
  }) async {
    final isValid = await verifyEmailOTPCode(email: email, otpCode: otpCode);
    if (!isValid) {
      throw Exception('Code OTP invalide ou expire.');
    }

    await signInWithEmailPassword(
      identifier: email,
      password: password,
    );
  }

  String _emailAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email invalide.';
      case 'user-not-found':
        return 'Aucun compte trouve avec cet email.';
      case 'invalid-action-code':
        return 'Lien de verification invalide ou expire.';
      case 'expired-action-code':
        return 'Lien de verification expire.';
      case 'too-many-requests':
        return 'Trop de tentatives. Reessayez plus tard.';
      case 'email-already-in-use':
        return 'Cet email est deja utilise.';
      default:
        return e.message ?? 'Erreur d authentification email.';
    }
  }

  Future<String?> getDebugEmailOTP(String email) async {
    try {
      return _sharedPreferences?.getString('email_otp_code');
    } catch (_) {
      return null;
    }
  }

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
        'isBlocked': false,
        'createdAtIso': DateTime.now().toIso8601String(),
        'updatedAtIso': DateTime.now().toIso8601String(),
        'fcmToken': token,
        if (vehicleImageUrl != null) 'providerVehicleImageUrl': vehicleImageUrl,
      });

      await _firestore.collection('phone_lookup').doc(normalizedPhone).set({
        'email': email.trim(),
        'uid': uid,
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
          'isBlocked': false,
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
          'providers/$uid/vehicle_${DateTime.now().millisecondsSinceEpoch}_$safeName',
        );

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
    final trimmed = identifier.trim();

    if (trimmed.contains('@')) {
      return trimmed;
    }

    final normalizedPhone = _normalizePhone(trimmed);

    final lookupDoc =
        await _firestore.collection('phone_lookup').doc(normalizedPhone).get();

    if (lookupDoc.exists) {
      final email = (lookupDoc.data()?['email'] ?? '').toString().trim();
      if (email.isNotEmpty) return email;
    }

    throw Exception('Aucun utilisateur avec cet email ou numero.');
  }

  String _normalizePhone(String input) {
    var phone = input.trim().replaceAll(RegExp(r'\D'), '');

    if (phone.startsWith('00')) {
      phone = phone.substring(2);
    }

    if (phone.startsWith('2130')) {
      phone = '213${phone.substring(4)}';
    } else if (phone.startsWith('213')) {
      // Already Algeria international format.
    } else if (phone.startsWith('0')) {
      phone = '213${phone.substring(1)}';
    } else if (phone.startsWith('6') ||
        phone.startsWith('5') ||
        phone.startsWith('7')) {
      phone = '213$phone';
    } else {
      phone = '213$phone';
    }

    return '+$phone';
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
