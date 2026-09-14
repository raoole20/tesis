import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import 'auth_routes.dart';

/// L2 — Crear cuenta.
///
/// El párrafo de arriba justifica por qué se piden estos datos: el conductor da
/// crédito, así que necesita saber a quién se lo da. La cédula y el teléfono de
/// WhatsApp están ahí por eso, no por trámite.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _idCard = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _idCard.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pushNamed(AuthRoutes.verifyPhone);

  @override
  Widget build(BuildContext context) {
    return CupoScreen(
      leading: const CupoBackButton(),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text('Crea tu cuenta', style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Los conductores te dan crédito: montas primero y pagas después. '
          'Por eso necesitan saber con quién están tratando.',
          style: AppTypography.body,
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
          helper: 'Te mandamos un código por WhatsApp para verificarlo.',
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
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        CupoPrimaryButton(label: 'Crear cuenta', onPressed: _submit),
        const SizedBox(height: AppSpacing.lg),
        const CupoDividerLabel('o'),
        const SizedBox(height: AppSpacing.md),
        CupoGoogleButton(
          label: 'Continuar con Google',
          onPressed: _submit,
        ),
      ],
    );
  }
}
