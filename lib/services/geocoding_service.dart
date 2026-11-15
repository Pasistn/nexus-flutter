import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeocodingResult {
  const GeocodingResult({
    required this.lat,
    required this.lng,
    required this.displayName,
  });

  final double lat;
  final double lng;
  final String displayName;
}

class GeocodingService {
  GeocodingService._();

  static const _host = 'nominatim.openstreetmap.org';
  static const _timeout = Duration(seconds: 10);

  static Map<String, String> get _headers => {
        'Accept-Language': 'de',
        if (!kIsWeb) 'User-Agent': 'NexusSkillExchange/1.0',
      };

  static Future<GeocodingResult?> geocode(String address) async {
    final query = address.trim();
    if (query.isEmpty || query.length > 200) return null;

    final json = await _get('/search', {
      'q': query,
      'format': 'json',
      'limit': '1',
    });
    if (json is! List || json.isEmpty) return null;

    final hit = json.first as Map<String, dynamic>;
    final lat = double.tryParse(hit['lat'] as String? ?? '');
    final lng = double.tryParse(hit['lon'] as String? ?? '');
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    return GeocodingResult(
      lat: lat,
      lng: lng,
      displayName: hit['display_name'] as String? ?? query,
    );
  }

  static Future<String?> reverseGeocode(double lat, double lng) async {
    final json = await _get('/reverse', {
      'lat': '$lat',
      'lon': '$lng',
      'format': 'json',
    });
    return json is Map<String, dynamic> ? json['display_name'] as String? : null;
  }

  static Future<Object?> _get(String path, Map<String, String> params) async {
    try {
      final res = await http
          .get(Uri.https(_host, path, params), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }
}
