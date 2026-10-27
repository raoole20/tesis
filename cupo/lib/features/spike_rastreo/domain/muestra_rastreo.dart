import 'dart:math';

import 'protocolo_rastreo.dart';

/// Estado de la app al capturar una muestra: los valores de
/// `AppLifecycleState` de Flutter, tal como los guarda
/// `spike_posiciones.estado_app`.
///
/// Es un espejo propio y no el enum de Flutter para que `domain/` siga siendo
/// Dart puro; la pantalla traduce uno al otro.
enum EstadoApp {
  resumed('resumed'),
  inactive('inactive'),
  paused('paused'),
  hidden('hidden'),
  detached('detached');

  const EstadoApp(this.valor);

  final String valor;
}

/// Nivel del permiso de ubicación al empezar la sesión
/// (`spike_posiciones.permiso`).
enum PermisoRastreo {
  /// «Mientras se usa la app». Es el que pediría la app real: con el
  /// servicio en primer plano debería bastar.
  mientrasSeUsa('mientras_se_usa'),

  /// «Permitir todo el tiempo».
  siempre('siempre'),

  /// Simulación: no se usa el GPS ni se pide permiso.
  noAplica('no_aplica');

  const PermisoRastreo(this.valor);

  final String valor;
}

/// Qué se mide: el protocolo de tres fases por reloj, o un recorrido real
/// en carro (`spike_posiciones.modo`).
enum ModoPrueba {
  fases('fases'),
  recorrido('recorrido');

  const ModoPrueba(this.valor);

  final String valor;
}

/// Lo que vale para toda una corrida del protocolo. Se repite en cada fila de
/// `spike_posiciones` para no necesitar una segunda tabla.
class SesionRastreo {
  const SesionRastreo({
    required this.id,
    required this.inicio,
    required this.protocolo,
    required this.wakelock,
    required this.permiso,
    this.modo = ModoPrueba.fases,
    this.simulada = false,
    this.bateriaSinRestriccion,
    this.dispositivo,
  });

  final ModoPrueba modo;

  /// La produjo el simulador, no un GPS. **Nunca cuenta como evidencia.**
  final bool simulada;

  /// UUID v4 generado en el teléfono.
  final String id;

  /// Hora del teléfono en que llegó la primera ubicación. Las fases se
  /// cuentan desde aquí.
  final DateTime inicio;

  /// En un recorrido solo vale su intervalo: no hay fases.
  final ProtocoloRastreo protocolo;

  /// Si el servicio de ubicación retiene el procesador (y el wifi) despierto.
  final bool wakelock;

  final PermisoRastreo permiso;

  /// Si Cupo está fuera de la optimización de batería; `null` si no se supo.
  final bool? bateriaSinRestriccion;

  /// Fabricante, modelo y versión de Android; `null` si no se supo.
  final String? dispositivo;

  /// Un UUID v4 al azar. [azar] se inyecta para poder probarlo.
  static String nuevoId(Random azar) {
    final b = List<int>.generate(16, (_) => azar.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // versión 4
    b[8] = (b[8] & 0x3f) | 0x80; // variante RFC 4122
    final hex = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Las columnas de la sesión en una fila de `spike_posiciones`.
  Map<String, Object?> toMap() => {
    'sesion_id': id,
    'sesion_inicio': inicio.toUtc().toIso8601String(),
    'modo': modo.valor,
    'simulada': simulada,
    'duracion_fase_s': modo == ModoPrueba.fases
        ? protocolo.duracionFase.inSeconds
        : null,
    'intervalo_s': protocolo.intervalo.inSeconds,
    'wakelock': wakelock,
    'permiso': permiso.valor,
    'bateria_sin_restriccion': bateriaSinRestriccion,
    'dispositivo': dispositivo,
  };
}

/// Una ubicación tal como la capturó la app.
///
/// [seq] se asigna al capturar y no cambia en los reintentos: por eso un
/// hueco en `seq` en la base es una muestra perdida en el camino, y un hueco
/// de tiempo sin hueco en `seq` es una muestra que nunca se capturó.
class MuestraRastreo {
  const MuestraRastreo({
    required this.seq,
    required this.lat,
    required this.lng,
    required this.capturadaEn,
    required this.estadoApp,
    this.fase,
    this.precisionM,
    this.fijadaEn,
    this.pantallaEncendida,
    this.bateriaPct,
    this.cargando,
    this.rumboDeg,
    this.rumboCalculado,
    this.velocidadMs,
    this.cierre = false,
  });

  final int seq;
  final double lat;
  final double lng;

  /// Radio de incertidumbre que informa el sistema, en metros.
  final double? precisionM;

  /// Hora del fix según el sistema de ubicación.
  final DateTime? fijadaEn;

  /// Hora del teléfono en que la ubicación llegó a la app.
  final DateTime capturadaEn;

  final EstadoApp estadoApp;

  /// Si la pantalla estaba encendida; `null` si no se pudo leer.
  final bool? pantallaEncendida;

  /// La fase por reloj; `null` en un recorrido (la columna dice
  /// `recorrido`).
  final FaseRastreo? fase;

  /// Batería al capturar, en %, y si estaba cargando; `null` si no se supo.
  final int? bateriaPct;
  final bool? cargando;

  /// Rumbo en grados (0 = norte) y si se calculó con el azimut desde la
  /// muestra anterior en vez de venir del GPS. Ver `rumboDeMuestra()`.
  final double? rumboDeg;
  final bool? rumboCalculado;

  /// Velocidad del GPS, en m/s.
  final double? velocidadMs;

  /// La marca de «Terminar recorrido»: cierra la ventana del reporte, no es
  /// una muestra.
  final bool cierre;

  /// La fila completa de `spike_posiciones`.
  ///
  /// [intentos] y [enviadaEn] son del envío que la lleva, no de la captura:
  /// `enviada_en − capturada_en` es lo que esperó en la cola, medido con un
  /// solo reloj.
  Map<String, Object?> fila(
    SesionRastreo sesion, {
    required int intentos,
    required DateTime enviadaEn,
  }) => {
    ...sesion.toMap(),
    'seq': seq,
    'lat': lat,
    'lng': lng,
    'precision_m': precisionM,
    'fijada_en': fijadaEn?.toUtc().toIso8601String(),
    'capturada_en': capturadaEn.toUtc().toIso8601String(),
    'enviada_en': enviadaEn.toUtc().toIso8601String(),
    'estado_app': estadoApp.valor,
    'pantalla_encendida': pantallaEncendida,
    'fase': fase?.valor ?? 'recorrido',
    'intentos': intentos,
    'bateria_pct': bateriaPct,
    'cargando': cargando,
    'rumbo_deg': rumboDeg,
    'rumbo_calculado': rumboCalculado,
    'velocidad_ms': velocidadMs,
    'cierre': cierre,
  };
}
