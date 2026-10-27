import 'dart:async';
import 'dart:js_interop';

import 'sin_red.dart';

@JS('fetch')
external JSPromise<_Respuesta> _fetch(JSString url);

extension type _Respuesta._(JSObject _) implements JSObject {
  external int get status;
  external JSPromise<JSString> text();
}

/// GET con `fetch` del navegador (web). El agente no se puede fijar desde el
/// navegador: lo pone él.
Future<({int estado, String cuerpo})> obtenerTexto(
  Uri url, {
  required Duration limite,
  String? agente,
}) async {
  try {
    final respuesta = await _fetch(url.toString().toJS).toDart.timeout(limite);
    final cuerpo = await respuesta.text().toDart.timeout(limite);
    return (estado: respuesta.status, cuerpo: cuerpo.toDart);
  } on TimeoutException {
    rethrow;
  } catch (e) {
    // fetch rechaza con un TypeError de JS sin red o sin CORS.
    throw SinRed('$e');
  }
}
