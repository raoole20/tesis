import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/reporte_fase.dart';

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
