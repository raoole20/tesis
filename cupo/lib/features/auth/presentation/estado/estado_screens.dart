import 'package:flutter/material.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../../../theme/theme.dart';
import '../auth_scope.dart';
import 'mensaje_screen.dart';

/// `pendiente` — el perfil se envió y el administrador todavía no lo revisa.
///
/// No hay botón de «actualizar» a propósito: la app está suscrita a su propia
/// fila, así que cuando el administrador apruebe, esta pantalla se cambia sola.
class EnRevisionScreen extends StatelessWidget {
  const EnRevisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.usuarioDe(context);

    return MensajeScreen(
      titulo: 'Tu registro está en revisión',
      cuerpo:
          'Estamos verificando tus datos. Es cosa de horas, no de días. '
          'Te avisamos apenas esté listo.',
      detalle:
          'Cuenta: ${usuario.email}\n'
          'Rol: ${usuario.rol.valor}',
      accionSecundaria: CupoSecondaryButton(
        label: 'Cerrar sesión',
        onPressed: AuthScope.de(context).repositorio.salir,
      ),
    );
  }
}

/// `rechazada` — el administrador devolvió el registro con un motivo.
class RechazadaScreen extends StatefulWidget {
  const RechazadaScreen({super.key});

  @override
  State<RechazadaScreen> createState() => _RechazadaScreenState();
}

class _RechazadaScreenState extends State<RechazadaScreen> {
  bool _enviando = false;

  Future<void> _reenviar() async {
    setState(() => _enviando = true);
    final repo = AuthScope.de(context).repositorio;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.enviarARevision();
      // No hace falta navegar: la fila cambia a 'pendiente', el stream lo
      // reporta y el AuthGate cambia de pantalla solo.
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.usuarioDe(context);

    return MensajeScreen(
      titulo: 'Tu registro necesita correcciones',
      cuerpo: 'Revisa lo que falta, corrígelo y vuelve a enviarlo.',
      detalle: usuario.motivoRechazo ?? 'El administrador no dejó un motivo.',
      colorDetalle: AppColors.dangerSoft,
      accion: CupoPrimaryButton(
        label: 'Volver a enviar',
        onPressed: _enviando ? null : _reenviar,
        isLoading: _enviando,
      ),
      accionSecundaria: CupoSecondaryButton(
        label: 'Cerrar sesión',
        onPressed: AuthScope.de(context).repositorio.salir,
      ),
    );
  }
}

/// `suspendida` — cuenta deshabilitada después de haber sido aprobada.
class SuspendidaScreen extends StatelessWidget {
  const SuspendidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MensajeScreen(
      titulo: 'Tu cuenta está deshabilitada',
      cuerpo:
          'Un administrador suspendió el acceso. Si crees que es un error, '
          'escríbenos y lo revisamos.',
      detalle: 'Escríbenos por WhatsApp al 0414 000 0000.',
      colorDetalle: AppColors.dangerSoft,
      accionSecundaria: CupoSecondaryButton(
        label: 'Cerrar sesión',
        onPressed: AuthScope.de(context).repositorio.salir,
      ),
    );
  }
}
