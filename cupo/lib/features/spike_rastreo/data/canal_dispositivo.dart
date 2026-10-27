import 'package:flutter/services.dart';

/// Lo que se sabe del teléfono al empezar la prueba.
class InfoDispositivo {
  const InfoDispositivo({
    required this.fabricante,
    required this.modelo,
    required this.android,
    required this.sdk,
    required this.bateriaSinRestriccion,
  });

  final String fabricante;
  final String modelo;

  /// Versión de Android tal como la muestra Ajustes: «14».
  final String android;

  /// Nivel de API: 34.
  final int sdk;

  /// Si Cupo está fuera de la optimización de batería de Android.
  final bool bateriaSinRestriccion;

  /// «samsung SM-A515F · Android 13 (API 33)».
  String get descripcion => '$fabricante $modelo · Android $android (API $sdk)';
}

/// El canal `cupo/spike_rastreo` de `MainActivity.kt`.
///
/// Cubre lo que geolocator no trae y que la prueba necesita, sin sumar
/// dependencias: el permiso de notificaciones de Android 13+, mantener la
/// pantalla encendida en la fase 1, saber si la pantalla está encendida al
/// capturar, el estado de la optimización de batería y los avisos de cambio
/// de fase.
///
/// Fuera de Android (o en las pruebas, donde no hay plataforma) cada llamada
/// devuelve `null` o `false` en vez de lanzar: la prueba sigue y la columna
/// queda vacía.
class CanalDispositivo {
  const CanalDispositivo();

  static const MethodChannel _canal = MethodChannel('cupo/spike_rastreo');

  Future<InfoDispositivo?> info() async {
    final mapa = await _llamar<Map<Object?, Object?>>('info');
    if (mapa == null) return null;
    return InfoDispositivo(
      fabricante: mapa['fabricante'] as String,
      modelo: mapa['modelo'] as String,
      android: mapa['android'] as String,
      sdk: mapa['sdk'] as int,
      bateriaSinRestriccion: mapa['bateriaSinRestriccion'] as bool,
    );
  }

  /// Pide el permiso de notificaciones (Android 13+). `true` si quedó dado;
  /// en versiones anteriores no hace falta pedirlo.
  Future<bool> pedirNotificaciones() async =>
      await _llamar<bool>('pedirNotificaciones') ?? false;

  /// `PowerManager.isInteractive`: si la pantalla está encendida.
  Future<bool?> pantallaEncendida() => _llamar<bool>('pantallaEncendida');

  /// Impide que la pantalla se apague sola mientras Cupo está a la vista.
  Future<void> mantenerPantallaEncendida(bool activo) =>
      _llamar<void>('mantenerPantallaEncendida', activo);

  /// Notificación con sonido y vibración. `false` si no se pudo mostrar (sin
  /// permiso de notificaciones, o fuera de Android).
  Future<bool> avisar({required String titulo, required String texto}) async =>
      await _llamar<bool>('avisar', {'titulo': titulo, 'texto': texto}) ??
      false;

  /// Abre la lista de apps con optimización de batería de Android.
  Future<void> abrirAjustesBateria() => _llamar<void>('abrirAjustesBateria');

  static Future<T?> _llamar<T>(String metodo, [Object? argumentos]) async {
    try {
      return await _canal.invokeMethod<T>(metodo, argumentos);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
