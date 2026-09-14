import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import 'auth_routes.dart';

/// L4 — Iniciar sesión.
///
/// Mismo orden de métodos que en el registro —Google primero, luego teléfono y
/// clave— para que quien vuelve reconozca por dónde entró.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    // Aquí entra el inicio de sesión contra el backend.
  }

  @override
  Widget build(BuildContext context) {
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
        CupoGoogleButton(label: 'Entrar con Google', onPressed: _submit),
        const SizedBox(height: AppSpacing.xl),
        const CupoDividerLabel('o con tu teléfono'),
        const SizedBox(height: AppSpacing.xl),
        CupoField(
          label: 'Teléfono',
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
          child: CupoPasswordInput(
            controller: _password,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: CupoLink(label: 'Olvidé mi clave', onPressed: () {}),
        ),
      ],
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupoPrimaryButton(label: 'Entrar', onPressed: _submit),
          const SizedBox(height: AppSpacing.md),
          CupoInlineLinkText(
            before: '¿No tienes cuenta? ',
            linkLabel: 'Créala aquí',
            onTap: () => Navigator.of(context).pushReplacementNamed(
              AuthRoutes.signUp,
            ),
          ),
        ],
      ),
    );
  }
}
