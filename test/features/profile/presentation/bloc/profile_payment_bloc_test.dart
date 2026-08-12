import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/profile_payment_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;

  setUp(() {
    repository = MockProfileRepository();
  });

  group('ProfilePaymentEvent equality', () {
    test('ProfilePaymentMethodChanged supports value equality based on props', () {
      expect(
        const ProfilePaymentMethodChanged('Cash'),
        const ProfilePaymentMethodChanged('Cash'),
      );
      expect(const ProfilePaymentMethodChanged('Cash').props, ['Cash']);
      expect(
        const ProfilePaymentMethodChanged('Cash'),
        isNot(const ProfilePaymentMethodChanged('UPI')),
      );
    });

    test('ProfilePaymentEditToggled supports value equality', () {
      expect(const ProfilePaymentEditToggled(), const ProfilePaymentEditToggled());
    });

    test('ProfilePaymentSaveRequested supports value equality based on props', () {
      expect(
        const ProfilePaymentSaveRequested('user@upi', '9876543210'),
        const ProfilePaymentSaveRequested('user@upi', '9876543210'),
      );
      expect(
        const ProfilePaymentSaveRequested('user@upi', '9876543210').props,
        ['user@upi', '9876543210'],
      );
      expect(
        const ProfilePaymentSaveRequested('user@upi', '9876543210'),
        isNot(const ProfilePaymentSaveRequested('other@upi', '9876543210')),
      );
    });

    test('ProfilePaymentDetailsLoaded supports value equality based on props', () {
      const loaded = ProfilePaymentDetailsLoaded(
        method: 'Cash',
        upiId: 'saved@upi',
        upiPhone: '9998887776',
      );
      expect(
        loaded,
        const ProfilePaymentDetailsLoaded(
          method: 'Cash',
          upiId: 'saved@upi',
          upiPhone: '9998887776',
        ),
      );
      expect(loaded.props, ['Cash', 'saved@upi', '9998887776']);
      expect(
        loaded,
        isNot(const ProfilePaymentDetailsLoaded(
          method: 'UPI',
          upiId: 'saved@upi',
          upiPhone: '9998887776',
        )),
      );
    });
  });

  group('ProfilePaymentBloc', () {
    blocTest<ProfilePaymentBloc, ProfilePaymentState>(
      'emits [selectedMethod updated] when ProfilePaymentMethodChanged is '
      'added',
      build: () {
        // Fail the constructor's initial load so it does not interfere with
        // the state sequence under test.
        when(() => repository.getPaymentDetails())
            .thenThrow(Exception('no details'));
        return ProfilePaymentBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(const ProfilePaymentMethodChanged('Cash')),
      expect: () => const [
        ProfilePaymentState(selectedMethod: 'Cash'),
      ],
    );

    blocTest<ProfilePaymentBloc, ProfilePaymentState>(
      'emits [isEditing toggled] when ProfilePaymentEditToggled is added',
      build: () {
        when(() => repository.getPaymentDetails())
            .thenThrow(Exception('no details'));
        return ProfilePaymentBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(const ProfilePaymentEditToggled()),
      expect: () => const [
        ProfilePaymentState(isEditing: true),
      ],
    );

    blocTest<ProfilePaymentBloc, ProfilePaymentState>(
      'emits [isEditing toggled back] when toggled twice',
      build: () {
        when(() => repository.getPaymentDetails())
            .thenThrow(Exception('no details'));
        return ProfilePaymentBloc(profileRepository: repository);
      },
      act: (bloc) => bloc
        ..add(const ProfilePaymentEditToggled())
        ..add(const ProfilePaymentEditToggled()),
      expect: () => const [
        ProfilePaymentState(isEditing: true),
        ProfilePaymentState(),
      ],
    );

    blocTest<ProfilePaymentBloc, ProfilePaymentState>(
      'emits state with incremented savedTick when '
      'ProfilePaymentSaveRequested succeeds',
      build: () {
        when(() => repository.getPaymentDetails())
            .thenThrow(Exception('no details'));
        when(
          () => repository.savePaymentDetails(
            method: any(named: 'method'),
            upiId: any(named: 'upiId'),
            upiPhone: any(named: 'upiPhone'),
          ),
        ).thenAnswer((_) async {});
        return ProfilePaymentBloc(profileRepository: repository);
      },
      act: (bloc) =>
          bloc.add(const ProfilePaymentSaveRequested('user@upi', '9876543210')),
      expect: () => const [
        ProfilePaymentState(
          savedTick: 1,
          upiId: 'user@upi',
          upiPhone: '9876543210',
        ),
      ],
      verify: (_) {
        verify(
          () => repository.savePaymentDetails(
            method: 'UPI',
            upiId: 'user@upi',
            upiPhone: '9876543210',
          ),
        ).called(1);
      },
    );

    blocTest<ProfilePaymentBloc, ProfilePaymentState>(
      'emits state with loaded details when ProfilePaymentDetailsLoaded is '
      'added',
      build: () {
        when(() => repository.getPaymentDetails())
            .thenThrow(Exception('no details'));
        return ProfilePaymentBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(
        const ProfilePaymentDetailsLoaded(
          method: 'Cash',
          upiId: 'saved@upi',
          upiPhone: '9998887776',
        ),
      ),
      expect: () => const [
        ProfilePaymentState(
          selectedMethod: 'Cash',
          upiId: 'saved@upi',
          upiPhone: '9998887776',
        ),
      ],
    );

    blocTest<ProfilePaymentBloc, ProfilePaymentState>(
      'loads saved payment details on construction when the repository call '
      'succeeds',
      build: () {
        when(() => repository.getPaymentDetails()).thenAnswer(
          (_) async => (
            method: 'UPI',
            upiId: 'preloaded@upi',
            upiPhone: '9123456780',
          ),
        );
        return ProfilePaymentBloc(profileRepository: repository);
      },
      act: (_) {},
      wait: const Duration(milliseconds: 10),
      expect: () => const [
        ProfilePaymentState(
          upiId: 'preloaded@upi',
          upiPhone: '9123456780',
        ),
      ],
    );
  });
}
