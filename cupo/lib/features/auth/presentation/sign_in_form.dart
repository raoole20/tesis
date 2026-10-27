import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../biometria/servicio_huella.dart';
import '../data/auth_repository.dart';
import 'auth_scope.dart';

/// L4 — Iniciar sesión, como contenido de la hoja de la bienvenida.
///
/// No es una pantalla aparte: la hoja de `WelcomeScreen` crece y este
/// formulario aparece dentro. Por eso no navega: «volver» y «Créala» se los
/// pide a la bienvenida por [onVolver] y [onCrearCuenta].
///
/// Tampoco navega al terminar: al abrirse la sesión, el `AuthGate` lee la fila
/// de `usuarios` y decide la pantalla según la tabla del apartado 6. Este
/// formulario solo tiene que entregar la credencial.
class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
    required this.onVolver,
    required this.onCrearCuenta,
  });

  /// Pliega la hoja y vuelve a la bienvenida.
  final VoidCallback onVolver;

  /// Cambia al formulario de registro sin plegar la hoja.
  final VoidCallback onCrearCuenta;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _enviando = false;
  String? _error;

  /// El correo con huella activa en este teléfono, o `null` si no hay (o el
  /// teléfono no tiene lector). Solo con él se muestra «Entrar con huella».
  String? _correoConHuella;
  bool _huellaConsultada = false;
  bool _entrandoConHuella = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aquí y no en initState: el AuthScope se lee del contexto, y eso no se
    // puede antes de este punto. La bandera evita repetir la consulta.
    if (!_huellaConsultada) {
      _huellaConsultada = true;
      _consultarHuella();
    }
  }

  Future<void> _consultarHuella() async {
    final huella = AuthScope.de(context).huella;
    if (huella == null || !await huella.disponible()) return;
    final correo = await huella.correoActivo();
    if (mounted) setState(() => _correoConHuella = correo);
  }

  Future<void> _entrarConHuella() async {
    final huella = AuthScope.de(context).huella;
    if (huella == null) return;
    final repositorio = AuthScope.de(context).repositorio;

    setState(() {
      _entrandoConHuella = true;
      _error = null;
    });

    final resultado = await huella.entrar(
      entrar: (email, clave) => repositorio.entrar(email: email, clave: clave),
    );
    if (!mounted) return;

    // Si salió bien, el AuthGate ya cambió de pantalla: no hay nada que hacer.
    // Si se canceló, tampoco: no es un error.
    setState(() {
      _entrandoConHuella = false;
      if (resultado case HuellaRechazada(:final mensaje, :final seDesactivo)) {
        _error = mensaje;
        if (seDesactivo) _correoConHuella = null;
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validar() {
    if (!_email.text.contains('@')) return 'Escribe un correo válido.';
    if (_password.text.isEmpty) return 'Escribe tu clave.';
    return null;
  }

  Future<void> _entrar() async {
    final falta = _validar();
    if (falta != null) {
      setState(() => _error = falta);
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await AuthScope.de(context).repositorio
          .entrar(email: _email.text, clave: _password.text);
      // Nada más. El AuthGate se encarga del resto.
    } on AuthFallo catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      // `mounted` porque el widget puede haberse ido mientras se esperaba:
      // llamar a setState sobre un widget desmontado revienta.
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _recuperarClave() async {
    if (!_email.text.contains('@')) {
      setState(
        () => _error = 'Escribe tu correo arriba y vuelve a tocar aquí.',
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthScope.de(context).repositorio.recuperarClave(_email.text);
      messenger.showSnackBar(
        const SnackBar(content: Text('Te mandamos un correo para cambiarla.')),
      );
    } on AuthFallo catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final correoConHuella = _correoConHuella;
    final ocupado = _enviando || _entrandoConHuella;

    return CupoSheetBody(
      title: 'Iniciar sesión',
      onBack: widget.onVolver,
      footer: CupoInlineLinkText(
        before: '¿No tienes cuenta? ',
        linkLabel: 'Créala',
        onTap: widget.onCrearCuenta,
      ),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text('Qué bueno verte', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xl),
        CupoField(
          label: 'Correo',
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
          label: 'Clave',
          trailing: CupoLink(
            label: '¿La olvidaste?',
            onPressed: _recuperarClave,
            style: AppTypography.linkSmall,
          ),
          child: CupoPasswordInput(
            controller: _password,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _entrar(),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          CupoErrorBanner(mensaje: error),
        ],
        const SizedBox(height: AppSpacing.xl),
        CupoPrimaryButton(
          label: 'Entrar',
          onPressed: ocupado ? null : _entrar,
          isLoading: _enviando,
        ),
        if (correoConHuella != null) ...[
          const SizedBox(height: AppSpacing.sm),
          CupoSecondaryButton(
            label: 'Entrar con huella',
            leading: const Icon(LucideIcons.fingerprint, size: AppSizes.icon),
            onPressed: ocupado ? null : _entrarConHuella,
            isLoading: _entrandoConHuella,
          ),
          const SizedBox(height: AppSpacing.xs),
          // El correo a la vista: si en el teléfono entró otra persona, sabe
          // de quién es la huella antes de tocar el botón.
          Text(
            'Como $correoConHuella',
            style: AppTypography.meta,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
