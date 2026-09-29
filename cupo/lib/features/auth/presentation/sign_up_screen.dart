import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../data/auth_repository.dart';
import '../domain/rol_usuario.dart';
import 'auth_routes.dart';
import 'auth_scope.dart';

/// L2 — Crear cuenta.
///
/// El párrafo de arriba justifica por qué se piden estos datos: el conductor da
/// crédito, así que necesita saber a quién se lo da. La cédula y el teléfono de
/// WhatsApp están ahí por eso, no por trámite.
///
/// Lo primero es el rol, y no es un detalle: viaja en el `data` del `signUp` y
/// es lo que lee el trigger `crear_usuario()` para decidir si la fila del
/// subtipo va en `estudiantes` o en `conductores`. Después del registro ya no
/// se puede cambiar desde la app — los privilegios por columna se lo prohíben
/// al propio usuario.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.rolInicial = RolUsuario.estudiante});

  final RolUsuario rolInicial;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _idCard = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  late RolUsuario _rol = widget.rolInicial;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _idCard.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validar() {
    if (_name.text.trim().isEmpty) return 'Escribe tu nombre y apellido.';
    if (!_email.text.contains('@')) return 'Escribe un correo válido.';
    if (_idCard.text.trim().isEmpty) return 'Escribe tu cédula.';
    if (_phone.text.trim().isEmpty) return 'Escribe tu teléfono.';
    if (_password.text.length < 6) {
      return 'La clave necesita al menos 6 caracteres.';
    }
    return null;
  }

  Future<void> _crearCuenta() async {
    final falta = _validar();
    if (falta != null) {
      setState(() => _error = falta);
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    // El campo es uno solo: lo que va antes del primer espacio son los
    // nombres, el resto los apellidos. Es una aproximación, y a propósito:
    // dos campos separados espantan más gente de la que arreglan.
    final partes = _name.text.trim().split(RegExp(r'\s+'));
    final nombres = partes.first;
    final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '';

    final repo = AuthScope.de(context).repositorio;

    try {
      await repo.registrar(
        email: _email.text,
        clave: _password.text,
        rol: _rol,
        nombres: nombres,
        apellidos: apellidos,
        telefono: _phone.text,
      );

      // La cédula no viaja en el signUp: el trigger no la escribe, y además
      // tiene restricción de unicidad. Se guarda una vez que ya hay sesión,
      // que es cuando el RLS deja escribir la fila.
      await repo.guardarDatosPersonales(
        nombres: nombres,
        apellidos: apellidos,
        cedula: _idCard.text,
        telefono: _phone.text,
      );

      // No se navega: el AuthGate ve la sesión nueva y enruta según el estado,
      // que en este punto es 'perfil_incompleto'.
    } on AuthFallo catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _conGoogle() async {
    setState(() => _error = null);
    try {
      await AuthScope.de(context).repositorio.entrarConGoogle();
    } on AuthFallo catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;

    return CupoScreen(
      leading: const CupoBackButton(),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text('Crea tu cuenta', style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Los conductores dan crédito: montas primero y pagas después. '
          'Por eso necesitan saber con quién están tratando.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('¿Cómo vas a usar Cupo?', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        CupoChoiceTile(
          titulo: 'Soy estudiante',
          descripcion: 'Busco puesto fijo para ir y volver de la universidad.',
          seleccionado: _rol.esEstudiante,
          onPressed: () => setState(() => _rol = RolUsuario.estudiante),
        ),
        const SizedBox(height: AppSpacing.sm),
        CupoChoiceTile(
          titulo: 'Soy conductor',
          descripcion: 'Hago rutas y quiero llenar los puestos de mi unidad.',
          seleccionado: _rol.esConductor,
          onPressed: () => setState(() => _rol = RolUsuario.conductor),
        ),
        const SizedBox(height: AppSpacing.xl),
        CupoField(
          label: 'Nombre y apellido',
          child: CupoTextInput(
            controller: _name,
            hintText: 'Génesis Materán',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CupoField(
          label: 'Correo',
          helper: 'Con este entras a Cupo.',
          child: CupoTextInput(
            controller: _email,
            hintText: 'genesis@ejemplo.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CupoField(
          label: 'Cédula',
          child: CupoTextInput(
            controller: _idCard,
            hintText: 'V-30.111.222',
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CupoField(
          label: 'Teléfono (el de WhatsApp)',
          helper: 'Por ahí te contacta el conductor.',
          child: CupoTextInput(
            controller: _phone,
            hintText: '0414 000 0000',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CupoField(
          label: 'Clave',
          helper: 'Al menos 6 caracteres.',
          child: CupoPasswordInput(
            controller: _password,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _crearCuenta(),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          CupoErrorBanner(mensaje: error),
        ],
        const SizedBox(height: AppSpacing.xl),
        CupoPrimaryButton(
          label: 'Crear cuenta',
          onPressed: _enviando ? null : _crearCuenta,
          isLoading: _enviando,
        ),
        const SizedBox(height: AppSpacing.lg),
        const CupoDividerLabel('o'),
        const SizedBox(height: AppSpacing.md),
        CupoGoogleButton(
          label: 'Continuar con Google',
          onPressed: _enviando ? null : _conGoogle,
        ),
        const SizedBox(height: AppSpacing.md),
        CupoInlineLinkText(
          before: '¿Ya tienes cuenta? ',
          linkLabel: 'Inicia sesión',
          onTap: () =>
              Navigator.of(context).pushReplacementNamed(AuthRoutes.signIn),
        ),
      ],
    );
  }
}
