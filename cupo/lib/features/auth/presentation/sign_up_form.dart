import 'package:flutter/material.dart';

import '../../../core/venezuela/documento_identidad.dart';
import '../../../core/venezuela/telefono_movil.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../data/auth_repository.dart';
import '../domain/rol_usuario.dart';
import 'auth_scope.dart';
import 'sign_up_role_form.dart';

/// L2, paso 2 de 2 — Los datos de la cuenta, según el rol del paso 1.
///
/// Igual que `SignInForm`, no es una pantalla aparte: vive dentro de la hoja
/// de `WelcomeScreen`, y «volver» e «Inicia sesión» se los pide a ella por
/// [onVolver] y [onIniciarSesion].
///
/// El rol ya viene elegido de `SignUpRoleForm`. Los campos son los mismos para
/// los dos —el `signUp` y el trigger `crear_usuario()` piden lo mismo—, pero
/// el texto le habla a cada uno: al estudiante se le explica que el conductor
/// da crédito y por eso pide cédula y WhatsApp; al conductor, que su cuenta
/// pasa por revisión y que la licencia se pide en el paso siguiente.
class SignUpForm extends StatefulWidget {
  const SignUpForm({
    super.key,
    required this.rol,
    required this.onVolver,
    required this.onIniciarSesion,
  }) : assert(
         rol != RolUsuario.administrador,
         'El administrador no se registra desde la app.',
       );

  /// El rol elegido en el paso 1. Viaja en el `data` del `signUp`.
  final RolUsuario rol;

  /// Vuelve al paso 1, a elegir el rol.
  final VoidCallback onVolver;

  /// Cambia al formulario de inicio de sesión sin plegar la hoja.
  final VoidCallback onIniciarSesion;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _idCard = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  TipoDocumento _tipoDocumento = TipoDocumento.v;
  OperadoraMovil? _operadora;

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
    final documento = validarDocumento(_tipoDocumento, _idCard.text);
    if (documento != null) return documento;
    final telefono = validarTelefono(_operadora, _phone.text);
    if (telefono != null) return telefono;
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

    // Una sola forma por dato —«V-30111222», «+584141234567»— para que las
    // restricciones `unique` de la base detecten los duplicados.
    final cedula = normalizarDocumento(_tipoDocumento, _idCard.text);
    final telefono = normalizarTelefono(_operadora!, _phone.text);

    try {
      await repo.registrar(
        email: _email.text,
        clave: _password.text,
        rol: widget.rol,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
      );

      // La cédula no viaja en el signUp: el trigger no la escribe, y además
      // tiene restricción de unicidad. Se guarda una vez que ya hay sesión,
      // que es cuando el RLS deja escribir la fila.
      await repo.guardarDatosPersonales(
        nombres: nombres,
        apellidos: apellidos,
        cedula: cedula,
        telefono: telefono,
      );

      // No se navega: el AuthGate ve la sesión nueva y enruta según el estado,
      // que en este punto es 'perfil_incompleto'.
    } on AuthFallo catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final textos = _TextosDelRol.de(widget.rol);

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
        const CupoStepIndicator(pasos: pasosDelRegistro, actual: 1),
        const SizedBox(height: AppSpacing.xl),
        Text(textos.titulo, style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(textos.explicacion, style: AppTypography.body),
        const SizedBox(height: AppSpacing.xl),
        CupoField(
          label: 'Nombre y apellido',
          child: CupoTextInput(
            controller: _name,
            hintText: textos.nombreDeEjemplo,
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
            hintText: textos.correoDeEjemplo,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CupoField(
          label: textos.etiquetaDocumento,
          helper: _tipoDocumento == TipoDocumento.j
              ? 'El RIF de la empresa o cooperativa, con su último dígito.'
              : null,
          child: CupoDocumentoInput(
            controller: _idCard,
            tipo: _tipoDocumento,
            tipos: textos.tiposDocumento,
            onTipoChanged: (tipo) => setState(() => _tipoDocumento = tipo),
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CupoField(
          label: 'Teléfono (el de WhatsApp)',
          helper: textos.ayudaTelefono,
          child: CupoTelefonoInput(
            controller: _phone,
            operadora: _operadora,
            onOperadoraChanged: (o) => setState(() => _operadora = o),
            textInputAction: TextInputAction.next,
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
      ],
    );
  }
}

/// Lo que el paso 2 le dice a cada rol. Los campos no cambian; el porqué sí.
class _TextosDelRol {
  const _TextosDelRol({
    required this.titulo,
    required this.explicacion,
    required this.nombreDeEjemplo,
    required this.correoDeEjemplo,
    required this.ayudaTelefono,
    required this.etiquetaDocumento,
    required this.tiposDocumento,
  });

  factory _TextosDelRol.de(RolUsuario rol) => rol.esConductor
      ? const _TextosDelRol(
          titulo: 'Tu cuenta de conductor',
          explicacion:
              'Antes de ofrecer puestos, revisamos quién maneja. Primero tus '
              'datos; después te pedimos la licencia y el certificado médico.',
          nombreDeEjemplo: 'José Rondón',
          correoDeEjemplo: 'jose@ejemplo.com',
          ayudaTelefono: 'Por ahí te escriben los estudiantes.',
          // Hay conductores que trabajan a nombre de una empresa o de una
          // cooperativa de transporte: esos se registran con el RIF.
          etiquetaDocumento: 'Cédula o RIF',
          tiposDocumento: [TipoDocumento.v, TipoDocumento.j],
        )
      : const _TextosDelRol(
          titulo: 'Tu cuenta de estudiante',
          explicacion:
              'Los conductores dan crédito: montas primero y pagas después. '
              'Por eso necesitan saber con quién están tratando.',
          nombreDeEjemplo: 'Génesis Materán',
          correoDeEjemplo: 'genesis@ejemplo.com',
          ayudaTelefono: 'Por ahí te contacta el conductor.',
          etiquetaDocumento: 'Cédula',
          tiposDocumento: [TipoDocumento.v],
        );

  final String titulo;
  final String explicacion;
  final String nombreDeEjemplo;
  final String correoDeEjemplo;
  final String ayudaTelefono;

  /// Etiqueta del campo del documento.
  final String etiquetaDocumento;

  /// Letras que puede elegir. Con una sola, el prefijo queda fijo.
  final List<TipoDocumento> tiposDocumento;
}
