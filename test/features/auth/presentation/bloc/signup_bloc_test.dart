import 'dart:io';

import 'package:acepool/core/usecases/scan_license_usecase.dart';
import 'package:acepool/core/utils/license_scanner.dart';
import 'package:acepool/features/auth/domain/entities/auth_exception.dart';
import 'package:acepool/features/auth/domain/entities/auth_user.dart';
import 'package:acepool/features/auth/domain/entities/signup_details.dart';
import 'package:acepool/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:acepool/features/auth/presentation/bloc/signup_bloc.dart';
import 'package:acepool/features/onboarding/domain/entities/travel_preference.dart';
import 'package:acepool/features/onboarding/domain/entities/vehicle_preference.dart';
import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockScanLicenseUseCase extends Mock implements ScanLicenseUseCase {}

class FakeSignupDetails extends Fake implements SignupDetails {}

void main() {
  late MockSignUpUseCase signUp;
  late MockScanLicenseUseCase scanLicense;

  setUpAll(() {
    registerFallbackValue(FakeSignupDetails());
  });

  setUp(() {
    signUp = MockSignUpUseCase();
    scanLicense = MockScanLicenseUseCase();
  });

  const user = AuthUser(uid: 'uid-1', email: 'jdoe@ascendion.com');

  SignupBloc buildBloc() =>
      SignupBloc(signUp: signUp, scanLicense: scanLicense);

  const validEvent = SignupSubmitted(
    fullName: 'Jane Doe',
    employeeId: 'EMP123',
    phone: '1234567890',
    emailUsername: 'jdoe',
    password: 'secret1',
    confirmPassword: 'secret1',
    showLicenseSection: false,
  );

  group('SignupEvent equality', () {
    test('SignupSubmitted supports value equality based on props', () {
      expect(validEvent, validEvent);
      expect(
        validEvent.props,
        [
          'Jane Doe',
          'EMP123',
          '1234567890',
          'jdoe',
          'secret1',
          'secret1',
          false,
          null,
        ],
      );
      expect(
        validEvent,
        isNot(const SignupSubmitted(
          fullName: 'Other',
          employeeId: 'EMP123',
          phone: '1234567890',
          emailUsername: 'jdoe',
          password: 'secret1',
          confirmPassword: 'secret1',
          showLicenseSection: false,
        )),
      );
    });

    test('SignupFieldChanged supports value equality', () {
      expect(const SignupFieldChanged(), const SignupFieldChanged());
    });

    test(
      'SignupLicenseImagePicked supports value equality based on props '
      '(imageFile path, not identity)',
      () {
        final pickedA = SignupLicenseImagePicked(isFront: true, imageFile: File('a.jpg'));
        final pickedB = SignupLicenseImagePicked(isFront: true, imageFile: File('a.jpg'));
        expect(pickedA, pickedB);
        expect(pickedA.props, [true, 'a.jpg']);
        expect(
          pickedA,
          isNot(SignupLicenseImagePicked(isFront: false, imageFile: File('a.jpg'))),
        );
        expect(
          pickedA,
          isNot(SignupLicenseImagePicked(isFront: true, imageFile: File('b.jpg'))),
        );
      },
    );
  });

  group('SignupSubmitted validation', () {
    blocTest<SignupBloc, SignupState>(
      'emits field errors for every empty field',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignupSubmitted(
          fullName: '',
          employeeId: '',
          phone: '',
          emailUsername: '',
          password: '',
          confirmPassword: '',
          showLicenseSection: false,
        ),
      ),
      expect: () => [
        const SignupState(
          fullNameError: 'Full name is required',
          employeeIdError: 'Employee ID is required',
          phoneError: 'Phone number is required',
          emailError: 'Work email username is required',
          passwordError: 'Password is required',
          confirmPasswordError: 'Please confirm your password',
        ),
      ],
      verify: (_) {
        verifyNever(() => signUp(any()));
      },
    );

    blocTest<SignupBloc, SignupState>(
      'flags an invalid phone number length',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignupSubmitted(
          fullName: 'Jane Doe',
          employeeId: 'EMP123',
          phone: '12345',
          emailUsername: 'jdoe',
          password: 'secret1',
          confirmPassword: 'secret1',
          showLicenseSection: false,
        ),
      ),
      expect: () => [
        const SignupState(
          phoneError: 'Enter a valid 10-digit phone number',
        ),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'flags a too-short password',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignupSubmitted(
          fullName: 'Jane Doe',
          employeeId: 'EMP123',
          phone: '1234567890',
          emailUsername: 'jdoe',
          password: '123',
          confirmPassword: '123',
          showLicenseSection: false,
        ),
      ),
      expect: () => [
        const SignupState(
          passwordError: 'Password must be at least 6 characters',
        ),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'flags mismatched confirm password',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignupSubmitted(
          fullName: 'Jane Doe',
          employeeId: 'EMP123',
          phone: '1234567890',
          emailUsername: 'jdoe',
          password: 'secret1',
          confirmPassword: 'other12',
          showLicenseSection: false,
        ),
      ),
      expect: () => [
        const SignupState(confirmPasswordError: 'Passwords do not match'),
      ],
    );

    final frontFile = File('front.jpg');
    final backFile = File('back.jpg');
    blocTest<SignupBloc, SignupState>(
      'preserves license state when re-emitting field errors',
      build: buildBloc,
      seed: () => SignupState(
        frontLicenseImage: frontFile,
        backLicenseImage: backFile,
        frontLicenseValid: true,
        backLicenseValid: false,
        licenseNumber: 'DL12345',
      ),
      act: (bloc) => bloc.add(
        const SignupSubmitted(
          fullName: '',
          employeeId: 'EMP123',
          phone: '1234567890',
          emailUsername: 'jdoe',
          password: 'secret1',
          confirmPassword: 'secret1',
          showLicenseSection: false,
        ),
      ),
      expect: () => [
        SignupState(
          fullNameError: 'Full name is required',
          frontLicenseImage: frontFile,
          backLicenseImage: backFile,
          frontLicenseValid: true,
          backLicenseValid: false,
          licenseNumber: 'DL12345',
        ),
      ],
    );
  });

  group('SignupSubmitted success/failure', () {
    blocTest<SignupBloc, SignupState>(
      'emits [submitting, success] and forwards trimmed details to the use case',
      setUp: () {
        when(() => signUp(any())).thenAnswer((_) async => user);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignupSubmitted(
          fullName: '  Jane Doe  ',
          employeeId: '  EMP123  ',
          phone: '  1234567890  ',
          emailUsername: '  jdoe  ',
          password: 'secret1',
          confirmPassword: 'secret1',
          showLicenseSection: false,
        ),
      ),
      expect: () => [
        const SignupState(status: SignupStatus.submitting),
        const SignupState(status: SignupStatus.success, user: user),
      ],
      verify: (_) {
        final captured = verify(() => signUp(captureAny())).captured;
        final details = captured.single as SignupDetails;
        expect(details.fullName, 'Jane Doe');
        expect(details.employeeId, 'EMP123');
        expect(details.phone, '1234567890');
        expect(details.emailUsername, 'jdoe');
        expect(details.password, 'secret1');
        expect(details.licenseVerified, isNull);
        expect(details.licenseNumber, isNull);
      },
    );

    blocTest<SignupBloc, SignupState>(
      'forwards onboardingSelection to the use case',
      setUp: () {
        when(() => signUp(any())).thenAnswer((_) async => user);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignupSubmitted(
          fullName: 'Jane Doe',
          employeeId: 'EMP123',
          phone: '1234567890',
          emailUsername: 'jdoe',
          password: 'secret1',
          confirmPassword: 'secret1',
          showLicenseSection: false,
          onboardingSelection: OnboardingSelection(
            travelPreference: TravelPreference.ride,
            vehicleType: VehiclePreference.car,
          ),
        ),
      ),
      expect: () => [
        const SignupState(status: SignupStatus.submitting),
        const SignupState(status: SignupStatus.success, user: user),
      ],
      verify: (_) {
        final captured = verify(() => signUp(captureAny())).captured;
        final details = captured.single as SignupDetails;
        expect(
          details.onboardingSelection,
          const OnboardingSelection(
            travelPreference: TravelPreference.ride,
            vehicleType: VehiclePreference.car,
          ),
        );
      },
    );

    blocTest<SignupBloc, SignupState>(
      'sets licenseVerified true when the license section is shown and a side is valid',
      setUp: () {
        when(() => signUp(any())).thenAnswer((_) async => user);
      },
      build: buildBloc,
      seed: () => SignupState(
        frontLicenseImage: File('front-2.jpg'),
        frontLicenseValid: true,
        licenseNumber: 'DL12345',
      ),
      act: (bloc) => bloc.add(
        const SignupSubmitted(
          fullName: 'Jane Doe',
          employeeId: 'EMP123',
          phone: '1234567890',
          emailUsername: 'jdoe',
          password: 'secret1',
          confirmPassword: 'secret1',
          showLicenseSection: true,
        ),
      ),
      expect: () => [
        isA<SignupState>()
            .having((s) => s.status, 'status', SignupStatus.submitting)
            .having((s) => s.frontLicenseValid, 'frontLicenseValid', true)
            .having((s) => s.licenseNumber, 'licenseNumber', 'DL12345'),
        isA<SignupState>()
            .having((s) => s.status, 'status', SignupStatus.success)
            .having((s) => s.user, 'user', user)
            .having((s) => s.frontLicenseValid, 'frontLicenseValid', true)
            .having((s) => s.licenseNumber, 'licenseNumber', 'DL12345'),
      ],
      verify: (_) {
        final captured = verify(() => signUp(captureAny())).captured;
        final details = captured.single as SignupDetails;
        expect(details.licenseVerified, isTrue);
        expect(details.licenseNumber, 'DL12345');
      },
    );

    blocTest<SignupBloc, SignupState>(
      'leaves licenseVerified null when showLicenseSection is true but no image was picked',
      setUp: () {
        when(() => signUp(any())).thenAnswer((_) async => user);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignupSubmitted(
          fullName: 'Jane Doe',
          employeeId: 'EMP123',
          phone: '1234567890',
          emailUsername: 'jdoe',
          password: 'secret1',
          confirmPassword: 'secret1',
          showLicenseSection: true,
        ),
      ),
      expect: () => [
        const SignupState(status: SignupStatus.submitting),
        const SignupState(status: SignupStatus.success, user: user),
      ],
      verify: (_) {
        final captured = verify(() => signUp(captureAny())).captured;
        final details = captured.single as SignupDetails;
        expect(details.licenseVerified, isNull);
      },
    );

    blocTest<SignupBloc, SignupState>(
      'emits failure with the AuthException message',
      setUp: () {
        when(
          () => signUp(any()),
        ).thenThrow(const AuthException('An account with this email already exists.'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(validEvent),
      expect: () => [
        const SignupState(status: SignupStatus.submitting),
        const SignupState(
          status: SignupStatus.failure,
          errorMessage: 'An account with this email already exists.',
        ),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'emits failure with a generic message on unexpected errors',
      setUp: () {
        when(() => signUp(any())).thenThrow(Exception('boom'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(validEvent),
      expect: () => [
        const SignupState(status: SignupStatus.submitting),
        const SignupState(
          status: SignupStatus.failure,
          errorMessage: 'Sign up failed. Please try again.',
        ),
      ],
    );
  });

  group('SignupFieldChanged', () {
    final frontFile = File('front-3.jpg');
    blocTest<SignupBloc, SignupState>(
      'resets validation errors and status while preserving license state',
      build: buildBloc,
      seed: () => SignupState(
        status: SignupStatus.failure,
        fullNameError: 'Full name is required',
        errorMessage: 'Sign up failed. Please try again.',
        frontLicenseImage: frontFile,
        isVerifyingFrontLicense: true,
        frontLicenseValid: true,
        licenseNumber: 'DL12345',
      ),
      act: (bloc) => bloc.add(const SignupFieldChanged()),
      expect: () => [
        SignupState(
          frontLicenseImage: frontFile,
          isVerifyingFrontLicense: true,
          frontLicenseValid: true,
          licenseNumber: 'DL12345',
        ),
      ],
    );
  });

  group('SignupLicenseImagePicked', () {
    blocTest<SignupBloc, SignupState>(
      'marks the front side as verifying, then applies the scan result',
      setUp: () {
        when(() => scanLicense(any())).thenAnswer(
          (_) async =>
              const LicenseScanResult(licenseNumber: 'DL999', ocrFailed: false),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        SignupLicenseImagePicked(isFront: true, imageFile: File('front-4.jpg')),
      ),
      expect: () => [
        isA<SignupState>()
            .having((s) => s.isVerifyingFrontLicense, 'isVerifyingFrontLicense', true)
            .having((s) => s.frontLicenseValid, 'frontLicenseValid', isNull),
        isA<SignupState>()
            .having((s) => s.isVerifyingFrontLicense, 'isVerifyingFrontLicense', false)
            .having((s) => s.frontLicenseValid, 'frontLicenseValid', true)
            .having((s) => s.licenseNumber, 'licenseNumber', 'DL999'),
      ],
      verify: (_) {
        verify(() => scanLicense('front-4.jpg')).called(1);
      },
    );

    blocTest<SignupBloc, SignupState>(
      'marks the back side as verifying, then applies the scan result',
      setUp: () {
        when(() => scanLicense(any())).thenAnswer(
          (_) async => const LicenseScanResult(ocrFailed: false),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        SignupLicenseImagePicked(isFront: false, imageFile: File('back-2.jpg')),
      ),
      expect: () => [
        isA<SignupState>()
            .having((s) => s.isVerifyingBackLicense, 'isVerifyingBackLicense', true)
            .having((s) => s.backLicenseValid, 'backLicenseValid', isNull),
        isA<SignupState>()
            .having((s) => s.isVerifyingBackLicense, 'isVerifyingBackLicense', false)
            .having((s) => s.backLicenseValid, 'backLicenseValid', isNull)
            .having((s) => s.licenseNumber, 'licenseNumber', isNull),
      ],
      verify: (_) {
        verify(() => scanLicense('back-2.jpg')).called(1);
      },
    );

    blocTest<SignupBloc, SignupState>(
      'marks frontLicenseValid false when OCR genuinely fails',
      setUp: () {
        when(() => scanLicense(any())).thenAnswer(
          (_) async => const LicenseScanResult(ocrFailed: true),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        SignupLicenseImagePicked(isFront: true, imageFile: File('front-5.jpg')),
      ),
      expect: () => [
        isA<SignupState>()
            .having((s) => s.isVerifyingFrontLicense, 'isVerifyingFrontLicense', true),
        isA<SignupState>()
            .having((s) => s.isVerifyingFrontLicense, 'isVerifyingFrontLicense', false)
            .having((s) => s.frontLicenseValid, 'frontLicenseValid', false),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'preserves the previously scanned license number when the new scan finds none',
      setUp: () {
        when(() => scanLicense(any())).thenAnswer(
          (_) async => const LicenseScanResult(ocrFailed: false),
        );
      },
      build: buildBloc,
      seed: () => SignupState(
        frontLicenseImage: File('front-6.jpg'),
        frontLicenseValid: true,
        licenseNumber: 'DL12345',
      ),
      act: (bloc) => bloc.add(
        SignupLicenseImagePicked(isFront: false, imageFile: File('back-3.jpg')),
      ),
      skip: 1,
      expect: () => [
        isA<SignupState>()
            .having((s) => s.frontLicenseValid, 'frontLicenseValid', true)
            .having((s) => s.isVerifyingBackLicense, 'isVerifyingBackLicense', false)
            .having((s) => s.backLicenseValid, 'backLicenseValid', isNull)
            .having((s) => s.licenseNumber, 'licenseNumber', 'DL12345'),
      ],
    );
  });
}
