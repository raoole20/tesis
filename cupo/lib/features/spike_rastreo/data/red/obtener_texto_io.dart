import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'sin_red.dart';

/// GET con `HttpClient` de `dart:io` (Android, pruebas).
Future<({int estado, String cuerpo})> obtenerTexto(
  Uri url, {
  required Duration limite,
  String? agente,
}) async {
  final cliente = HttpClient()..connectionTimeout = limite;
  try {
    final pedido = await cliente.getUrl(url).timeout(limite);
    if (agente != null) {
      pedido.headers.set(HttpHeaders.userAgentHeader, agente);
    }
    final respuesta = await pedido.close().timeout(limite);
    final cuerpo = await respuesta
        .transform(utf8.decoder)
        .join()
        .timeout(limite);
    return (estado: respuesta.statusCode, cuerpo: cuerpo);
  } on SocketException catch (e) {
    throw SinRed('$e');
  } on HttpException catch (e) {
    throw SinRed('$e');
  } finally {
    cliente.close(force: true);
  }
}
