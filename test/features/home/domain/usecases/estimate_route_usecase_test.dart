import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/features/home/domain/repositories/home_repository.dart';
import 'package:acepool/features/home/domain/usecases/estimate_route_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository repository;
  late EstimateRouteUseCase useCase;

  setUp(() {
    repository = MockHomeRepository();
    useCase = EstimateRouteUseCase(repository);
  });

  group('EstimateRouteUseCase', () {
    test('forwards args to repository.estimateRoute and returns its result', () async {
      const routeDetails = RouteDetails(distanceKm: 12.5, durationMinutes: 20);
      when(() => repository.estimateRoute(
            originLat: 1.0,
            originLng: 2.0,
            destLat: 3.0,
            destLng: 4.0,
          )).thenAnswer((_) async => routeDetails);

      final result = await useCase(
        originLat: 1.0,
        originLng: 2.0,
        destLat: 3.0,
        destLng: 4.0,
      );

      expect(result, routeDetails);
      verify(() => repository.estimateRoute(
            originLat: 1.0,
            originLng: 2.0,
            destLat: 3.0,
            destLng: 4.0,
          )).called(1);
    });

    test('propagates exceptions thrown by the repository', () async {
      when(() => repository.estimateRoute(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
          )).thenThrow(Exception('failed'));

      expect(
        () => useCase(originLat: 1, originLng: 2, destLat: 3, destLng: 4),
        throwsA(isA<Exception>()),
      );
    });
  });
}
