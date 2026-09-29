import 'destino_auth.dart';
import 'estado_cuenta.dart';
import 'rol_usuario.dart';
import 'usuario.dart';

/// La tabla de enrutamiento del apartado 6, como **una sola función**.
///
/// El modelo insiste en que viva en un solo lugar, y hay una razón práctica
/// además de la ordenada: al ser una función pura —mismas entradas, misma
/// salida, sin tocar red ni disco— se prueba entera con pruebas unitarias.
/// Esa es la evidencia verificable del Objetivo 4, y está en
/// `test/features/auth/resolver_destino_test.dart`.
///
/// El orden de las comprobaciones importa: **el estado manda sobre el rol**.
/// Una cuenta suspendida va a la pantalla de suspendida aunque sea de
/// administrador.
DestinoAuth resolverDestino({
  required RolUsuario rol,
  required EstadoCuenta estado,
  required bool onboardingCompleto,
}) {
  switch (estado) {
    case EstadoCuenta.perfilIncompleto:
      return rol.esConductor
          ? DestinoAuth.perfilConductor
          : DestinoAuth.perfilEstudiante;

    case EstadoCuenta.pendiente:
      return DestinoAuth.enRevision;

    case EstadoCuenta.rechazada:
      return DestinoAuth.rechazada;

    case EstadoCuenta.suspendida:
      return DestinoAuth.suspendida;

    case EstadoCuenta.aprobada:
      switch (rol) {
        // El administrador no tiene onboarding: no pone pin ni elige zonas.
        case RolUsuario.administrador:
          return DestinoAuth.bandejaAdministrador;

        case RolUsuario.estudiante:
          return onboardingCompleto
              ? DestinoAuth.inicioEstudiante
              : DestinoAuth.onboardingEstudiante;

        case RolUsuario.conductor:
          return onboardingCompleto
              ? DestinoAuth.inicioConductor
              : DestinoAuth.onboardingConductor;
      }
  }
}

/// Atajo cuando ya se tiene la fila completa.
DestinoAuth destinoDe(Usuario usuario) => resolverDestino(
  rol: usuario.rol,
  estado: usuario.estado,
  onboardingCompleto: usuario.onboardingCompleto,
);
