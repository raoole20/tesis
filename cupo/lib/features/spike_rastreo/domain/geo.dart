import 'dart:math';

/// Un punto en WGS 84, en grados.
///
/// Propio del spike para que `domain/` siga siendo Dart puro (sin `latlong2`);
/// la pantalla lo traduce a `LatLng` para dibujarlo.
class PuntoGeo {
  const PuntoGeo(this.lat, this.lng);

  final double lat;
  final double lng;

  /// `POINT(lng lat)` con SRID, como lo lee una columna `geography`.
  String get ewkt => 'SRID=4326;POINT($lng $lat)';

  @override
  bool operator ==(Object other) =>
      other is PuntoGeo && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'PuntoGeo($lat, $lng)';
}

/// Radio medio de la Tierra, en metros (el que usa PostGIS para la esfera).
const double _radioTierra = 6371008.8;

double _rad(double grados) => grados * pi / 180;

/// Distancia sobre la esfera entre [a] y [b], en metros (haversine). Frente a
/// `ST_Distance` sobre `geography` (elipsoide) difiere menos de 0,5 %.
double distanciaMetros(PuntoGeo a, PuntoGeo b) {
  final dLat = _rad(b.lat - a.lat);
  final dLng = _rad(b.lng - a.lng);
  final h =
      pow(sin(dLat / 2), 2) +
      cos(_rad(a.lat)) * cos(_rad(b.lat)) * pow(sin(dLng / 2), 2);
  return 2 * _radioTierra * asin(sqrt(h.toDouble()));
}

/// Rumbo inicial de [desde] hacia [hacia], en grados: 0 = norte, 90 = este,
/// 180 = sur, 270 = oeste. Siempre en [0, 360).
double azimutGrados(PuntoGeo desde, PuntoGeo hacia) {
  final lat1 = _rad(desde.lat);
  final lat2 = _rad(hacia.lat);
  final dLng = _rad(hacia.lng - desde.lng);
  final y = sin(dLng) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
  return normalizarGrados(atan2(y, x) * 180 / pi);
}

/// Lleva cualquier ángulo a [0, 360).
double normalizarGrados(double grados) {
  final r = grados % 360;
  return r >= 360 ? 0 : r;
}

/// El rumbo que se guarda en una muestra.
///
/// El del GPS vale si viene en [0, 360) y el teléfono se mueve (≥ 1 m/s):
/// quieto, Android suele mandar 0 o −1, que no significan nada. Si no vale,
/// se calcula con el azimut desde la muestra [anterior], siempre que estén a
/// más de 5 m (más cerca, el ruido del GPS manda). Devuelve el rumbo y si fue
/// calculado, o `null` si no hay forma de saberlo.
({double grados, bool calculado})? rumboDeMuestra({
  required double? rumboGps,
  required double? velocidadMs,
  required PuntoGeo actual,
  PuntoGeo? anterior,
}) {
  if (rumboGps != null &&
      rumboGps >= 0 &&
      rumboGps < 360 &&
      (velocidadMs ?? 0) >= 1) {
    return (grados: normalizarGrados(rumboGps), calculado: false);
  }
  if (anterior != null && distanciaMetros(anterior, actual) > 5) {
    return (grados: azimutGrados(anterior, actual), calculado: true);
  }
  return null;
}
