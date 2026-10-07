import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../onboarding/presentation/onboarding_estudiante_screen.dart';
import '../../trip/presentation/student_home_screen.dart';
import '../domain/destino_auth.dart';
import 'auth_scope.dart';
import 'estado/estado_screens.dart';
import 'estado/mensaje_screen.dart';

/// Traduce un [DestinoAuth] en el widget que lo muestra.
///
/// Está separado de `resolverDestino` a propósito: aquella función es lógica
/// pura y se prueba sin levantar Flutter; esta solo enchufa widgets. Si
/// estuvieran juntas, la tabla de enrutamiento no se podría probar con una
/// prueba unitaria.
///
/// El `switch` sobre un enum no admite huecos: al agregar un destino, el
/// analizador obliga a decir qué se ve en él.
Widget destinoPantalla(DestinoAuth destino) {
  return switch (destino) {
    DestinoAuth.enRevision => const EnRevisionScreen(),
    DestinoAuth.rechazada => const RechazadaScreen(),
    DestinoAuth.suspendida => const SuspendidaScreen(),

    // Las que faltan por construir. Cada una es un paso del plan del
    // onboarding; hasta entonces muestran dónde está la persona en vez de
    // dejarla en blanco.
    DestinoAuth.perfilConductor => const EnConstruccionScreen(
      titulo: 'Completa tu perfil de conductor',
      paso: 'Licencia y certificado médico',
    ),
    DestinoAuth.perfilEstudiante => const EnConstruccionScreen(
      titulo: 'Completa tu perfil de estudiante',
      paso: 'Universidad, carrera y carnet',
    ),
    DestinoAuth.onboardingConductor => const EnConstruccionScreen(
      titulo: 'Elige tus zonas de trabajo',
      paso: 'Selección de zonas con vista previa en mapa',
    ),
    // Fija el domicilio en PostGIS y completa el onboarding; el stream del
    // AuthGate lleva entonces a inicioEstudiante.
    DestinoAuth.onboardingEstudiante => const OnboardingEstudianteScreen(),
    DestinoAuth.inicioConductor => const EnConstruccionScreen(
      titulo: 'Inicio del conductor',
      paso: 'Rutas, turnos y cupos — Iteración 2',
    ),
    DestinoAuth.inicioEstudiante => const StudentHomeScreen(),
    DestinoAuth.bandejaAdministrador => const EnConstruccionScreen(
      titulo: 'Bandeja de solicitudes',
      paso: 'Aprobar y rechazar registros',
    ),
  };
}

/// Marcador de posición de una pantalla que todavía no existe.
///
/// Muestra quién entró y a qué estado llegó: mientras se arma el resto, esto
/// es lo que permite comprobar que el enrutamiento del apartado 6 funciona.
class EnConstruccionScreen extends StatelessWidget {
  const EnConstruccionScreen({
    super.key,
    required this.titulo,
    required this.paso,
  });

  final String titulo;

  /// Qué va a vivir aquí cuando se construya.
  final String paso;

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.usuarioDe(context);

    return MensajeScreen(
      titulo: titulo,
      cuerpo: 'Esta pantalla todavía no está construida.',
      detalle:
          'Próximo paso: $paso\n\n'
          '${usuario.nombreParaMostrar}\n'
          'rol: ${usuario.rol.valor} · estado: ${usuario.estado.valor}\n'
          'onboarding: ${usuario.onboardingCompleto ? "completo" : "pendiente"}',
      colorDetalle: AppColors.primarySoft,
      accionSecundaria: CupoSecondaryButton(
        label: 'Cerrar sesión',
        onPressed: AuthScope.de(context).repositorio.salir,
      ),
    );
  }
}
