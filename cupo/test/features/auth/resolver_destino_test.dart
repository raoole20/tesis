import 'package:cupo/features/auth/domain/destino_auth.dart';
import 'package:cupo/features/auth/domain/estado_cuenta.dart';
import 'package:cupo/features/auth/domain/resolver_destino.dart';
import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:flutter_test/flutter_test.dart';

/// La tabla de enrutamiento del apartado 6 del modelo de datos, fila por fila.
///
/// Es la prueba que cubre el Objetivo 4: `resolverDestino` es una función pura
/// —sin red, sin disco, sin Flutter— así que se puede afirmar su comportamiento
/// completo, no una muestra. Son 3 roles × 5 estados × 2 valores de
/// onboarding = 30 combinaciones, y aquí están las 30.
void main() {
  group('El estado manda sobre el rol', () {
    // Las cuatro primeras filas de la tabla dicen «cualquiera» en la columna
    // del rol. Se prueba con los tres roles y con onboarding en ambos valores
    // para dejarlo dicho: en estos estados nada más influye.
    for (final rol in RolUsuario.values) {
      for (final onboarding in [true, false]) {
        final sufijo = '${rol.valor}, onboarding=$onboarding';

        test('perfil_incompleto → formulario del rol ($sufijo)', () {
          expect(
            resolverDestino(
              rol: rol,
              estado: EstadoCuenta.perfilIncompleto,
              onboardingCompleto: onboarding,
            ),
            rol.esConductor
                ? DestinoAuth.perfilConductor
                : DestinoAuth.perfilEstudiante,
          );
        });

        test('pendiente → en revisión ($sufijo)', () {
          expect(
            resolverDestino(
              rol: rol,
              estado: EstadoCuenta.pendiente,
              onboardingCompleto: onboarding,
            ),
            DestinoAuth.enRevision,
          );
        });

        test('rechazada → pantalla de rechazo ($sufijo)', () {
          expect(
            resolverDestino(
              rol: rol,
              estado: EstadoCuenta.rechazada,
              onboardingCompleto: onboarding,
            ),
            DestinoAuth.rechazada,
          );
        });

        test('suspendida → cuenta deshabilitada ($sufijo)', () {
          expect(
            resolverDestino(
              rol: rol,
              estado: EstadoCuenta.suspendida,
              onboardingCompleto: onboarding,
            ),
            DestinoAuth.suspendida,
          );
        });
      }
    }
  });

  group('Cuenta aprobada: decide el rol y el onboarding', () {
    test('estudiante sin onboarding → poner el pin de casa', () {
      expect(
        resolverDestino(
          rol: RolUsuario.estudiante,
          estado: EstadoCuenta.aprobada,
          onboardingCompleto: false,
        ),
        DestinoAuth.onboardingEstudiante,
      );
    });

    test('estudiante con onboarding → inicio del estudiante', () {
      expect(
        resolverDestino(
          rol: RolUsuario.estudiante,
          estado: EstadoCuenta.aprobada,
          onboardingCompleto: true,
        ),
        DestinoAuth.inicioEstudiante,
      );
    });

    test('conductor sin onboarding → elegir zonas de trabajo', () {
      expect(
        resolverDestino(
          rol: RolUsuario.conductor,
          estado: EstadoCuenta.aprobada,
          onboardingCompleto: false,
        ),
        DestinoAuth.onboardingConductor,
      );
    });

    test('conductor con onboarding → inicio del conductor', () {
      expect(
        resolverDestino(
          rol: RolUsuario.conductor,
          estado: EstadoCuenta.aprobada,
          onboardingCompleto: true,
        ),
        DestinoAuth.inicioConductor,
      );
    });

    test('el administrador no tiene onboarding: va a la bandeja igual', () {
      for (final onboarding in [true, false]) {
        expect(
          resolverDestino(
            rol: RolUsuario.administrador,
            estado: EstadoCuenta.aprobada,
            onboardingCompleto: onboarding,
          ),
          DestinoAuth.bandejaAdministrador,
        );
      }
    });
  });

  group('Ninguna combinación se queda sin destino', () {
    // Si mañana se agrega un estado o un rol y no se enruta, esta prueba lo
    // caza antes que el usuario.
    test('las 30 combinaciones devuelven algo', () {
      for (final rol in RolUsuario.values) {
        for (final estado in EstadoCuenta.values) {
          for (final onboarding in [true, false]) {
            expect(
              () => resolverDestino(
                rol: rol,
                estado: estado,
                onboardingCompleto: onboarding,
              ),
              returnsNormally,
              reason: '$rol / $estado / $onboarding',
            );
          }
        }
      }
    });
  });

  group('Los enums espejan los tipos de PostgreSQL', () {
    test('rol_usuario', () {
      expect(RolUsuario.desde('estudiante'), RolUsuario.estudiante);
      expect(RolUsuario.desde('conductor'), RolUsuario.conductor);
      expect(RolUsuario.desde('administrador'), RolUsuario.administrador);
      expect(() => RolUsuario.desde('chofer'), throwsArgumentError);
    });

    test('estado_cuenta: el guion bajo de PostgreSQL, no el camelCase', () {
      expect(
        EstadoCuenta.desde('perfil_incompleto'),
        EstadoCuenta.perfilIncompleto,
      );
      expect(EstadoCuenta.perfilIncompleto.valor, 'perfil_incompleto');
      expect(() => EstadoCuenta.desde('perfilIncompleto'), throwsArgumentError);
    });
  });
}
