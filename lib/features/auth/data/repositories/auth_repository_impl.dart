import 'dart:convert';
import 'dart:math';

import 'package:acepool/core/constants/api_keys.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';

import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/signup_details.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_error_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    FirebaseFirestore? db,
    FirebaseAuth? firebaseAuth,
    http.Client? httpClient,
  })  : _db = db ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            ),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _db;
  final FirebaseAuth _firebaseAuth;
  final http.Client _httpClient;

  String _toWorkEmail(String username) => '$username@ascendion.com';

  @override
  Future<AuthUser> signIn({
    required String username,
    required String password,
    OnboardingSelection? onboardingSelection,
  }) async {
    try {
      final credential = await _firebaseAuth
          .signInWithEmailAndPassword(
            email: _toWorkEmail(username),
            password: password,
          );
      final user = credential.user!;

      if (onboardingSelection != null) {
        await _db.collection('users').doc(user.uid).set({
          'travelPreference': onboardingSelection.travelPreference.name,
          'vehicleType': onboardingSelection.vehicleType.name,
        }, SetOptions(merge: true));
      }

      return AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        AuthErrorMapper.map(e, fallback: 'Login failed. Please try again.'),
      );
    }
  }

  static const _ssoCancelledCodes = {
    'web-context-canceled',
    'user-cancelled',
    'canceled',
    'cancelled',
  };

  @override
  Future<AuthUser> signInWithMicrosoft() async {
    final provider = OAuthProvider('microsoft.com')
      ..setCustomParameters({
        'tenant': ApiKeys.azureTenantId,
        'domain_hint': 'ascendion.com',
      });

    try {
      final credential = await _firebaseAuth.signInWithProvider(provider);
      final user = credential.user!;
      final email = user.email ?? '';

      if (!email.toLowerCase().endsWith('@ascendion.com')) {
        await _firebaseAuth.signOut();
        throw const AuthException(
          'Please sign in with your Ascendion work account.',
        );
      }

      await _ensureUserDoc(user);

      return AuthUser(uid: user.uid, email: email, displayName: user.displayName);
    } on FirebaseAuthException catch (e) {
      if (_ssoCancelledCodes.contains(e.code)) {
        throw const SsoCancelledException();
      }
      throw AuthException(
        AuthErrorMapper.map(
          e,
          fallback: 'Microsoft sign-in failed. Please try again.',
        ),
      );
    }
  }

  Future<void> _ensureUserDoc(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) return;

    await ref.set({
      'fullName': user.displayName ?? '',
      'email': user.email,
      'authProvider': 'microsoft',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<AuthUser> signUp(SignupDetails details) async {
    try {
      final email = _toWorkEmail(details.emailUsername);
      final credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email,
            password: details.password,
          );
      final uid = credential.user!.uid;

      // Update display name so home screen shows the correct name immediately
      await credential.user!.updateDisplayName(details.fullName);

      final userData = <String, dynamic>{
        'fullName': details.fullName,
        'employeeId': details.employeeId,
        'phone': details.phone,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final selection = details.onboardingSelection;
      if (selection != null) {
        userData['travelPreference'] = selection.travelPreference.name;
        userData['vehicleType'] = selection.vehicleType.name;
      }

      if (details.licenseVerified != null) {
        userData['licenceVerified'] = details.licenseVerified;
        if (details.licenseNumber != null) {
          userData['licenceNumber'] = details.licenseNumber;
        }
      }

      await _db.collection('users').doc(uid).set(userData);

      return AuthUser(uid: uid, email: email, displayName: details.fullName);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        AuthErrorMapper.map(e, fallback: 'Sign up failed. Please try again.'),
      );
    } catch (e) {
      throw const AuthException('Sign up failed. Please try again.');
    }
  }

  @override
  Future<void> sendOtp({required String email, required String uid}) async {
    final otp = _generateOtp();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    try {
      await _db.collection('otps').doc(uid).set({
        'otp': otp,
        'expiresAt': Timestamp.fromDate(expiry),
        'email': email,
      });

      await _sendOtpEmail(email, otp);
    } catch (e) {
      debugPrint('OTP send error: $e');
    }
  }

  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  Future<void> _sendOtpEmail(String email, String otp) async {
    debugPrint('Sending OTP $otp to $email');

    final response = await _httpClient.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': ApiKeys.emailJsServiceId,
        'template_id': ApiKeys.emailJsTemplateId,
        'user_id': ApiKeys.emailJsPublicKey,
        'accessToken': ApiKeys.emailJsPrivateKey,
        'template_params': {
          'to_email': email,
          'otp': otp,
          'passcode': otp,
          'otp_code': otp,
          'company_name': 'AcePool',
          'valid_minutes': '15',
        },
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('EmailJS error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to send OTP email');
    }
  }

  @override
  Future<bool> verifyOtp({
    required String uid,
    required String enteredOtp,
  }) async {
    try {
      final doc = await _db.collection('otps').doc(uid).get();

      if (!doc.exists) {
        throw const AuthException('OTP not found. Please resend.');
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        throw const AuthException('OTP has expired. Please resend.');
      }

      if (enteredOtp != storedOtp) {
        throw const AuthException('Incorrect OTP. Please try again.');
      }

      await doc.reference.delete();
      return true;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException('Verification failed. Please try again.');
    }
  }

  @override
  Future<void> cancelSignup({required String uid}) async {
    try {
      await _db.collection('otps').doc(uid).delete();
      await _db.collection('users').doc(uid).delete();
      await _firebaseAuth.currentUser?.delete();
    } catch (_) {}
  }
}
