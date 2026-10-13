import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../../core/venezuela/documento_identidad.dart' show soloDigitos;

/// Deja escribir solo dígitos, hasta [maxDigitos], y les da formato al vuelo:
/// «30111222» se ve «30.111.222».
///
/// El cursor se queda después del mismo dígito en el que estaba, aunque el
/// formato agregue o quite separadores alrededor.
class FormatoDeDigitos extends TextInputFormatter {
  const FormatoDeDigitos({
    required this.maxDigitos,
    required this.formatear,
    this.preparar,
  });

  final int maxDigitos;

  /// Da formato a los dígitos ya recortados.
  final String Function(String digitos) formatear;

  /// Transforma los dígitos antes de recortarlos, por ejemplo para reconocer
  /// un número pegado completo con su código de operadora.
  final String Function(String digitos)? preparar;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final crudos = soloDigitos(newValue.text);
    final preparados = preparar?.call(crudos) ?? crudos;
    final digitos = preparados.length > maxDigitos
        ? preparados.substring(0, maxDigitos)
        : preparados;
    final texto = formatear(digitos);

    // Si `preparar` cambió los dígitos, la posición vieja ya no significa
    // nada: el cursor va al final.
    if (preparados != crudos) {
      return TextEditingValue(
        text: texto,
        selection: TextSelection.collapsed(offset: texto.length),
      );
    }

    final finCursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitosAntes = math.min(
      soloDigitos(newValue.text.substring(0, finCursor)).length,
      digitos.length,
    );

    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(
        offset: _posicionTrasDigito(texto, digitosAntes),
      ),
    );
  }

  /// La posición en [texto] justo después de su dígito número [n].
  static int _posicionTrasDigito(String texto, int n) {
    if (n == 0) return 0;
    var vistos = 0;
    for (var i = 0; i < texto.length; i++) {
      if (RegExp(r'\d').hasMatch(texto[i])) vistos++;
      if (vistos == n) return i + 1;
    }
    return texto.length;
  }
}
