/// Cédula y RIF venezolanos: validación, formato y forma normalizada.
///
/// Es Dart puro a propósito: se prueba con pruebas unitarias, sin levantar
/// Flutter (`test/core/venezuela/documento_identidad_test.dart`).
///
/// La letra del documento no se escribe: la elige la persona de una lista
/// cerrada. Así no llegan a la base variantes como «v30111222», «V 30.111.222»
/// o «30111222» para la misma persona, que la restricción `unique` de
/// `usuarios.cedula` no reconocería como iguales.
library;

/// Tipo de documento que acepta Cupo.
///
/// - **V**: persona natural venezolana, con cédula de identidad.
/// - **J**: persona jurídica —una empresa o cooperativa de transporte—, con
///   su RIF.
enum TipoDocumento {
  v(letra: 'V', nombre: 'Venezolano', descripcion: 'Cédula de identidad'),
  j(
    letra: 'J',
    nombre: 'Jurídico',
    descripcion: 'RIF de empresa o cooperativa',
  );

  const TipoDocumento({
    required this.letra,
    required this.nombre,
    required this.descripcion,
  });

  /// La letra con la que se guarda y se muestra: «V», «J».
  final String letra;

  final String nombre;
  final String descripcion;

  /// Cuántos dígitos se pueden escribir como máximo.
  ///
  /// La cédula llega hoy a 8 dígitos. El RIF siempre tiene 9: el número de 8
  /// (con ceros a la izquierda) más el dígito verificador.
  int get maxDigitos => switch (this) {
    TipoDocumento.v => 8,
    TipoDocumento.j => 9,
  };

  /// Ejemplo para el campo vacío.
  String get ejemplo => switch (this) {
    TipoDocumento.v => '30.111.222',
    TipoDocumento.j => '12345678-9',
  };
}

/// Lo que queda del texto al quitarle todo lo que no sea dígito.
String soloDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

/// Por qué [digitos] no sirve como documento de tipo [tipo], o `null` si
/// sirve.
String? validarDocumento(TipoDocumento tipo, String digitos) {
  final limpio = soloDigitos(digitos);

  switch (tipo) {
    case TipoDocumento.v:
      if (limpio.isEmpty) return 'Escribe tu cédula.';
      // Menos de 6 dígitos solo lo tienen cédulas muy antiguas; casi siempre
      // es un dígito que faltó.
      if (limpio.length < 6) return 'La cédula está incompleta.';
      if (limpio.length > 8) return 'La cédula tiene dígitos de más.';
      if (int.parse(limpio) == 0) return 'Esa cédula no es válida.';
      return null;

    case TipoDocumento.j:
      if (limpio.isEmpty) return 'Escribe el RIF de la empresa.';
      if (limpio.length != 9) {
        return 'El RIF lleva 9 dígitos: 8 del número y el verificador.';
      }
      final verificador = digitoVerificadorRif(tipo, limpio.substring(0, 8));
      if (verificador != int.parse(limpio[8])) {
        return 'Ese RIF no es válido. Revisa el último dígito.';
      }
      return null;
  }
}

/// El dígito verificador del RIF, por el módulo 11 del SENIAT.
///
/// La letra cuenta como primer dígito (V = 1, J = 3) y cada posición se
/// multiplica por su peso, de izquierda a derecha: 4, 3, 2, 7, 6, 5, 4, 3, 2.
/// El verificador es 11 menos el resto de dividir la suma entre 11; si da 10
/// u 11, es 0.
///
/// Ejemplo: J-00002961-0 → 3·4 + 2·5 + 9·4 + 6·3 + 1·2 = 78; 78 mod 11 = 1;
/// 11 − 1 = 10 → 0.
int digitoVerificadorRif(TipoDocumento tipo, String ochoDigitos) {
  assert(ochoDigitos.length == 8, 'El número del RIF tiene 8 dígitos.');

  const pesos = [3, 2, 7, 6, 5, 4, 3, 2];
  final valorLetra = switch (tipo) {
    TipoDocumento.v => 1,
    TipoDocumento.j => 3,
  };

  var suma = valorLetra * 4;
  for (var i = 0; i < 8; i++) {
    suma += int.parse(ochoDigitos[i]) * pesos[i];
  }

  final resultado = 11 - (suma % 11);
  return resultado >= 10 ? 0 : resultado;
}

/// Cómo se ve el número mientras se escribe, sin la letra.
///
/// - Cédula: miles con punto, «30.111.222».
/// - RIF: guion antes del verificador cuando ya está, «12345678-9».
String formatearDocumento(TipoDocumento tipo, String digitos) {
  final limpio = soloDigitos(digitos);

  switch (tipo) {
    case TipoDocumento.v:
      final buffer = StringBuffer();
      for (var i = 0; i < limpio.length; i++) {
        // Un punto cada tres dígitos, contando desde la derecha.
        if (i > 0 && (limpio.length - i) % 3 == 0) buffer.write('.');
        buffer.write(limpio[i]);
      }
      return buffer.toString();

    case TipoDocumento.j:
      if (limpio.length <= 8) return limpio;
      return '${limpio.substring(0, 8)}-${limpio.substring(8)}';
  }
}

/// La forma en que el documento se guarda en `usuarios.cedula`.
///
/// Sin puntos y con la letra por delante: «V-30111222», «J-12345678-9». Una
/// sola forma por documento es lo que hace que la restricción `unique`
/// detecte los duplicados.
String normalizarDocumento(TipoDocumento tipo, String digitos) {
  final limpio = soloDigitos(digitos);
  return switch (tipo) {
    TipoDocumento.v => 'V-$limpio',
    TipoDocumento.j => 'J-${formatearDocumento(tipo, limpio)}',
  };
}
