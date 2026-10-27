/// Un GET de texto que funciona en Android y en el navegador.
///
/// `dart:io` no existe en web y `package:http` no es dependencia directa del
/// proyecto, así que se elige la implementación al compilar: `HttpClient` en
/// el teléfono y `fetch` del navegador en web (localhost).
library;

export 'obtener_texto_io.dart'
    if (dart.library.js_interop) 'obtener_texto_web.dart';
export 'sin_red.dart';
