import 'dart:convert';

import 'package:acepool/core/services/directions_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return http.Response(jsonEncode(body), statusCode);
}

Map<String, dynamic> _routeBody({
  required List<Map<String, dynamic>> legs,
  String status = 'OK',
}) {
  return {
    'status': status,
    'routes': [
      {'legs': legs},
    ],
  };
}

Map<String, dynamic> _leg({int? distanceMeters, int? durationSeconds}) {
  return {
    if (distanceMeters != null) 'distance': {'value': distanceMeters},
    if (durationSeconds != null) 'duration': {'value': durationSeconds},
  };
}

void main() {
  group('DirectionsService.fetchRouteDistanceKm', () {
    test('returns total distance in km on a successful OK response', () async {
      final client = MockClient((request) async {
        return _jsonResponse(
          _routeBody(legs: [_leg(distanceMeters: 5000)]),
        );
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, 5.0);
    });

    test('sums distances across multiple legs (waypoints)', () async {
      final client = MockClient((request) async {
        return _jsonResponse(
          _routeBody(legs: [
            _leg(distanceMeters: 2000),
            _leg(distanceMeters: 3000),
          ]),
        );
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
        waypoints: const [
          [10.0, 20.0],
        ],
      );

      expect(result, 5.0);
    });

    test('constructs the waypoints query param from the given list', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return _jsonResponse(_routeBody(legs: [_leg(distanceMeters: 1000)]));
      });
      final service = DirectionsService(httpClient: client);

      await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
        waypoints: const [
          [10.0, 20.0],
          [30.0, 40.0],
        ],
      );

      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['waypoints'], '10.0,20.0|30.0,40.0');
    });

    test('omits waypoints query param when the list is empty', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return _jsonResponse(_routeBody(legs: [_leg(distanceMeters: 1000)]));
      });
      final service = DirectionsService(httpClient: client);

      await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(capturedUri!.queryParameters.containsKey('waypoints'), isFalse);
    });

    test('returns null on non-200 status code', () async {
      final client = MockClient((request) async => http.Response('', 500));
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('returns null when API status is not OK', () async {
      final client = MockClient((request) async {
        return _jsonResponse(_routeBody(legs: [_leg(distanceMeters: 1000)], status: 'ZERO_RESULTS'));
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('returns null when routes list is empty', () async {
      final client = MockClient((request) async {
        return _jsonResponse({'status': 'OK', 'routes': <dynamic>[]});
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('returns null when routes key is missing', () async {
      final client = MockClient((request) async {
        return _jsonResponse({'status': 'OK'});
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('returns null when legs list is empty', () async {
      final client = MockClient((request) async {
        return _jsonResponse(_routeBody(legs: []));
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('treats a missing leg distance value as 0', () async {
      final client = MockClient((request) async {
        return _jsonResponse(_routeBody(legs: [_leg()]));
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, 0.0);
    });

    test('returns null when the client throws (e.g. malformed JSON)', () async {
      final client = MockClient((request) async => http.Response('not json', 200));
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('returns null when the client throws an exception directly', () async {
      final client = MockClient((request) async => throw Exception('network down'));
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDistanceKm(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });
  });

  group('DirectionsService.fetchRouteDetails', () {
    test('returns distance and duration on a successful OK response', () async {
      final client = MockClient((request) async {
        return _jsonResponse(
          _routeBody(legs: [_leg(distanceMeters: 10000, durationSeconds: 1200)]),
        );
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDetails(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNotNull);
      expect(result!.distanceKm, 10.0);
      expect(result.durationMinutes, 20);
    });

    test('sums distance and duration across multiple legs', () async {
      final client = MockClient((request) async {
        return _jsonResponse(
          _routeBody(legs: [
            _leg(distanceMeters: 5000, durationSeconds: 600),
            _leg(distanceMeters: 5000, durationSeconds: 600),
          ]),
        );
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDetails(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result!.distanceKm, 10.0);
      expect(result.durationMinutes, 20);
    });

    test('rounds duration minutes to the nearest minute', () async {
      final client = MockClient((request) async {
        return _jsonResponse(
          _routeBody(legs: [_leg(distanceMeters: 1000, durationSeconds: 100)]),
        );
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDetails(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      // 100 seconds = 1.666... minutes -> rounds to 2.
      expect(result!.durationMinutes, 2);
    });

    test('returns null on non-200 status code', () async {
      final client = MockClient((request) async => http.Response('', 404));
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDetails(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('returns null when API status is not OK', () async {
      final client = MockClient((request) async {
        return _jsonResponse(_routeBody(legs: [_leg(distanceMeters: 1000)], status: 'REQUEST_DENIED'));
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDetails(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('returns null when routes list is empty', () async {
      final client = MockClient((request) async {
        return _jsonResponse({'status': 'OK', 'routes': <dynamic>[]});
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDetails(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('returns null when legs list is empty', () async {
      final client = MockClient((request) async {
        return _jsonResponse(_routeBody(legs: []));
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDetails(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });

    test('treats missing distance/duration values in a leg as 0', () async {
      final client = MockClient((request) async {
        return _jsonResponse(_routeBody(legs: [_leg()]));
      });
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDetails(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result!.distanceKm, 0.0);
      expect(result.durationMinutes, 0);
    });

    test('returns null when the client throws', () async {
      final client = MockClient((request) async => throw Exception('network down'));
      final service = DirectionsService(httpClient: client);

      final result = await service.fetchRouteDetails(
        originLat: 1,
        originLng: 2,
        destLat: 3,
        destLng: 4,
      );

      expect(result, isNull);
    });
  });
}
