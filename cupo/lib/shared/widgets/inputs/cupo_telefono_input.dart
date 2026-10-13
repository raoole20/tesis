import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/venezuela/telefono_movil.dart';
import 'cupo_prefix_selector.dart';
import 'cupo_text_input.dart';
import 'formato_de_digitos.dart';

/// Campo de teléfono móvil: el código de operadora a la izquierda, los 7
/// dígitos a la derecha.
///
/// El código se elige de una hoja con todas las operadoras (0412, 0414,
/// 0416, 0422, 0424 y 0426). Mientras no se elija, se ve «04XX» en gris y
/// [validarTelefono] lo reclama: no hay un código por omisión, porque uno
/// equivocado que pase desapercibido deja un número al que nadie puede
/// escribir.
///
/// Si se pega el número entero («0414 123 4567» o «+58 414 1234567») en el
/// campo, se reconoce el código, se elige solo y quedan los 7 dígitos.
///
/// El [controller] guarda los 7 dígitos formateados. Para obtener lo que va
/// a la base: `normalizarTelefono(operadora, controller.text)`.
class CupoTelefonoInput extends StatelessWidget {
  const CupoTelefonoInput({
    super.key,
    required this.controller,
    required this.operadora,
    required this.onOperadoraChanged,
    this.textInputAction,
    this.enabled = true,
  });

  final TextEditingController controller;
  final OperadoraMovil? operadora;
  final ValueChanged<OperadoraMovil> onOperadoraChanged;
  final TextInputAction? textInputAction;
  final bool enabled;

  /// Reconoce un número pegado completo y se queda con los 7 dígitos.
  String _preparar(String digitos) {
    final separado = separarTelefono(digitos);
    if (separado == null) return digitos;
    onOperadoraChanged(separado.$1);
    return separado.$2;
  }

  @override
  Widget build(BuildContext context) {
    return CupoTextInput(
      controller: controller,
      enabled: enabled,
      hintText: '123 4567',
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      inputFormatters: [
        FormatoDeDigitos(
          // `preparar` ve el número entero antes del recorte a 7 dígitos.
          maxDigitos: OperadoraMovil.digitosDelNumero,
          formatear: formatearTelefono,
          preparar: _preparar,
        ),
      ],
      prefix: CupoPrefixSelector<OperadoraMovil>(
        tituloHoja: 'Código de operadora',
        placeholder: '04XX',
        valor: operadora,
        enabled: enabled,
        onChanged: onOperadoraChanged,
        opciones: [
          for (final o in OperadoraMovil.values)
            CupoOpcionPrefijo(
              valor: o,
              etiqueta: o.codigo,
              titulo: o.codigo,
              descripcion: o.nombre,
              icono: LucideIcons.smartphone,
            ),
        ],
      ),
    );
  }
}
