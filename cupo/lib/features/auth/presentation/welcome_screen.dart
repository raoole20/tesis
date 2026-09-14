import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import 'auth_routes.dart';

/// L1 — Bienvenida.
///
/// No pide nada: explica qué es Cupo y ofrece los dos caminos de entrada.
/// El enlace a «Iniciar sesión» es secundario a propósito, no un tercer botón.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupoScreen(
      topGap: AppSpacing.xxxl,
      children: [
        const Center(child: CupoLockup()),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'Tu puesto fijo hasta la URBE',
          style: AppTypography.display,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Te conectamos con transportistas que ya hacen tu ruta. '
          'Crear la cuenta toma menos de dos minutos.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ],
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupoGoogleButton(
            label: 'Continuar con Google',
            onPressed: () =>
                Navigator.of(context).pushNamed(AuthRoutes.verifyPhone),
          ),
          const SizedBox(height: AppSpacing.sm),
          CupoPrimaryButton(
            label: 'Crear cuenta con mi teléfono',
            onPressed: () => Navigator.of(context).pushNamed(AuthRoutes.signUp),
          ),
          const SizedBox(height: AppSpacing.xl),
          CupoInlineLinkText(
            before: '¿Ya tienes cuenta? ',
            linkLabel: 'Iniciar sesión',
            onTap: () => Navigator.of(context).pushNamed(AuthRoutes.signIn),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Al continuar aceptas los términos y el aviso de privacidad. '
            'Cupo es un servicio independiente, no afiliado a la universidad.',
            style: AppTypography.legal,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
