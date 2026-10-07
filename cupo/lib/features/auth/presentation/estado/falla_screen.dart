import 'package:flutter/material.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../../../theme/theme.dart';
import 'mensaje_screen.dart';

/// Hay sesión pero no se pudo leer la fila de `usuarios`: se cayó la red, el
/// RLS rechazó la consulta, o el perfil no existe.
///
/// Sin esta pantalla ese caso termina en pantalla blanca sin salida.
class FallaScreen extends StatelessWidget {
  const FallaScreen({
    super.key,
    required this.mensaje,
    required this.onReintentar,
    required this.onSalir,
  });

  final String mensaje;
  final Future<void> Function() onReintentar;
  final Future<void> Function() onSalir;

  @override
  Widget build(BuildContext context) {
    return MensajeScreen(
      titulo: 'No pudimos cargar tu cuenta',
      cuerpo: 'La sesión está abierta, pero no llegamos a tus datos.',
      detalle: mensaje,
      colorDetalle: AppColors.dangerSoft,
      accion: CupoPrimaryButton(
        label: 'Reintentar',
        onPressed: () => onReintentar(),
      ),
      accionSecundaria: CupoSecondaryButton(
        label: 'Cerrar sesión',
        onPressed: () => onSalir(),
      ),
    );
  }
}
