import 'package:acepool/core/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

Position _fakePosition({double lat = 12.9716, double lng = 77.5946}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime(2026, 1, 1),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  group('LocationService.getCurrentLocation', () {
    test('returns null when permission is denied and stays denied after requesting', () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.denied,
        isLocationServiceEnabled: () async => true,
        getCurrentPosition: ({locationSettings}) async => _fakePosition(),
      );

      final result = await service.getCurrentLocation();

      expect(result, isNull);
    });

    test('returns null when permission is denied and becomes deniedForever after requesting', () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.deniedForever,
        isLocationServiceEnabled: () async => true,
        getCurrentPosition: ({locationSettings}) async => _fakePosition(),
      );

      final result = await service.getCurrentLocation();

      expect(result, isNull);
    });

    test('returns null immediately when permission is already deniedForever (no request needed)', () async {
      var requestCalled = false;
      final service = LocationService(
        checkPermission: () async => LocationPermission.deniedForever,
        requestPermission: () async {
          requestCalled = true;
          return LocationPermission.deniedForever;
        },
        isLocationServiceEnabled: () async => true,
        getCurrentPosition: ({locationSettings}) async => _fakePosition(),
      );

      final result = await service.getCurrentLocation();

      expect(result, isNull);
      // Only "denied" (not "deniedForever") triggers a request per the
      // production branch condition.
      expect(requestCalled, isFalse);
    });

    test('re-requests permission when denied, and proceeds once granted', () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.whileInUse,
        isLocationServiceEnabled: () async => true,
        getCurrentPosition: ({locationSettings}) async => _fakePosition(lat: 1, lng: 2),
      );

      final result = await service.getCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 1);
      expect(result.longitude, 2);
    });

    test('returns null when permission is granted but the location service is disabled', () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.always,
        requestPermission: () async => LocationPermission.always,
        isLocationServiceEnabled: () async => false,
        getCurrentPosition: ({locationSettings}) async => _fakePosition(),
      );

      final result = await service.getCurrentLocation();

      expect(result, isNull);
    });

    test('returns the real position when permission is granted and service is enabled', () async {
      final expected = _fakePosition(lat: 40.7128, lng: -74.0060);
      final service = LocationService(
        checkPermission: () async => LocationPermission.whileInUse,
        requestPermission: () async => LocationPermission.whileInUse,
        isLocationServiceEnabled: () async => true,
        getCurrentPosition: ({locationSettings}) async => expected,
      );

      final result = await service.getCurrentLocation();

      expect(result, same(expected));
    });

    test('returns null when checkPermission throws', () async {
      final service = LocationService(
        checkPermission: () async => throw Exception('platform error'),
        requestPermission: () async => LocationPermission.whileInUse,
        isLocationServiceEnabled: () async => true,
        getCurrentPosition: ({locationSettings}) async => _fakePosition(),
      );

      final result = await service.getCurrentLocation();

      expect(result, isNull);
    });

    test('returns null when getCurrentPosition throws (e.g. timeout)', () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.always,
        requestPermission: () async => LocationPermission.always,
        isLocationServiceEnabled: () async => true,
        getCurrentPosition: ({locationSettings}) async {
          throw Exception('timed out');
        },
      );

      final result = await service.getCurrentLocation();

      expect(result, isNull);
    });

    test('returns null when getCurrentPosition never completes within the internal timeout', () async {
      final service = LocationService(
        checkPermission: () async => LocationPermission.always,
        requestPermission: () async => LocationPermission.always,
        isLocationServiceEnabled: () async => true,
        getCurrentPosition: ({locationSettings}) =>
            Future.delayed(const Duration(seconds: 20), () => _fakePosition()),
      );

      final result = await service.getCurrentLocation();

      expect(result, isNull);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });

  group('LocationService.isServiceEnabled', () {
    test('returns true when the injected isLocationServiceEnabled resolves true', () async {
      final service = LocationService(isLocationServiceEnabled: () async => true);

      expect(await service.isServiceEnabled(), isTrue);
    });

    test('returns false when the injected isLocationServiceEnabled resolves false', () async {
      final service = LocationService(isLocationServiceEnabled: () async => false);

      expect(await service.isServiceEnabled(), isFalse);
    });
  });
}
