import 'dart:convert';
import 'dart:math';

import 'package:acepool/core/constants/api_keys.dart';
import 'package:http/http.dart' as http;

/// A single Google Places Autocomplete suggestion.
class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });
}

/// Resolved coordinates + formatted address for a place, from Place Details.
class PlaceDetails {
  final String formattedAddress;
  final double lat;
  final double lng;

  const PlaceDetails({
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });
}

/// Address search backed by the Places API (New) — the same data source
/// behind Google Maps' own search box, so results match what a user finds
/// there (unlike OpenStreetMap-based search, which has much sparser
/// building/flat-level address coverage).
class PlacesService {
  static const _autocompleteUrl = 'https://places.googleapis.com/v1/places:autocomplete';
  static const _detailsBaseUrl = 'https://places.googleapis.com/v1/places';

  /// A random per-search-session token, grouping autocomplete keystrokes with
  /// their eventual details lookup as one Google-billed session.
  static String newSessionToken() {
    final rand = Random.secure();
    return List.generate(16, (_) => rand.nextInt(16).toRadixString(16)).join();
  }

  /// Address suggestions for [input]. Returns an empty list on no matches or
  /// any failure (missing/invalid key, no connectivity, API error) — never
  /// throws, so callers can treat it the same as a genuine zero-results reply.
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    required String sessionToken,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_autocompleteUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': ApiKeys.googleDirections,
            },
            body: jsonEncode({
              'input': input,
              'sessionToken': sessionToken,
              'includedRegionCodes': ['in'],
              'languageCode': 'en',
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = body['suggestions'] as List<dynamic>? ?? [];
      return suggestions
          .map((s) => (s as Map<String, dynamic>)['placePrediction'] as Map<String, dynamic>?)
          .whereType<Map<String, dynamic>>()
          .map((p) {
            final structured = p['structuredFormat'] as Map<String, dynamic>?;
            final mainText =
                (structured?['mainText'] as Map<String, dynamic>?)?['text'] as String?;
            final secondaryText =
                (structured?['secondaryText'] as Map<String, dynamic>?)?['text'] as String?;
            final description = (p['text'] as Map<String, dynamic>?)?['text'] as String?;
            return PlacePrediction(
              placeId: p['placeId'] as String,
              mainText: mainText ?? description ?? '',
              secondaryText: secondaryText ?? '',
              description: description ?? mainText ?? '',
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Resolves the formatted address + lat/lng for [placeId]. Returns null on
  /// any failure — callers should surface an error rather than silently
  /// picking a location with no coordinates.
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    required String sessionToken,
  }) async {
    try {
      final uri = Uri.parse('$_detailsBaseUrl/$placeId').replace(queryParameters: {
        'sessionToken': sessionToken,
      });
      final response = await http.get(
        uri,
        headers: {
          'X-Goog-Api-Key': ApiKeys.googleDirections,
          'X-Goog-FieldMask': 'formattedAddress,location',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final location = body['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return PlaceDetails(
        formattedAddress: (body['formattedAddress'] as String?) ?? '',
        lat: lat,
        lng: lng,
      );
    } catch (_) {
      return null;
    }
  }
}
