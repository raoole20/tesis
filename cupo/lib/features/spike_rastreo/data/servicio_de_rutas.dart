import 'dart:async';
import 'dart:convert';

import '../domain/geo.dart';
import '../domain/ruta_planificada.dart';
import 'red/obtener_texto.dart';

/// No se pudo trazar la ruta, ya redactado para mostrarse.
class RutaFallo implements Exception {
  const RutaFallo(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Pide la ruta por las calles al servidor público de OSRM.
///
/// Funciona en Android y en el navegador (ver `red/obtener_texto.dart`; OSRM
/// responde con `Access-Control-Allow-Origin: *`). **Solo para pruebas**: el
/// servidor público no admite producción y el proveedor de rutas de Cupo
/// sigue abierto (DA-19). Si falla, el recorrido se puede hacer igual, sin
/// ruta planificada.
class ServicioDeRutas {
  const ServicioDeRutas({this.limite = const Duration(seconds: 10)});

  final Duration limite;

  Future<RutaPlanificada> trazar(List<PuntoGeo> paradas) async {
    try {
      final respuesta = await obtenerTexto(
        RutaPlanificada.urlOsrm(paradas),
        limite: limite,
        // La política de OSRM pide identificarse (el navegador lo ignora).
        agente: 'com.cupo.app (spike de rastreo, tesis URBE)',
      );
      if (respuesta.estado != 200) {
        throw RutaFallo('El servidor de rutas respondió ${respuesta.estado}.');
      }
      return RutaPlanificada.desdeOsrm(
        jsonDecode(respuesta.cuerpo) as Map<String, dynamic>,
      );
    } on SinRed {
      throw const RutaFallo('No hay conexión con el servidor de rutas.');
    } on TimeoutException {
      throw const RutaFallo('El servidor de rutas no respondió a tiempo.');
    } on FormatException catch (e) {
      throw RutaFallo(
        'La respuesta del servidor de rutas no sirve: ${e.message}',
      );
    }
  }
}
