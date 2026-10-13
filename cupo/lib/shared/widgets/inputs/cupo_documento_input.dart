import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/venezuela/documento_identidad.dart';
import 'cupo_prefix_selector.dart';
import 'cupo_text_input.dart';
import 'formato_de_digitos.dart';

/// Campo de cédula o RIF: la letra a la izquierda, el número a la derecha.
///
/// La letra no se escribe. Si [tipos] trae una sola —el estudiante solo
/// puede ser «V»—, queda fija; si trae varias —el conductor puede ser «V» o
/// «J»—, se elige de una hoja. El número solo admite dígitos y se formatea
/// según el tipo: «30.111.222» o «12345678-9».
///
/// El [controller] guarda el número formateado, sin la letra. Para obtener lo
/// que va a la base: `normalizarDocumento(tipo, controller.text)`.
class CupoDocumentoInput extends StatelessWidget {
  const CupoDocumentoInput({
    super.key,
    required this.controller,
    required this.tipo,
    required this.onTipoChanged,
    this.tipos = TipoDocumento.values,
    this.textInputAction,
    this.enabled = true,
  });

  final TextEditingController controller;
  final TipoDocumento tipo;
  final ValueChanged<TipoDocumento> onTipoChanged;

  /// Los tipos que se pueden elegir. Con uno solo, el prefijo es fijo.
  final List<TipoDocumento> tipos;

  final TextInputAction? textInputAction;
  final bool enabled;

  static IconData _icono(TipoDocumento tipo) => switch (tipo) {
    TipoDocumento.v => LucideIcons.idCard,
    TipoDocumento.j => LucideIcons.building2,
  };

  void _cambiarTipo(TipoDocumento nuevo) {
    // Los formateadores solo corren cuando se teclea: al cambiar de tipo hay
    // que reformatear a mano lo que ya estaba escrito.
    final digitos = soloDigitos(controller.text);
    final recortados = digitos.length > nuevo.maxDigitos
        ? digitos.substring(0, nuevo.maxDigitos)
        : digitos;
    controller.text = formatearDocumento(nuevo, recortados);
    onTipoChanged(nuevo);
  }

  @override
  Widget build(BuildContext context) {
    return CupoTextInput(
      controller: controller,
      enabled: enabled,
      hintText: tipo.ejemplo,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: [
        FormatoDeDigitos(
          maxDigitos: tipo.maxDigitos,
          formatear: (digitos) => formatearDocumento(tipo, digitos),
        ),
      ],
      prefix: CupoPrefixSelector<TipoDocumento>(
        tituloHoja: 'Tipo de documento',
        valor: tipo,
        enabled: enabled,
        onChanged: _cambiarTipo,
        opciones: [
          for (final t in tipos)
            CupoOpcionPrefijo(
              valor: t,
              etiqueta: t.letra,
              titulo: '${t.letra} · ${t.nombre}',
              descripcion: t.descripcion,
              icono: _icono(t),
            ),
        ],
      ),
    );
  }
}
