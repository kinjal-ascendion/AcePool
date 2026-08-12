import 'dart:convert';

import 'package:acepool/core/services/places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return http.Response(jsonEncode(body), statusCode);
}

Map<String, dynamic> _suggestion({
  required String placeId,
  String? mainText,
  String? secondaryText,
  String? description,
}) {
  return {
    'placePrediction': {
      'placeId': placeId,
      if (mainText != null || secondaryText != null)
        'structuredFormat': {
          if (mainText != null)
            'mainText': {'text': mainText},
          if (secondaryText != null)
            'secondaryText': {'text': secondaryText},
        },
      if (description != null) 'text': {'text': description},
    },
  };
}

void main() {
  group('PlacesService.newSessionToken', () {
    test('returns a 16-character lowercase hex string', () {
      final token = PlacesService.newSessionToken();
      expect(token.length, 16);
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(token), isTrue);
    });

    test('returns a different token on each call', () {
      final a = PlacesService.newSessionToken();
      final b = PlacesService.newSessionToken();
      expect(a, isNot(b));
    });
  });

  group('PlacesService.autocomplete', () {
    test('parses suggestions with full structuredFormat data', () async {
      final client = MockClient((request) async {
        return _jsonResponse({
          'suggestions': [
            _suggestion(
              placeId: 'p1',
              mainText: 'MG Road',
              secondaryText: 'Bangalore, India',
              description: 'MG Road, Bangalore, India',
            ),
          ],
        });
      });
      final service = PlacesService(httpClient: client);

      final result = await service.autocomplete('MG', sessionToken: 'tok');

      expect(result, hasLength(1));
      expect(result.first.placeId, 'p1');
      expect(result.first.mainText, 'MG Road');
      expect(result.first.secondaryText, 'Bangalore, India');
      expect(result.first.description, 'MG Road, Bangalore, India');
    });

    test('mainText falls back to description when missing', () async {
      final client = MockClient((request) async {
        return _jsonResponse({
          'suggestions': [
            _suggestion(placeId: 'p1', description: 'Full Description'),
          ],
        });
      });
      final service = PlacesService(httpClient: client);

      final result = await service.autocomplete('x', sessionToken: 'tok');

      expect(result.first.mainText, 'Full Description');
      expect(result.first.secondaryText, '');
    });

    test('description falls back to mainText when missing', () async {
      final client = MockClient((request) async {
        return _jsonResponse({
          'suggestions': [
            _suggestion(placeId: 'p1', mainText: 'Only Main'),
          ],
        });
      });
      final service = PlacesService(httpClient: client);

      final result = await service.autocomplete('x', sessionToken: 'tok');

      expect(result.first.description, 'Only Main');
      expect(result.first.mainText, 'Only Main');
    });

    test('mainText/description both fall back to empty string when everything is missing', () async {
      final client = MockClient((request) async {
        return _jsonResponse({
          'suggestions': [
            {
              'placePrediction': {'placeId': 'p1'},
            },
          ],
        });
      });
      final service = PlacesService(httpClient: client);

      final result = await service.autocomplete('x', sessionToken: 'tok');

      expect(result.first.mainText, '');
      expect(result.first.description, '');
      expect(result.first.secondaryText, '');
    });

    test('skips suggestions without a placePrediction key', () async {
      final client = MockClient((request) async {
        return _jsonResponse({
          'suggestions': [
            {'someOtherKey': {}},
            _suggestion(placeId: 'p2', mainText: 'Valid'),
          ],
        });
      });
      final service = PlacesService(httpClient: client);

      final result = await service.autocomplete('x', sessionToken: 'tok');

      expect(result, hasLength(1));
      expect(result.first.placeId, 'p2');
    });

    test('returns empty list when suggestions key is missing', () async {
      final client = MockClient((request) async => _jsonResponse({}));
      final service = PlacesService(httpClient: client);

      final result = await service.autocomplete('x', sessionToken: 'tok');

      expect(result, isEmpty);
    });

    test('returns empty list on non-200 status code', () async {
      final client = MockClient((request) async => http.Response('', 400));
      final service = PlacesService(httpClient: client);

      final result = await service.autocomplete('x', sessionToken: 'tok');

      expect(result, isEmpty);
    });

    test('returns empty list when the client throws', () async {
      final client = MockClient((request) async => throw Exception('network down'));
      final service = PlacesService(httpClient: client);

      final result = await service.autocomplete('x', sessionToken: 'tok');

      expect(result, isEmpty);
    });

    test('returns empty list on malformed JSON body', () async {
      final client = MockClient((request) async => http.Response('not json', 200));
      final service = PlacesService(httpClient: client);

      final result = await service.autocomplete('x', sessionToken: 'tok');

      expect(result, isEmpty);
    });

    test('includes sessionToken and input in the request body', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse({'suggestions': []});
      });
      final service = PlacesService(httpClient: client);

      await service.autocomplete('MG Road', sessionToken: 'session-123');

      expect(capturedBody!['input'], 'MG Road');
      expect(capturedBody!['sessionToken'], 'session-123');
      expect(capturedBody!.containsKey('locationBias'), isFalse);
    });

    test('includes locationBias with biasLat/biasLng when both are provided', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse({'suggestions': []});
      });
      final service = PlacesService(httpClient: client);

      await service.autocomplete(
        'MG Road',
        sessionToken: 'session-123',
        biasLat: 12.97,
        biasLng: 77.59,
      );

      expect(capturedBody!.containsKey('locationBias'), isTrue);
      final circle = capturedBody!['locationBias']['circle'] as Map<String, dynamic>;
      expect(circle['center']['latitude'], 12.97);
      expect(circle['center']['longitude'], 77.59);
      expect(circle['radius'], 50000.0);
    });

    test('omits locationBias when only biasLat is provided', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse({'suggestions': []});
      });
      final service = PlacesService(httpClient: client);

      await service.autocomplete('MG Road', sessionToken: 'session-123', biasLat: 12.97);

      expect(capturedBody!.containsKey('locationBias'), isFalse);
    });

    test('omits locationBias when only biasLng is provided', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse({'suggestions': []});
      });
      final service = PlacesService(httpClient: client);

      await service.autocomplete('MG Road', sessionToken: 'session-123', biasLng: 77.59);

      expect(capturedBody!.containsKey('locationBias'), isFalse);
    });
  });

  group('PlacesService.getPlaceDetails', () {
    test('returns formatted address and lat/lng on success', () async {
      final client = MockClient((request) async {
        return _jsonResponse({
          'formattedAddress': '123 MG Road, Bangalore',
          'location': {'latitude': 12.9716, 'longitude': 77.5946},
        });
      });
      final service = PlacesService(httpClient: client);

      final result = await service.getPlaceDetails('p1', sessionToken: 'tok');

      expect(result, isNotNull);
      expect(result!.formattedAddress, '123 MG Road, Bangalore');
      expect(result.lat, 12.9716);
      expect(result.lng, 77.5946);
    });

    test('defaults formattedAddress to empty string when missing', () async {
      final client = MockClient((request) async {
        return _jsonResponse({
          'location': {'latitude': 1.0, 'longitude': 2.0},
        });
      });
      final service = PlacesService(httpClient: client);

      final result = await service.getPlaceDetails('p1', sessionToken: 'tok');

      expect(result!.formattedAddress, '');
    });

    test('returns null when location key is missing', () async {
      final client = MockClient((request) async {
        return _jsonResponse({'formattedAddress': 'Somewhere'});
      });
      final service = PlacesService(httpClient: client);

      final result = await service.getPlaceDetails('p1', sessionToken: 'tok');

      expect(result, isNull);
    });

    test('returns null when latitude is missing from location', () async {
      final client = MockClient((request) async {
        return _jsonResponse({
          'location': {'longitude': 2.0},
        });
      });
      final service = PlacesService(httpClient: client);

      final result = await service.getPlaceDetails('p1', sessionToken: 'tok');

      expect(result, isNull);
    });

    test('returns null when longitude is missing from location', () async {
      final client = MockClient((request) async {
        return _jsonResponse({
          'location': {'latitude': 1.0},
        });
      });
      final service = PlacesService(httpClient: client);

      final result = await service.getPlaceDetails('p1', sessionToken: 'tok');

      expect(result, isNull);
    });

    test('returns null on non-200 status code', () async {
      final client = MockClient((request) async => http.Response('', 404));
      final service = PlacesService(httpClient: client);

      final result = await service.getPlaceDetails('p1', sessionToken: 'tok');

      expect(result, isNull);
    });

    test('returns null when the client throws', () async {
      final client = MockClient((request) async => throw Exception('network down'));
      final service = PlacesService(httpClient: client);

      final result = await service.getPlaceDetails('p1', sessionToken: 'tok');

      expect(result, isNull);
    });

    test('returns null on malformed JSON body', () async {
      final client = MockClient((request) async => http.Response('not json', 200));
      final service = PlacesService(httpClient: client);

      final result = await service.getPlaceDetails('p1', sessionToken: 'tok');

      expect(result, isNull);
    });

    test('includes the sessionToken query parameter and placeId in the path', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return _jsonResponse({
          'location': {'latitude': 1.0, 'longitude': 2.0},
        });
      });
      final service = PlacesService(httpClient: client);

      await service.getPlaceDetails('my-place-id', sessionToken: 'session-abc');

      expect(capturedUri!.queryParameters['sessionToken'], 'session-abc');
      expect(capturedUri!.path, contains('my-place-id'));
    });
  });
}
