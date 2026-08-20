import 'dart:convert';

import 'package:acepool/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:acepool/features/auth/domain/entities/auth_exception.dart';
import 'package:acepool/features/auth/domain/entities/signup_details.dart';
import 'package:acepool/features/onboarding/domain/entities/travel_preference.dart';
import 'package:acepool/features/onboarding/domain/entities/vehicle_preference.dart';
import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

http.Client _okClient() {
  return MockClient((request) async {
    return http.Response('{}', 200);
  });
}

void main() {
  group('AuthRepositoryImpl.signIn', () {
    test('returns AuthUser mapped from the signed-in Firebase user', () async {
      final mockUser = MockUser(
        uid: 'uid-1',
        email: 'jdoe@ascendion.com',
        displayName: 'Jane Doe',
      );
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      final result = await repo.signIn(username: 'jdoe', password: 'secret1');

      expect(result.uid, 'uid-1');
      expect(result.email, 'jdoe@ascendion.com');
      expect(result.displayName, 'Jane Doe');
    });

    test('merges onboardingSelection into the users doc on success', () async {
      final mockUser = MockUser(uid: 'uid-2', email: 'jdoe@ascendion.com');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );
      const selection = OnboardingSelection(
        travelPreference: TravelPreference.drive,
        vehicleType: VehiclePreference.bike,
      );

      await repo.signIn(
        username: 'jdoe',
        password: 'secret1',
        onboardingSelection: selection,
      );

      final doc = await firestore.collection('users').doc('uid-2').get();
      expect(doc.data()!['travelPreference'], 'drive');
      expect(doc.data()!['vehicleType'], 'bike');
    });

    test('does not write to Firestore when onboardingSelection is null', () async {
      final mockUser = MockUser(uid: 'uid-3', email: 'jdoe@ascendion.com');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await repo.signIn(username: 'jdoe', password: 'secret1');

      final doc = await firestore.collection('users').doc('uid-3').get();
      expect(doc.exists, isFalse);
    });

    test('maps invalid-credential to a user-facing message', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      final repo = AuthRepositoryImpl(
        db: FakeFirebaseFirestore(),
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signIn(username: 'jdoe', password: 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid username or password',
          ),
        ),
      );
    });

    test('maps unmapped FirebaseAuthException codes to the login fallback', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      final repo = AuthRepositoryImpl(
        db: FakeFirebaseFirestore(),
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signIn(username: 'jdoe', password: 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Login failed. Please try again.',
          ),
        ),
      );
    });
  });

  group('AuthRepositoryImpl.signInWithMicrosoft', () {
    test('returns AuthUser and creates a users doc on first sign-in', () async {
      final mockUser = MockUser(
        uid: 'uid-sso-1',
        email: 'jdoe@ascendion.com',
        displayName: 'Jane Doe',
      );
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      final result = await repo.signInWithMicrosoft();

      expect(result.uid, 'uid-sso-1');
      expect(result.email, 'jdoe@ascendion.com');
      expect(result.displayName, 'Jane Doe');

      final doc = await firestore.collection('users').doc('uid-sso-1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['fullName'], 'Jane Doe');
      expect(doc.data()!['email'], 'jdoe@ascendion.com');
      expect(doc.data()!['authProvider'], 'microsoft');
    });

    test('does not overwrite an existing users doc on repeat sign-in', () async {
      final mockUser = MockUser(uid: 'uid-sso-2', email: 'jdoe@ascendion.com');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('uid-sso-2').set({
        'fullName': 'Existing Name',
        'employeeId': 'EMP999',
      });
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await repo.signInWithMicrosoft();

      final doc = await firestore.collection('users').doc('uid-sso-2').get();
      expect(doc.data()!['fullName'], 'Existing Name');
      expect(doc.data()!['employeeId'], 'EMP999');
    });

    test('signs out and throws when the account is outside ascendion.com', () async {
      final mockUser = MockUser(uid: 'uid-sso-3', email: 'jdoe@gmail.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final repo = AuthRepositoryImpl(
        db: FakeFirebaseFirestore(),
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signInWithMicrosoft(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Please sign in with your Ascendion work account.',
          ),
        ),
      );
      expect(auth.currentUser, isNull);
    });

    test('maps account-exists-with-different-credential to a user-facing message', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithProvider, null))
          .on(auth)
          .thenThrow(
            FirebaseAuthException(code: 'account-exists-with-different-credential'),
          );
      final repo = AuthRepositoryImpl(
        db: FakeFirebaseFirestore(),
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signInWithMicrosoft(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'An account already exists with this email using a different sign-in method.',
          ),
        ),
      );
    });

    test('throws SsoCancelledException when the user cancels the sign-in sheet', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithProvider, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'web-context-canceled'));
      final repo = AuthRepositoryImpl(
        db: FakeFirebaseFirestore(),
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signInWithMicrosoft(),
        throwsA(isA<SsoCancelledException>()),
      );
    });
  });

  group('AuthRepositoryImpl.signUp', () {
    const details = SignupDetails(
      fullName: 'Jane Doe',
      employeeId: 'EMP123',
      phone: '1234567890',
      emailUsername: 'jdoe',
      password: 'secret1',
    );

    test('creates the Firebase user, writes the users doc and returns AuthUser', () async {
      final auth = MockFirebaseAuth();
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      final result = await repo.signUp(details);

      expect(result.email, 'jdoe@ascendion.com');
      expect(result.displayName, 'Jane Doe');
      expect(auth.currentUser?.displayName, 'Jane Doe');

      final doc = await firestore.collection('users').doc(result.uid).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['fullName'], 'Jane Doe');
      expect(data['employeeId'], 'EMP123');
      expect(data['phone'], '1234567890');
      expect(data['email'], 'jdoe@ascendion.com');
      expect(data.containsKey('createdAt'), isTrue);
      expect(data.containsKey('travelPreference'), isFalse);
      expect(data.containsKey('licenceVerified'), isFalse);
    });

    test('includes onboardingSelection fields when provided', () async {
      final auth = MockFirebaseAuth();
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );
      const withSelection = SignupDetails(
        fullName: 'Jane Doe',
        employeeId: 'EMP123',
        phone: '1234567890',
        emailUsername: 'jdoe',
        password: 'secret1',
        onboardingSelection: OnboardingSelection(
          travelPreference: TravelPreference.both,
          vehicleType: VehiclePreference.car,
        ),
      );

      final result = await repo.signUp(withSelection);

      final doc = await firestore.collection('users').doc(result.uid).get();
      expect(doc.data()!['travelPreference'], 'both');
      expect(doc.data()!['vehicleType'], 'car');
    });

    test('writes licenceVerified and licenceNumber when licenseVerified is set', () async {
      final auth = MockFirebaseAuth();
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );
      const withLicense = SignupDetails(
        fullName: 'Jane Doe',
        employeeId: 'EMP123',
        phone: '1234567890',
        emailUsername: 'jdoe',
        password: 'secret1',
        licenseVerified: true,
        licenseNumber: 'DL12345',
      );

      final result = await repo.signUp(withLicense);

      final doc = await firestore.collection('users').doc(result.uid).get();
      expect(doc.data()!['licenceVerified'], isTrue);
      expect(doc.data()!['licenceNumber'], 'DL12345');
    });

    test('writes licenceVerified without licenceNumber when licenseNumber is null', () async {
      final auth = MockFirebaseAuth();
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );
      const withLicense = SignupDetails(
        fullName: 'Jane Doe',
        employeeId: 'EMP123',
        phone: '1234567890',
        emailUsername: 'jdoe',
        password: 'secret1',
        licenseVerified: false,
      );

      final result = await repo.signUp(withLicense);

      final doc = await firestore.collection('users').doc(result.uid).get();
      expect(doc.data()!['licenceVerified'], isFalse);
      expect(doc.data()!.containsKey('licenceNumber'), isFalse);
    });

    test('maps email-already-in-use to a user-facing message', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      final repo = AuthRepositoryImpl(
        db: FakeFirebaseFirestore(),
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signUp(details),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'An account with this email already exists.',
          ),
        ),
      );
    });

    test('maps weak-password to a user-facing message', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'weak-password'));
      final repo = AuthRepositoryImpl(
        db: FakeFirebaseFirestore(),
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signUp(details),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Password is too weak. Use at least 6 characters.',
          ),
        ),
      );
    });

    test('maps invalid-email to a user-facing message', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));
      final repo = AuthRepositoryImpl(
        db: FakeFirebaseFirestore(),
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signUp(details),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Please enter a valid email',
          ),
        ),
      );
    });

    test('maps unmapped FirebaseAuthException codes to the signup fallback', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      final repo = AuthRepositoryImpl(
        db: FakeFirebaseFirestore(),
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signUp(details),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Sign up failed. Please try again.',
          ),
        ),
      );
    });

    test('wraps non-FirebaseAuthException failures in the signup fallback message', () async {
      final auth = MockFirebaseAuth();
      final firestore = MockFirebaseFirestore();
      when(() => firestore.collection('users')).thenThrow(Exception('boom'));
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(
        repo.signUp(details),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Sign up failed. Please try again.',
          ),
        ),
      );
    });
  });

  group('AuthRepositoryImpl.sendOtp', () {
    test('writes an OTP doc and posts the email, swallowing all errors', () async {
      http.Request? capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      });
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: client,
      );

      await repo.sendOtp(email: 'jdoe@ascendion.com', uid: 'uid-1');

      final doc = await firestore.collection('otps').doc('uid-1').get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['email'], 'jdoe@ascendion.com');
      final otp = data['otp'] as String;
      expect(otp.length, 6);
      expect(int.tryParse(otp), isNotNull);
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      expect(expiresAt.isAfter(DateTime.now()), isTrue);

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.url,
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      );
      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      final templateParams =
          body['template_params'] as Map<String, dynamic>;
      expect(templateParams['to_email'], 'jdoe@ascendion.com');
      expect(templateParams['otp'], otp);
      expect(templateParams['passcode'], otp);
      expect(templateParams['otp_code'], otp);
      expect(templateParams['company_name'], 'AcePool');
    });

    test('does not throw when the email endpoint returns a non-200 response', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: client,
      );

      await expectLater(
        repo.sendOtp(email: 'jdoe@ascendion.com', uid: 'uid-1'),
        completes,
      );

      final doc = await firestore.collection('otps').doc('uid-1').get();
      expect(doc.exists, isTrue);
    });

    test('does not throw when Firestore write fails', () async {
      final firestore = MockFirebaseFirestore();
      when(() => firestore.collection('otps')).thenThrow(Exception('boom'));
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: _okClient(),
      );

      await expectLater(
        repo.sendOtp(email: 'jdoe@ascendion.com', uid: 'uid-1'),
        completes,
      );
    });
  });

  group('AuthRepositoryImpl.verifyOtp', () {
    test('throws not-found when there is no OTP doc', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: _okClient(),
      );

      await expectLater(
        repo.verifyOtp(uid: 'uid-1', enteredOtp: '123456'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'OTP not found. Please resend.',
          ),
        ),
      );
    });

    test('throws expired when the stored OTP has passed its expiry', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('otps').doc('uid-1').set({
        'otp': '123456',
        'email': 'jdoe@ascendion.com',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      });
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: _okClient(),
      );

      await expectLater(
        repo.verifyOtp(uid: 'uid-1', enteredOtp: '123456'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'OTP has expired. Please resend.',
          ),
        ),
      );
    });

    test('throws incorrect when the entered OTP does not match', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('otps').doc('uid-1').set({
        'otp': '123456',
        'email': 'jdoe@ascendion.com',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: _okClient(),
      );

      await expectLater(
        repo.verifyOtp(uid: 'uid-1', enteredOtp: '000000'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Incorrect OTP. Please try again.',
          ),
        ),
      );
    });

    test('returns true and deletes the doc when the OTP matches', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('otps').doc('uid-1').set({
        'otp': '123456',
        'email': 'jdoe@ascendion.com',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: _okClient(),
      );

      final result = await repo.verifyOtp(uid: 'uid-1', enteredOtp: '123456');

      expect(result, isTrue);
      final doc = await firestore.collection('otps').doc('uid-1').get();
      expect(doc.exists, isFalse);
    });

    test('wraps unexpected failures in the generic verification message', () async {
      final firestore = FakeFirebaseFirestore();
      // Malformed doc: 'otp' is not a String, forcing the cast in the
      // repository to throw and fall into the generic catch branch.
      await firestore.collection('otps').doc('uid-1').set({
        'otp': 123456,
        'email': 'jdoe@ascendion.com',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: _okClient(),
      );

      await expectLater(
        repo.verifyOtp(uid: 'uid-1', enteredOtp: '123456'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Verification failed. Please try again.',
          ),
        ),
      );
    });
  });

  group('AuthRepositoryImpl.cancelSignup', () {
    test('deletes the otp doc, user doc and auth account', () async {
      final mockUser = MockUser(uid: 'uid-1', email: 'jdoe@ascendion.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('otps').doc('uid-1').set({'otp': '123456'});
      await firestore.collection('users').doc('uid-1').set({'fullName': 'Jane'});
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await repo.cancelSignup(uid: 'uid-1');

      final otpDoc = await firestore.collection('otps').doc('uid-1').get();
      final userDoc = await firestore.collection('users').doc('uid-1').get();
      expect(otpDoc.exists, isFalse);
      expect(userDoc.exists, isFalse);
    });

    test('swallows errors thrown while deleting Firestore docs', () async {
      final firestore = MockFirebaseFirestore();
      when(() => firestore.collection('otps')).thenThrow(Exception('boom'));
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: _okClient(),
      );

      await expectLater(repo.cancelSignup(uid: 'uid-1'), completes);
    });

    test('swallows errors thrown while deleting the auth account', () async {
      final mockUser = MockUser(uid: 'uid-1', email: 'jdoe@ascendion.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      whenCalling(Invocation.method(#delete, []))
          .on(auth.currentUser!)
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        httpClient: _okClient(),
      );

      await expectLater(repo.cancelSignup(uid: 'uid-1'), completes);
    });

    test('does nothing to the auth account when no user is signed in', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = AuthRepositoryImpl(
        db: firestore,
        firebaseAuth: MockFirebaseAuth(),
        httpClient: _okClient(),
      );

      await expectLater(repo.cancelSignup(uid: 'uid-1'), completes);
    });
  });
}
