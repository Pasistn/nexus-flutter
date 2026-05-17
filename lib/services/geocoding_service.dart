import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final double lat;
  final double lng;
  final String displayName;

  const GeocodingResult(
      {required this.lat, required this.lng, required this.displayName});
}

class GeocodingService {
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';

  static Future<GeocodingResult?> geocode(String address) async {
    final uri = Uri.parse('$_nominatimBase/search').replace(
      queryParameters: {
        'q': address,
        'format': 'json',
        'limit': '1',
      },
    );

    try {
      final res = await http.get(uri, headers: {
        'User-Agent': 'NexusApp/1.0 (nexus@skill-exchange.app)',
      });
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as List;
      if (data.isEmpty) return null;
      final first = data.first as Map<String, dynamic>;
      return GeocodingResult(
        lat: double.parse(first['lat'] as String),
        lng: double.parse(first['lon'] as String),
        displayName: first['display_name'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String?> reverseGeocode(double lat, double lng) async {
    final uri =
        Uri.parse('$_nominatimBase/reverse').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'format': 'json',
    });

    try {
      final res = await http.get(uri, headers: {
        'User-Agent': 'NexusApp/1.0 (nexus@skill-exchange.app)',
      });
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
