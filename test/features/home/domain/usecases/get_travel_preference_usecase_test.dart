import 'package:acepool/features/home/domain/repositories/home_repository.dart';
import 'package:acepool/features/home/domain/usecases/get_travel_preference_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository repository;
  late GetTravelPreferenceUseCase useCase;

  setUp(() {
    repository = MockHomeRepository();
    useCase = GetTravelPreferenceUseCase(repository);
  });

  group('GetTravelPreferenceUseCase', () {
    test('returns the repository result', () async {
      when(() => repository.getTravelPreference()).thenAnswer((_) async => 'ride');

      final result = await useCase();

      expect(result, 'ride');
      verify(() => repository.getTravelPreference()).called(1);
    });

    test('returns null when repository returns null', () async {
      when(() => repository.getTravelPreference()).thenAnswer((_) async => null);

      final result = await useCase();

      expect(result, isNull);
    });

    test('propagates exceptions thrown by the repository', () async {
      when(() => repository.getTravelPreference()).thenThrow(Exception('failed'));

      expect(() => useCase(), throwsA(isA<Exception>()));
    });
  });
}
