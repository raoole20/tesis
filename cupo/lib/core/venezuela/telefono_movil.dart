/// Teléfonos móviles venezolanos: operadora, validación y forma normalizada.
///
/// Dart puro, como `documento_identidad.dart`: se prueba sin Flutter
/// (`test/core/venezuela/telefono_movil_test.dart`).
library;

import 'documento_identidad.dart' show soloDigitos;

/// Código de operadora de un móvil venezolano.
///
/// El código no se escribe: se elige. Es lo que más se equivoca al teclear un
/// número, y un número mal escrito es un estudiante al que el conductor no
/// puede escribirle por WhatsApp.
enum OperadoraMovil {
  o412(codigo: '0412', nombre: 'Digitel'),
  o414(codigo: '0414', nombre: 'Movistar'),
  o416(codigo: '0416', nombre: 'Movilnet'),
  o422(codigo: '0422', nombre: 'Digitel'),
  o424(codigo: '0424', nombre: 'Movistar'),
  o426(codigo: '0426', nombre: 'Movilnet');

  const OperadoraMovil({required this.codigo, required this.nombre});

  /// Como se marca dentro de Venezuela: «0414».
  final String codigo;

  /// La empresa: «Movistar».
  final String nombre;

  /// Los dígitos del número sin el código de operadora.
  static const int digitosDelNumero = 7;
}

/// Por qué el teléfono no sirve, o `null` si sirve.
String? validarTelefono(OperadoraMovil? operadora, String digitos) {
  final limpio = soloDigitos(digitos);

  if (operadora == null) return 'Elige el código de tu operadora.';
  if (limpio.isEmpty) return 'Escribe tu teléfono.';
  if (limpio.length != OperadoraMovil.digitosDelNumero) {
    return 'Después del ${operadora.codigo} van 7 dígitos.';
  }
  return null;
}

/// Cómo se ve el número mientras se escribe, sin el código: «123 4567».
String formatearTelefono(String digitos) {
  final limpio = soloDigitos(digitos);
  if (limpio.length <= 3) return limpio;
  return '${limpio.substring(0, 3)} ${limpio.substring(3)}';
}

/// Separa un número completo en operadora y los 7 dígitos restantes.
///
/// Sirve para cuando se pega o se autocompleta el número entero en el campo
/// de los 7 dígitos. Acepta «04141234567» (11 dígitos) y «584141234567»
/// (12, con el código de país); con cualquier otra cosa devuelve `null`.
(OperadoraMovil, String)? separarTelefono(String texto) {
  var limpio = soloDigitos(texto);
  if (limpio.length == 12 && limpio.startsWith('58')) {
    limpio = '0${limpio.substring(2)}';
  }
  if (limpio.length != 11) return null;

  for (final operadora in OperadoraMovil.values) {
    if (limpio.startsWith(operadora.codigo)) {
      return (operadora, limpio.substring(4));
    }
  }
  return null;
}

/// La forma en que se guarda en `usuarios.telefono`: E.164, «+584141234567».
///
/// Es la que entiende WhatsApp (`wa.me/584141234567`), y al ser una sola
/// forma por número, la restricción `unique` detecta los duplicados.
String normalizarTelefono(OperadoraMovil operadora, String digitos) {
  return '+58${operadora.codigo.substring(1)}${soloDigitos(digitos)}';
}
