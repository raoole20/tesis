import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'theme/theme.dart';

Future<void> main() async {
  // Antes de tocar nada asíncrono hay que amarrar el motor de Flutter. Sin
  // esto, Supabase.initialize falla al leer la sesión guardada en el teléfono.
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.estaConfigurado) {
    // Sin credenciales la app no puede hacer nada, pero tampoco debe arrancar
    // en blanco: dice qué falta y cómo se pasa.
    runApp(const SinConfiguracionApp());
    return;
  }

  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  // El AuthGate es la app: construye el MaterialApp y decide qué se ve según
  // haya sesión y en qué estado esté la cuenta.
  runApp(AuthGate(repositorio: AuthRepository()));
}

/// Pantalla de arranque cuando faltan `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
class SinConfiguracionApp extends StatelessWidget {
  const SinConfiguracionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cupo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.surface,
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Falta configurar Supabase', style: AppTypography.title),
                const SizedBox(height: AppSpacing.md),
                Text(Env.ayudaConfiguracion, style: AppTypography.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
