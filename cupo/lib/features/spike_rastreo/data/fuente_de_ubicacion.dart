import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// geolocator, envuelto para que la pantalla de la prueba se pueda montar en
/// las pruebas de widget con una fuente falsa.
class FuenteDeUbicacion {
  const FuenteDeUbicacion();

  Future<bool> servicioActivo() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> permiso() => Geolocator.checkPermission();

  /// La primera vez pide «Mientras se usa la app». Si ya está dado, en
  /// Android 10+ geolocator pide además el de segundo plano: en Android 11+
  /// eso abre Ajustes en el permiso de ubicación de Cupo, donde está
  /// «Permitir todo el tiempo».
  Future<LocationPermission> pedirPermiso() => Geolocator.requestPermission();

  Future<bool> abrirAjustesApp() => Geolocator.openAppSettings();

  Future<bool> abrirAjustesUbicacion() => Geolocator.openLocationSettings();

  /// Dónde está el teléfono ahora: la salida del recorrido real. Pide el
  /// permiso si hace falta (en el navegador, el aviso de «usar tu
  /// ubicación»; localhost cuenta como contexto seguro). Lanza si no hay
  /// servicio, permiso o señal.
  Future<Position> posicionActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw const PermissionDeniedException('Sin permiso de ubicación');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// El flujo de ubicaciones de la prueba.
  ///
  /// En Android corre como **servicio en primer plano** (con la notificación
  /// fija que eso exige): es lo que permite seguir recibiendo ubicaciones con
  /// la app minimizada sin el permiso «Permitir todo el tiempo».
  /// `distanceFilter: 0` y el intervalo fijo hacen que un teléfono quieto
  /// también produzca una muestra por intervalo.
  ///
  /// Con [wakelock], el servicio retiene el procesador y el wifi despiertos:
  /// sin eso, con la pantalla apagada Android puede dormir el procesador y
  /// entregar las ubicaciones de golpe al despertar.
  Stream<Position> posiciones({
    required Duration intervalo,
    required bool wakelock,
    required String tituloAviso,
    required String textoAviso,
    Color? acento,
  }) {
    final ajustes = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            intervalDuration: intervalo,
            foregroundNotificationConfig: ForegroundNotificationConfig(
              notificationTitle: tituloAviso,
              notificationText: textoAviso,
              notificationChannelName: 'Prueba de rastreo',
              enableWakeLock: wakelock,
              enableWifiLock: wakelock,
              setOngoing: true,
              color: acento,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          );
    return Geolocator.getPositionStream(locationSettings: ajustes);
  }
}
