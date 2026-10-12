import 'package:latlong2/latlong.dart';

/// Zona de cobertura provisional para el spike de georreferenciación.
///
/// Datos tomados de `supabase/migrations/20260924000008_seed_zonas_maracaibo.sql`.
/// Son rectángulos aproximados, no los límites oficiales de las parroquias.
/// En producción se cargan desde Supabase con `ST_AsGeoJSON`.
class ZonaCobertura {
  final String nombre;
  final String municipio;

  /// Vértices del polígono en orden [SO, SE, NE, NO].
  /// `flutter_map` cierra el polígono automáticamente: el último punto NO
  /// necesita repetirse.
  final List<LatLng> vertices;

  const ZonaCobertura({
    required this.nombre,
    required this.municipio,
    required this.vertices,
  });

  // --- helpers para detección rápida por bounding-box (spike) ---

  LatLng get _sw => vertices[0]; // SO — lat mín, lng mín
  LatLng get _ne => vertices[2]; // NE — lat máx, lng máx

  /// Devuelve `true` si [punto] cae dentro del rectángulo.
  ///
  /// Solo válido para polígonos rectangulares (como los de esta seed).
  /// El Spike 3 real usará ray-casting para polígonos arbitrarios.
  bool contiene(LatLng punto) {
    return punto.latitude >= _sw.latitude &&
        punto.latitude <= _ne.latitude &&
        punto.longitude >= _sw.longitude &&
        punto.longitude <= _ne.longitude;
  }
}

/// Catálogo provisional de zonas de cobertura de Maracaibo.
///
/// Formato de cada zona: [SO, SE, NE, NO] → LatLng(lat, lng).
/// Nota: en SQL, la función `caja_zona(oeste, sur, este, norte)` genera
/// el WKT en orden (lng, lat); aquí se transpone a (lat, lng) para
/// `latlong2`.
const List<ZonaCobertura> zonasMaracaibo = [
  ZonaCobertura(
    nombre: 'La Limpia',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.670, -71.665), // SO
      LatLng(10.670, -71.615), // SE
      LatLng(10.700, -71.615), // NE
      LatLng(10.700, -71.665), // NO
    ],
  ),
  ZonaCobertura(
    nombre: 'Circunvalación 2',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.700, -71.665),
      LatLng(10.700, -71.610),
      LatLng(10.725, -71.610),
      LatLng(10.725, -71.665),
    ],
  ),
  ZonaCobertura(
    nombre: 'Cuatricentenario',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.725, -71.660),
      LatLng(10.725, -71.600),
      LatLng(10.755, -71.600),
      LatLng(10.755, -71.660),
    ],
  ),
  ZonaCobertura(
    nombre: 'Las Delicias',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.645, -71.645),
      LatLng(10.645, -71.610),
      LatLng(10.670, -71.610),
      LatLng(10.670, -71.645),
    ],
  ),
  ZonaCobertura(
    nombre: '5 de Julio',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.645, -71.625),
      LatLng(10.645, -71.595),
      LatLng(10.670, -71.595),
      LatLng(10.670, -71.625),
    ],
  ),
  ZonaCobertura(
    nombre: 'Tierra Negra',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.665, -71.610),
      LatLng(10.665, -71.580),
      LatLng(10.695, -71.580),
      LatLng(10.695, -71.610),
    ],
  ),
  ZonaCobertura(
    nombre: 'El Milagro',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.650, -71.600),
      LatLng(10.650, -71.570),
      LatLng(10.700, -71.570),
      LatLng(10.700, -71.600),
    ],
  ),
  ZonaCobertura(
    nombre: 'Sabaneta',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.615, -71.650),
      LatLng(10.615, -71.610),
      LatLng(10.645, -71.610),
      LatLng(10.645, -71.650),
    ],
  ),
  ZonaCobertura(
    nombre: 'El Amparo',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.610, -71.690),
      LatLng(10.610, -71.650),
      LatLng(10.645, -71.650),
      LatLng(10.645, -71.690),
    ],
  ),
  ZonaCobertura(
    nombre: 'Pomona',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.590, -71.645),
      LatLng(10.590, -71.605),
      LatLng(10.618, -71.605),
      LatLng(10.618, -71.645),
    ],
  ),
  ZonaCobertura(
    nombre: 'Los Haticos',
    municipio: 'Maracaibo',
    vertices: [
      LatLng(10.555, -71.625),
      LatLng(10.555, -71.585),
      LatLng(10.592, -71.585),
      LatLng(10.592, -71.625),
    ],
  ),
  ZonaCobertura(
    nombre: 'San Francisco',
    municipio: 'San Francisco',
    vertices: [
      LatLng(10.510, -71.680),
      LatLng(10.510, -71.600),
      LatLng(10.560, -71.600),
      LatLng(10.560, -71.680),
    ],
  ),
];
