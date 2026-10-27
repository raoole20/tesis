import 'geo.dart';

/// La ruta del recorrido real: de dónde sale y adónde llega.
///
/// La llegada es fija (la URBE). La salida es **la ubicación actual** de quien
/// prueba; la de esta constante es solo el respaldo para la simulación y para
/// cuando no hay GPS. No es de ningún usuario: lo que se manejó de verdad
/// queda en `spike_recorridos`, con el `conductor_id` de la sesión.
class RutaDePrueba {
  const RutaDePrueba({
    required this.nombre,
    required this.etiquetaLlegada,
    required this.inicio,
    required this.llegada,
  });

  final String nombre;

  /// Cómo se llama la llegada en la pantalla: «URBE».
  final String etiquetaLlegada;
  final PuntoGeo inicio;
  final PuntoGeo llegada;

  /// **La ruta por omisión del modo «Recorrido real».** Cambiar el destino es
  /// editar [llegada]; cambiar la salida de respaldo, [inicio] (ver
  /// docs/producto/spike-rastreo.md §13.2).
  ///
  /// La llegada es la URBE (Av. 15P, La Trinidad), confirmada con
  /// OpenStreetMap. Desde la salida de respaldo (Av. 61), según OSRM
  /// (27-oct-2026): 4,92 km y ≈7 min sin tráfico, por Avenida 61 → Calle 44 A
  /// → Avenida 2 → Calle N → Avenida 5 → Av. Circunvalación 2 → Avenida 16 →
  /// URBE.
  static const porOmision = RutaDePrueba(
    nombre: 'Prueba: tu ubicación → URBE',
    etiquetaLlegada: 'URBE',
    // Respaldo: Av. 61, solo si no hay ubicación actual.
    inicio: PuntoGeo(10.702096062336127, -71.60399954232982),
    llegada: PuntoGeo(10.694066051261032, -71.6339425901966),
  );

  RutaDePrueba copyWith({PuntoGeo? inicio, PuntoGeo? llegada}) => RutaDePrueba(
    nombre: nombre,
    etiquetaLlegada: etiquetaLlegada,
    inicio: inicio ?? this.inicio,
    llegada: llegada ?? this.llegada,
  );

  /// Las paradas que se le piden al ruteador: ida, o ida y vuelta.
  List<PuntoGeo> paradas({bool idaYVuelta = false}) =>
      idaYVuelta ? [inicio, llegada, inicio] : [inicio, llegada];
}

/// La línea por las calles que devolvió el ruteador.
class RutaPlanificada {
  const RutaPlanificada({
    required this.puntos,
    required this.distanciaM,
    required this.duracionS,
    required this.calles,
    this.fuente = 'osrm',
  });

  /// El servidor público de OSRM. **Solo para pruebas**: su política de uso
  /// no admite tráfico de producción. El proveedor de rutas de Cupo sigue
  /// abierto (DA-19).
  static const String servidorOsrm = 'https://router.project-osrm.org';

  /// La consulta de ruta en auto, con la geometría completa en GeoJSON y los
  /// pasos (para los nombres de las calles).
  static Uri urlOsrm(List<PuntoGeo> paradas) {
    final coordenadas = paradas.map((p) => '${p.lng},${p.lat}').join(';');
    return Uri.parse(
      '$servidorOsrm/route/v1/driving/$coordenadas'
      '?overview=full&geometries=geojson&steps=true',
    );
  }

  /// Lee la respuesta de `/route/v1` de OSRM. Lanza [FormatException] si no
  /// trae una ruta.
  factory RutaPlanificada.desdeOsrm(Map<String, dynamic> respuesta) {
    if (respuesta['code'] != 'Ok') {
      throw FormatException('OSRM respondió ${respuesta['code']}');
    }
    final rutas = respuesta['routes'];
    if (rutas is! List || rutas.isEmpty) {
      throw const FormatException('OSRM no devolvió ninguna ruta');
    }
    final ruta = rutas.first as Map<String, dynamic>;
    final geometria = ruta['geometry'] as Map<String, dynamic>;
    final coordenadas = geometria['coordinates'] as List<dynamic>;
    final puntos = [
      for (final c in coordenadas)
        PuntoGeo(
          ((c as List<dynamic>)[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        ),
    ];
    if (puntos.length < 2) {
      throw const FormatException('La ruta de OSRM tiene menos de 2 puntos');
    }

    final calles = <String>[];
    for (final tramo in (ruta['legs'] as List<dynamic>? ?? const [])) {
      final pasos = (tramo as Map<String, dynamic>)['steps'] as List<dynamic>?;
      for (final paso in pasos ?? const []) {
        final nombre = ((paso as Map<String, dynamic>)['name'] as String? ?? '')
            .trim();
        if (nombre.isNotEmpty && (calles.isEmpty || calles.last != nombre)) {
          calles.add(nombre);
        }
      }
    }

    return RutaPlanificada(
      puntos: puntos,
      distanciaM: (ruta['distance'] as num).toDouble(),
      duracionS: (ruta['duration'] as num).toDouble(),
      calles: calles,
    );
  }

  final List<PuntoGeo> puntos;
  final double distanciaM;

  /// Sin tráfico, según el ruteador.
  final double duracionS;

  /// Las calles en orden, sin repetir seguidas.
  final List<String> calles;

  final String fuente;

  /// `LINESTRING(lng lat, …)` con SRID, para `spike_recorridos`.
  String get ewkt =>
      'SRID=4326;LINESTRING(${puntos.map((p) => '${p.lng} ${p.lat}').join(',')})';
}
