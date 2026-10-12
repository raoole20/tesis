import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../domain/rol_usuario.dart';

/// Nombre de los dos pasos del registro, para [CupoStepIndicator].
const List<String> pasosDelRegistro = ['Tipo de cuenta', 'Tus datos'];

/// L2, paso 1 de 2 — Elegir el rol antes de pedir ningún dato.
///
/// Va primero y solo, porque decide el resto: el formulario del paso 2 cambia
/// según el rol, y el rol viaja en el `data` del `signUp` —lo lee el trigger
/// `crear_usuario()` para crear la fila en `estudiantes` o en `conductores`—.
/// Después del registro ya no se puede cambiar desde la app, así que no se
/// marca ninguno de antemano: «Continuar» se habilita cuando la persona elige.
///
/// Como [SignUpForm], vive dentro de la hoja de `WelcomeScreen` y no navega.
class SignUpRoleForm extends StatefulWidget {
  const SignUpRoleForm({
    super.key,
    required this.onVolver,
    required this.onElegir,
    required this.onIniciarSesion,
    this.rolInicial,
  });

  /// Pliega la hoja y vuelve a la bienvenida.
  final VoidCallback onVolver;

  /// Pasa al formulario del rol elegido.
  final ValueChanged<RolUsuario> onElegir;

  /// Cambia al formulario de inicio de sesión sin plegar la hoja.
  final VoidCallback onIniciarSesion;

  /// El rol que ya se había elegido, al volver desde el paso 2.
  final RolUsuario? rolInicial;

  @override
  State<SignUpRoleForm> createState() => _SignUpRoleFormState();
}

class _SignUpRoleFormState extends State<SignUpRoleForm> {
  late RolUsuario? _rol = widget.rolInicial;

  @override
  Widget build(BuildContext context) {
    final rol = _rol;

    return CupoSheetBody(
      title: 'Crear cuenta',
      onBack: widget.onVolver,
      footer: CupoInlineLinkText(
        before: '¿Ya tienes cuenta? ',
        linkLabel: 'Inicia sesión',
        onTap: widget.onIniciarSesion,
      ),
      children: [
        const SizedBox(height: AppSpacing.xl),
        const CupoStepIndicator(pasos: pasosDelRegistro, actual: 0),
        const SizedBox(height: AppSpacing.xl),
        Text('¿Cómo vas a usar Cupo?', style: AppTypography.title),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: CupoChoiceTile(
                icono: LucideIcons.graduationCap,
                titulo: 'Soy estudiante',
                descripcion: 'Busco un puesto fijo para ir a la URBE.',
                seleccionado: rol == RolUsuario.estudiante,
                onPressed: () => setState(() => _rol = RolUsuario.estudiante),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CupoChoiceTile(
                icono: LucideIcons.busFront,
                titulo: 'Soy conductor',
                descripcion: 'Ofrezco puestos en mi unidad.',
                seleccionado: rol == RolUsuario.conductor,
                onPressed: () => setState(() => _rol = RolUsuario.conductor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        CupoPrimaryButton(
          label: 'Continuar',
          onPressed: rol == null ? null : () => widget.onElegir(rol),
        ),
      ],
    );
  }
}
