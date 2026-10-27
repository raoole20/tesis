import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/geo.dart';
import '../domain/reporte_fase.dart';
import '../domain/reporte_ruta.dart';
import '../domain/ruta_planificada.dart';
import '../domain/traza.dart';

/// Error al hablar con Supabase durante la prueba, ya redactado para
/// mostrarse.
class SpikeRastreoFallo implements Exception {
  const SpikeRastreoFallo(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Lectura y escritura de `spike_posiciones` y `spike_reporte()`.
///
/// Igual que los demás repositorios, el cliente se resuelve al usarlo y no al
/// construir, para que las pruebas de widget no necesiten levantar Supabase.
class SpikeRastreoRepository {
  SpikeRastreoRepository({
    SupabaseClient? cliente,
    this.limite = const Duration(seconds: 15),
  }) : _inyectado = cliente;

  final SupabaseClient? _inyectado;

  /// Cuánto se espera una respuesta antes de dar el envío por fallido. Sin
  /// límite, una conexión colgada trancaría la cola entera.
  final Duration limite;

  SupabaseClient get _db => _inyectado ?? Supabase.instance.client;

  /// Inserta un lote de filas ya armadas.
  ///
  /// `ON CONFLICT (sesion_id, seq) DO NOTHING`: si un envío anterior llegó
  /// pero su respuesta se perdió, el reintento no duplica la muestra.
  Future<void> insertar(List<Map<String, Object?>> filas) async {
    if (filas.isEmpty) return;
    try {
      await _db
          .from('spike_posiciones')
          .upsert(filas, onConflict: 'sesion_id,seq', ignoreDuplicates: true)
          .timeout(limite);
    } on PostgrestException catch (e) {
      throw SpikeRastreoFallo(_traducir(e.message));
    } on TimeoutException {
      throw SpikeRastreoFallo(
        'Supabase no respondió en ${limite.inSeconds} s. Se reintenta solo.',
      );
    } on AuthException catch (e) {
      throw SpikeRastreoFallo(_traducir(e.message));
    } catch (e) {
      // Sin red, `http` lanza ClientException o SocketException según la
      // plataforma; no se importan para no sumar dependencias directas.
      throw SpikeRastreoFallo(_traducir('$e'));
    }
  }

  /// El reporte por fase de [sesionId]. Ver la migración
  /// `20261026000001_spike_rastreo.sql`.
  Future<List<ReporteFase>> reporte(String sesionId) async {
    try {
      final filas = await _db
          .rpc<List<dynamic>>('spike_reporte', params: {'p_sesion': sesionId})
          .timeout(limite);
      return [
        for (final fila in filas)
          ReporteFase.fromMap(fila as Map<String, dynamic>),
      ];
    } on PostgrestException catch (e) {
      throw SpikeRastreoFallo(_traducir(e.message));
    } on TimeoutException {
      throw const SpikeRastreoFallo(
        'Supabase no respondió. Revisa la conexión y vuelve a intentar.',
      );
    } catch (e) {
      throw SpikeRastreoFallo(_traducir('$e'));
    }
  }

  /// Guarda el plan del recorrido en `spike_recorridos` (una vez por
  /// sesión; un reintento no duplica).
  Future<void> registrarRecorrido({
    required String sesionId,
    required RutaDePrueba ruta,
    required bool idaYVuelta,
    RutaPlanificada? planificada,
    PuntoGeo? domicilio,
    bool simulada = false,
  }) async {
    try {
      await _db
          .from('spike_recorridos')
          .upsert(
            {
              'sesion_id': sesionId,
              'ruta_planificada': planificada?.ewkt,
              'ruta_fuente': planificada?.fuente,
              'ruta_distancia_m': planificada?.distanciaM,
              'ruta_duracion_s': planificada?.duracionS,
              'ida_y_vuelta': idaYVuelta,
              'inicio_plan': ruta.inicio.ewkt,
              'llegada_plan': ruta.llegada.ewkt,
              'domicilio': domicilio?.ewkt,
              'radio_aviso_m': CriterioRuta.radioAvisoM,
              'simulada': simulada,
            },
            onConflict: 'sesion_id',
            ignoreDuplicates: true,
          )
          .timeout(limite);
    } on PostgrestException catch (e) {
      throw SpikeRastreoFallo(_traducir(e.message));
    } on TimeoutException {
      throw const SpikeRastreoFallo(
        'Supabase no respondió. Se reintenta solo.',
      );
    } catch (e) {
      throw SpikeRastreoFallo(_traducir('$e'));
    }
  }

  /// Guarda una ruta recalculada por un desvío, con la hora del teléfono
  /// (la misma escala que `capturada_en`). Un reintento no duplica.
  Future<void> registrarRutaRecalculada({
    required String sesionId,
    required DateTime calculadaEn,
    required PuntoGeo desde,
    required RutaPlanificada ruta,
    double? desvioM,
    bool simulada = false,
  }) async {
    try {
      await _db
          .from('spike_rutas_recalculadas')
          .upsert(
            {
              'sesion_id': sesionId,
              'calculada_en': calculadaEn.toUtc().toIso8601String(),
              'desde': desde.ewkt,
              'ruta': ruta.ewkt,
              'distancia_m': ruta.distanciaM,
              'duracion_s': ruta.duracionS,
              'desvio_m': desvioM,
              'simulada': simulada,
            },
            onConflict: 'sesion_id,calculada_en',
            ignoreDuplicates: true,
          )
          .timeout(limite);
    } on PostgrestException catch (e) {
      throw SpikeRastreoFallo(_traducir(e.message));
    } on TimeoutException {
      throw const SpikeRastreoFallo('Supabase no respondió.');
    } catch (e) {
      throw SpikeRastreoFallo(_traducir('$e'));
    }
  }

  /// `spike_reporte_ruta(sesion)`: el resultado del recorrido.
  Future<ReporteRuta?> reporteRuta(String sesionId) async {
    try {
      final filas = await _db
          .rpc<List<dynamic>>(
            'spike_reporte_ruta',
            params: {'p_sesion': sesionId},
          )
          .timeout(limite);
      if (filas.isEmpty) return null;
      return ReporteRuta.fromMap(filas.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw SpikeRastreoFallo(_traducir(e.message));
    } on TimeoutException {
      throw const SpikeRastreoFallo(
        'Supabase no respondió. Revisa la conexión y vuelve a intentar.',
      );
    } catch (e) {
      throw SpikeRastreoFallo(_traducir('$e'));
    }
  }

  /// Las filas de la sesión, en orden, para dibujar la traza. Por páginas:
  /// PostgREST corta en 1000 filas, y una hora de recorrido son 720.
  Future<List<PuntoTraza>> traza(String sesionId) async {
    const pagina = 1000;
    final puntos = <PuntoTraza>[];
    try {
      for (var desde = 0; ; desde += pagina) {
        final filas = await _db
            .from('spike_posiciones')
            .select(
              'seq, lat, lng, capturada_en, estado_app, pantalla_encendida, '
              'rumbo_deg, cierre',
            )
            .eq('sesion_id', sesionId)
            .order('capturada_en')
            .order('seq')
            .range(desde, desde + pagina - 1)
            .timeout(limite);
        puntos.addAll(filas.map(PuntoTraza.fromMap));
        if (filas.length < pagina) return puntos;
      }
    } on PostgrestException catch (e) {
      throw SpikeRastreoFallo(_traducir(e.message));
    } on TimeoutException {
      throw const SpikeRastreoFallo('Supabase no respondió.');
    } catch (e) {
      if (e is SpikeRastreoFallo) rethrow;
      throw SpikeRastreoFallo(_traducir('$e'));
    }
  }

  /// `spike_ruta_geojson(sesion)` como texto, listo para pegar en
  /// geojson.io o QGIS.
  Future<String> geojson(String sesionId) async {
    try {
      final datos = await _db
          .rpc<dynamic>('spike_ruta_geojson', params: {'p_sesion': sesionId})
          .timeout(limite);
      return const JsonEncoder.withIndent('  ').convert(datos);
    } on PostgrestException catch (e) {
      throw SpikeRastreoFallo(_traducir(e.message));
    } on TimeoutException {
      throw const SpikeRastreoFallo('Supabase no respondió.');
    } catch (e) {
      throw SpikeRastreoFallo(_traducir('$e'));
    }
  }

  String _traducir(String mensaje) {
    final texto = mensaje.toLowerCase();
    if (texto.contains('host lookup') ||
        texto.contains('socketexception') ||
        texto.contains('clientexception') ||
        texto.contains('connection') ||
        texto.contains('network')) {
      return 'No hay conexión. Las muestras esperan en la cola y se '
          'reintentan solas.';
    }
    if (texto.contains('row-level security')) {
      return 'Supabase rechazó la muestra: la cuenta no es de conductor.';
    }
    if (texto.contains('jwt') || texto.contains('refresh')) {
      return 'La sesión venció y no se pudo renovar. Se reintenta solo.';
    }
    // Es una herramienta de depuración: el texto técnico ayuda a
    // diagnosticar más que esconderlo.
    return 'Supabase rechazó el envío: $mensaje';
  }
}
