import 'package:flutter/material.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../../../theme/theme.dart';

/// Pantalla de una sola idea: un título, una explicación y a lo sumo dos
/// acciones.
///
/// Es el molde de las tres pantallas de estado —en revisión, rechazada,
/// suspendida— y de la de falla. Son la parte del login que siempre se olvida
/// y la que deja a la gente mirando una pantalla en blanco.
class MensajeScreen extends StatelessWidget {
  const MensajeScreen({
    super.key,
    required this.titulo,
    required this.cuerpo,
    this.detalle,
    this.colorDetalle = AppColors.warningSoft,
    this.accion,
    this.accionSecundaria,
  });

  final String titulo;
  final String cuerpo;

  /// Bloque destacado: el motivo del rechazo, el mensaje del error.
  final String? detalle;

  /// Fondo del bloque de [detalle]. Ámbar para lo que está en espera, rojo
  /// suave para lo que salió mal (regla 7 de CLAUDE.md).
  final Color colorDetalle;

  final Widget? accion;
  final Widget? accionSecundaria;

  @override
  Widget build(BuildContext context) {
    final detalleTexto = detalle;

    return CupoScreen(
      topGap: AppSpacing.xxxl,
      children: [
        const Center(child: CupoLockup()),
        const SizedBox(height: AppSpacing.xxxl),
        Text(titulo, style: AppTypography.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        Text(cuerpo, style: AppTypography.body, textAlign: TextAlign.center),
        // `?.` no serviría aquí: hace falta el `if` porque el widget entero
        // sobra cuando no hay detalle, no solo su contenido.
        if (detalleTexto != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorDetalle,
              borderRadius: AppRadius.mdAll,
            ),
            child: Text(detalleTexto, style: AppTypography.body),
          ),
        ],
      ],
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accion != null) accion!,
          if (accion != null && accionSecundaria != null)
            const SizedBox(height: AppSpacing.sm),
          if (accionSecundaria != null) accionSecundaria!,
        ],
      ),
    );
  }
}
