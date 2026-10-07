import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../data/auth_repository.dart';
import 'auth_routes.dart';
import 'auth_scope.dart';

/// L4 — Iniciar sesión.
///
/// Mismo orden de métodos que en el registro —Google primero, luego correo y
/// clave— para que quien vuelve reconozca por dónde entró.
///
/// No navega al terminar: al abrirse la sesión, el `AuthGate` lee la fila de
/// `usuarios` y decide la pantalla según la tabla del apartado 6. Esta
/// pantalla solo tiene que entregar la credencial.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _enviando = false;
  String? _error;

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
      await AuthScope.de(context).repositorio.entrar(
        email: _email.text,
        clave: _password.text,
      );
      // Nada más. El AuthGate se encarga del resto.
    } on AuthFallo catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      // `mounted` porque el widget puede haberse ido mientras se esperaba:
      // llamar a setState sobre un widget desmontado revienta.
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _entrarConGoogle() async {
    setState(() => _error = null);
    try {
      await AuthScope.de(context).repositorio.entrarConGoogle();
    } on AuthFallo catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  Future<void> _recuperarClave() async {
    if (!_email.text.contains('@')) {
      setState(() => _error = 'Escribe tu correo arriba y vuelve a tocar aquí.');
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

    return CupoScreen(
      leading: const CupoBackButton(),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text('Bienvenida de vuelta', style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Entra con el mismo método que usaste al registrarte.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.xl),
        CupoGoogleButton(
          label: 'Entrar con Google',
          onPressed: _enviando ? null : _entrarConGoogle,
        ),
        const SizedBox(height: AppSpacing.xl),
        const CupoDividerLabel('o con tu correo'),
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
          child: CupoPasswordInput(
            controller: _password,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _entrar(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: CupoLink(label: 'Olvidé mi clave', onPressed: _recuperarClave),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          CupoErrorBanner(mensaje: error),
        ],
      ],
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupoPrimaryButton(
            label: 'Entrar',
            onPressed: _enviando ? null : _entrar,
            isLoading: _enviando,
          ),
          const SizedBox(height: AppSpacing.md),
          CupoInlineLinkText(
            before: '¿No tienes cuenta? ',
            linkLabel: 'Créala aquí',
            onTap: () => Navigator.of(
              context,
            ).pushReplacementNamed(AuthRoutes.signUp),
          ),
        ],
      ),
    );
  }
}
