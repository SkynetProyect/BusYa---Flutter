import 'package:latlong2/latlong.dart' as latlong;

/// Utilidad pura (sin estado) para decodificar polylines codificadas
/// con el algoritmo de Google (precisión 1e5).
class PolylineDecoder {
  const PolylineDecoder._();

  /// Convierte una cadena codificada en una lista de coordenadas.
  static List<latlong.LatLng> decode(String encoded) {
    final points = <latlong.LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      lat += _readDelta(encoded, index, (i) => index = i);
      lng += _readDelta(encoded, index, (i) => index = i);
      points.add(latlong.LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  /// Lee un valor delta (lat o lng) desde [start] y
  /// reporta el nuevo índice mediante [onIndex].
  static int _readDelta(String encoded, int start, void Function(int) onIndex) {
    int index = start, shift = 0, result = 0, b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    onIndex(index);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }
}
