import 'package:cupo/features/auth/data/auth_repository.dart';
import 'package:cupo/features/auth/domain/estado_cuenta.dart';
import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:cupo/features/auth/domain/usuario.dart';
import 'package:cupo/features/auth/presentation/auth_scope.dart';
import 'package:cupo/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta una pantalla suelta con todo lo que da por sentado: el tema, un
/// `Navigator` y un [AuthScope].
///
/// No se monta la app entera porque `main()` llama a `Supabase.initialize`, y
/// una prueba de widget no debe necesitar red ni credenciales. El repositorio
/// que se inyecta aquí no se toca mientras la prueba no dispare un envío.
Future<void> montarPantalla(
  WidgetTester tester,
  Widget pantalla, {
  Usuario? usuario,
  AuthRepository? repositorio,
}) async {
  // El lienzo del diseño, para que las medidas de CupoScreen se ejerciten tal
  // como se verán en el teléfono.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = repositorio ?? AuthRepository();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: pantalla,
      // El AuthScope va en `builder` y no envolviendo `home`: así alcanza
      // también a las pantallas que se empujen encima durante la prueba.
      builder: (context, child) =>
          AuthScope(repositorio: repo, usuario: usuario, child: child!),
    ),
  );
}

/// Una fila de `usuarios` de mentira, para las pantallas que exigen sesión.
Usuario usuarioDePrueba({
  RolUsuario rol = RolUsuario.estudiante,
  EstadoCuenta estado = EstadoCuenta.aprobada,
  bool onboardingCompleto = false,
  String? motivoRechazo,
}) {
  return Usuario(
    id: '00000000-0000-0000-0000-000000000001',
    email: 'genesis@ejemplo.com',
    rol: rol,
    estado: estado,
    nombres: 'Génesis',
    apellidos: 'Materán',
    onboardingCompleto: onboardingCompleto,
    telefono: '0414 000 0000',
    cedula: 'V-30.111.222',
    motivoRechazo: motivoRechazo,
  );
}
