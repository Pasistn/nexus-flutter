import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  LocationService._();

  static Future<LatLng> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable('Standortdienste sind deaktiviert.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable('Standortzugriff wurde nicht erlaubt.');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 15),
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  static Future<LatLng?> tryCurrent() async {
    try {
      return await current();
    } catch (_) {
      return null;
    }
  }
}
