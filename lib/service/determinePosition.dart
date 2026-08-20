import 'package:geolocator/geolocator.dart';

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    throw Exception(' gps no activado');
  }

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      throw Exception('Permiso denegado');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      'Permiso denegado permanentemente',
    );
  }

  return await Geolocator.getCurrentPosition(
  );
}