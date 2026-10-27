import 'package:flutter/services.dart';

/// Lo que se sabe del teléfono al empezar la prueba.
class InfoDispositivo {
  const InfoDispositivo({
    required this.fabricante,
    required this.modelo,
    required this.android,
    required this.sdk,
    required this.bateriaSinRestriccion,
    this.bateriaPct,
    this.cargando,
  });

  final String fabricante;
  final String modelo;

  /// Versión de Android tal como la muestra Ajustes: «14».
  final String android;

  /// Nivel de API: 34.
  final int sdk;

  /// Si Cupo está fuera de la optimización de batería de Android.
  final bool bateriaSinRestriccion;

  /// Carga de la batería, en %, y si está conectado a un cargador (también
  /// el del carro). `null` si no se pudo leer.
  final int? bateriaPct;
  final bool? cargando;

  /// «samsung SM-A515F · Android 13 (API 33)».
  String get descripcion => '$fabricante $modelo · Android $android (API $sdk)';
}

/// Pantalla y batería al capturar una muestra.
class EstadoAlCapturar {
  const EstadoAlCapturar({
    this.pantallaEncendida,
    this.bateriaPct,
    this.cargando,
  });

  final bool? pantallaEncendida;
  final int? bateriaPct;
  final bool? cargando;
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
      bateriaPct: mapa['bateriaPct'] as int?,
      cargando: mapa['cargando'] as bool?,
    );
  }

  /// Pantalla y batería en el momento de capturar una muestra, en una sola
  /// llamada.
  Future<EstadoAlCapturar?> estadoAlCapturar() async {
    final mapa = await _llamar<Map<Object?, Object?>>('estadoAlCapturar');
    if (mapa == null) return null;
    return EstadoAlCapturar(
      pantallaEncendida: mapa['pantallaEncendida'] as bool?,
      bateriaPct: mapa['bateriaPct'] as int?,
      cargando: mapa['cargando'] as bool?,
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

  /// Publica la notificación en vivo de la prueba (la del servicio en primer
  /// plano: ver `estadoEnVivo` en MainActivity.kt). Con [fijo] en `false`
  /// publica el resumen final, descartable, en otro id. [acento] es
  /// `AppColors.primary`. `false` si no se pudo mostrar.
  Future<bool> mostrarEstado({
    required String titulo,
    required String texto,
    DateTime? inicio,
    int? progreso,
    int maximo = 1000,
    bool fijo = true,
    Color? acento,
  }) async =>
      await _llamar<bool>('estadoEnVivo', {
        'titulo': titulo,
        'texto': texto,
        'inicioMs': inicio?.millisecondsSinceEpoch,
        'progreso': progreso,
        'maximo': maximo,
        'fijo': fijo,
        'color': acento?.toARGB32(),
      }) ??
      false;

  /// Quita la notificación en vivo (la del servicio la quita el servicio al
  /// terminar; esta llamada cubre la simulación, que no tiene servicio).
  Future<void> cerrarEstado() => _llamar<void>('cerrarEstado');

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
