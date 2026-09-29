import 'package:cupo/features/auth/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'soporte/banco_de_pruebas.dart';

void main() {
  setUpAll(() {
    // Sin esto, google_fonts intenta descargar Manrope durante la prueba.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // No se monta `CupoApp` porque `main()` llama a `Supabase.initialize`: eso
  // exige credenciales y red, que es justo lo que una prueba no debe pedir.
  // Se monta la pantalla con la que arranca alguien sin sesión.
  testWidgets('la app arranca y muestra su pantalla inicial', (tester) async {
    await montarPantalla(tester, const WelcomeScreen());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Cupo'), findsOneWidget);
  });
}
