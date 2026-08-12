import 'package:acepool/features/profile/domain/entities/profile_summary.dart';
import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;

  const summary = ProfileSummary(
    fullName: 'Jane Doe',
    employeeId: 'EMP001',
    phone: '9876543210',
    travelPreference: 'drive',
    hasVehicles: true,
  );

  const summary2 = ProfileSummary(
    fullName: 'Jane Updated',
    employeeId: 'EMP001',
  );

  setUp(() {
    repository = MockProfileRepository();
  });

  group('ProfileEvent equality', () {
    test('ProfileStarted supports value equality', () {
      expect(const ProfileStarted(), const ProfileStarted());
    });
  });

  group('ProfileState equality', () {
    test('supports value equality based on props', () {
      expect(const ProfileState(), const ProfileState());
      expect(const ProfileState().props, [ProfileStatus.initial, null]);
      expect(
        const ProfileState(status: ProfileStatus.loaded, summary: summary),
        const ProfileState(status: ProfileStatus.loaded, summary: summary),
      );
      expect(
        const ProfileState(status: ProfileStatus.loaded, summary: summary),
        isNot(const ProfileState(status: ProfileStatus.loaded, summary: summary2)),
      );
    });
  });

  group('ProfileBloc', () {
    test('initial state is ProfileState()', () {
      expect(
        ProfileBloc(profileRepository: repository).state,
        const ProfileState(),
      );
    });

    blocTest<ProfileBloc, ProfileState>(
      'emits [loading, loaded] when watchProfile emits a single summary',
      build: () {
        when(() => repository.watchProfile()).thenAnswer(
          (_) => Stream.value(summary),
        );
        return ProfileBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(const ProfileStarted()),
      expect: () => const [
        ProfileState(status: ProfileStatus.loading),
        ProfileState(status: ProfileStatus.loaded, summary: summary),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [loading, loaded, loaded] when watchProfile emits multiple '
      'summaries',
      build: () {
        when(() => repository.watchProfile()).thenAnswer(
          (_) => Stream.fromIterable([summary, summary2]),
        );
        return ProfileBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(const ProfileStarted()),
      expect: () => const [
        ProfileState(status: ProfileStatus.loading),
        ProfileState(status: ProfileStatus.loaded, summary: summary),
        ProfileState(status: ProfileStatus.loaded, summary: summary2),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits only [loading] and surfaces an error when watchProfile errors',
      build: () {
        when(() => repository.watchProfile()).thenAnswer(
          (_) => Stream<ProfileSummary>.error(Exception('stream failed')),
        );
        return ProfileBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(const ProfileStarted()),
      expect: () => const [
        ProfileState(status: ProfileStatus.loading),
      ],
      errors: () => [isA<Exception>()],
    );
  });
}
