import 'package:geolocator/geolocator.dart';

/// Resultado tipado de una solicitud de ubicación.
///
/// Se usa `sealed class` para que el llamador maneje todos los casos
/// con un `switch` exhaustivo y no pueda olvidarse de ninguno.
sealed class LocationResult {
  const LocationResult();
}

/// La solicitud fue exitosa. [position] contiene lat/lng y precisión.
final class LocationSuccess extends LocationResult {
  final Position position;
  LocationSuccess(this.position);
}

/// El servicio de ubicación del dispositivo está desactivado (GPS apagado).
final class LocationServiceDisabled extends LocationResult {
  const LocationServiceDisabled();
}

/// El usuario denegó el permiso, pero puede volver a pedirse.
final class LocationPermissionDenied extends LocationResult {
  const LocationPermissionDenied();
}

/// El usuario denegó el permiso permanentemente (marca "No volver a preguntar").
/// Solo se puede resolver abriendo la pantalla de ajustes de la app.
final class LocationPermissionDeniedForever extends LocationResult {
  const LocationPermissionDeniedForever();
}

/// Servicio de ubicación del dispositivo.
///
/// Encapsula `geolocator` para que el widget solo dependa de
/// [LocationResult] y no del API de la librería externa.
/// Esto hace la lógica fácilmente testeable con un stub.
class LocationService {
  const LocationService();

  /// Solicita permisos si hacen falta y devuelve la posición actual.
  ///
  /// Flujo:
  /// 1. Verificar que el servicio GPS está activo.
  /// 2. Verificar / solicitar el permiso de ubicación en primer plano.
  /// 3. Obtener la posición con alta precisión.
  ///
  /// Este spike solo pide [LocationPermission.whileInUse] (primer plano).
  /// El Spike 1 real añadirá [LocationPermission.always] para segundo plano.
  Future<LocationResult> getCurrentPosition() async {
    // — 1. GPS encendido —
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationServiceDisabled();
    }

    // — 2. Permiso —
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationPermissionDenied();
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationPermissionDeniedForever();
    }

    // — 3. Posición —
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    return LocationSuccess(position);
  }

  /// Abre la pantalla de ajustes del sistema para activar el GPS.
  Future<void> abrirAjustesUbicacion() => Geolocator.openLocationSettings();

  /// Abre la pantalla de permisos de la app en Ajustes del sistema.
  Future<void> abrirAjustesApp() => Geolocator.openAppSettings();
}
