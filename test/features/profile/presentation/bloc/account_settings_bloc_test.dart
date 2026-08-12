import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/account_settings_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;

  setUp(() {
    repository = MockProfileRepository();
  });

  group('AccountSettingsEvent equality', () {
    test('AccountSettingsSaveRequested supports value equality based on props', () {
      const event = AccountSettingsSaveRequested(
        fullName: 'John Doe',
        phone: '9876543210',
        email: 'john@example.com',
        licenceVerified: true,
        licenceNumber: 'DL12345',
      );
      expect(
        event,
        const AccountSettingsSaveRequested(
          fullName: 'John Doe',
          phone: '9876543210',
          email: 'john@example.com',
          licenceVerified: true,
          licenceNumber: 'DL12345',
        ),
      );
      expect(event.props, ['John Doe', '9876543210', 'john@example.com', true, 'DL12345']);
      expect(
        event,
        isNot(const AccountSettingsSaveRequested(
          fullName: 'Other',
          phone: '9876543210',
          email: 'john@example.com',
        )),
      );
    });
  });

  group('AccountSettingsState equality', () {
    test('supports value equality based on props', () {
      expect(const AccountSettingsState(), const AccountSettingsState());
      expect(const AccountSettingsState().props, [AccountSettingsStatus.initial, null]);
      expect(
        const AccountSettingsState(status: AccountSettingsStatus.failure, message: 'x'),
        isNot(
          const AccountSettingsState(status: AccountSettingsStatus.failure, message: 'y'),
        ),
      );
    });
  });

  group('AccountSettingsBloc', () {
    test('initial state is AccountSettingsState()', () {
      expect(
        AccountSettingsBloc(profileRepository: repository).state,
        const AccountSettingsState(),
      );
    });

    blocTest<AccountSettingsBloc, AccountSettingsState>(
      'emits [failure] when phone number is non-empty and not 10 digits',
      build: () => AccountSettingsBloc(profileRepository: repository),
      act: (bloc) => bloc.add(
        const AccountSettingsSaveRequested(
          fullName: 'John Doe',
          phone: '12345',
          email: 'john@example.com',
        ),
      ),
      expect: () => const [
        AccountSettingsState(
          status: AccountSettingsStatus.failure,
          message: 'Enter a valid 10-digit phone number',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => repository.updateProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            email: any(named: 'email'),
          ),
        );
      },
    );

    blocTest<AccountSettingsBloc, AccountSettingsState>(
      'emits [saving, success] when phone is empty and update succeeds',
      build: () {
        when(
          () => repository.updateProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            email: any(named: 'email'),
            licenceVerified: any(named: 'licenceVerified'),
            licenceNumber: any(named: 'licenceNumber'),
          ),
        ).thenAnswer((_) async {});
        return AccountSettingsBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(
        const AccountSettingsSaveRequested(
          fullName: 'John Doe',
          phone: '',
          email: 'john@example.com',
        ),
      ),
      expect: () => const [
        AccountSettingsState(status: AccountSettingsStatus.saving),
        AccountSettingsState(status: AccountSettingsStatus.success),
      ],
    );

    blocTest<AccountSettingsBloc, AccountSettingsState>(
      'emits [saving, success] when phone is a valid 10-digit number and '
      'update succeeds',
      build: () {
        when(
          () => repository.updateProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            email: any(named: 'email'),
            licenceVerified: any(named: 'licenceVerified'),
            licenceNumber: any(named: 'licenceNumber'),
          ),
        ).thenAnswer((_) async {});
        return AccountSettingsBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(
        const AccountSettingsSaveRequested(
          fullName: 'John Doe',
          phone: '9876543210',
          email: 'john@example.com',
          licenceVerified: true,
          licenceNumber: 'DL12345',
        ),
      ),
      expect: () => const [
        AccountSettingsState(status: AccountSettingsStatus.saving),
        AccountSettingsState(status: AccountSettingsStatus.success),
      ],
      verify: (_) {
        verify(
          () => repository.updateProfile(
            fullName: 'John Doe',
            phone: '9876543210',
            email: 'john@example.com',
            licenceVerified: true,
            licenceNumber: 'DL12345',
          ),
        ).called(1);
      },
    );

    blocTest<AccountSettingsBloc, AccountSettingsState>(
      'emits [saving, failure] when the repository throws',
      build: () {
        when(
          () => repository.updateProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            email: any(named: 'email'),
            licenceVerified: any(named: 'licenceVerified'),
            licenceNumber: any(named: 'licenceNumber'),
          ),
        ).thenThrow(Exception('network error'));
        return AccountSettingsBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(
        const AccountSettingsSaveRequested(
          fullName: 'John Doe',
          phone: '9876543210',
          email: 'john@example.com',
        ),
      ),
      expect: () => [
        const AccountSettingsState(status: AccountSettingsStatus.saving),
        isA<AccountSettingsState>()
            .having((s) => s.status, 'status', AccountSettingsStatus.failure)
            .having(
              (s) => s.message,
              'message',
              contains('Failed to save profile'),
            ),
      ],
    );
  });
}
