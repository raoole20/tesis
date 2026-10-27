import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../../../theme/theme.dart';
import '../../domain/rol_usuario.dart';
import '../../domain/usuario.dart';
import '../auth_scope.dart';

/// El avatar de quien está adentro, y la puerta a su cuenta.
///
/// Es la pieza común de todas las pantallas posteriores al login: va en la
/// esquina del saludo, sea cual sea el rol. Lee el usuario del [AuthScope],
/// así que no recibe nada: una pantalla nueva solo tiene que ponerlo.
///
/// Tocarlo abre [mostrarHojaDeCuenta], que es donde vive «Cerrar sesión».
class BotonDeCuenta extends StatelessWidget {
  const BotonDeCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.usuarioDe(context);

    return Semantics(
      button: true,
      label: 'Tu cuenta',
      excludeSemantics: true,
      child: Material(
        color: AppColors.primarySoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => mostrarHojaDeCuenta(context),
          child: _Avatar(iniciales: usuario.iniciales),
        ),
      ),
    );
  }
}

/// Abre la hoja con los datos de la cuenta y la acción de cerrar sesión.
Future<void> mostrarHojaDeCuenta(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    elevation: 0,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (_) => const _HojaDeCuenta(),
  );
}

class _HojaDeCuenta extends StatefulWidget {
  const _HojaDeCuenta();

  @override
  State<_HojaDeCuenta> createState() => _HojaDeCuentaState();
}

class _HojaDeCuentaState extends State<_HojaDeCuenta> {
  bool _saliendo = false;
  String? _error;

  /// No hace falta navegar a ningún lado: el `AuthGate` oye el cambio de
  /// sesión, descarta lo apilado —esta hoja incluida— y muestra la
  /// bienvenida.
  Future<void> _cerrarSesion() async {
    setState(() {
      _saliendo = true;
      _error = null;
    });

    try {
      await AuthScope.de(context).repositorio.salir();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saliendo = false;
        _error =
            'No se pudo cerrar la sesión. Revisa tu conexión e inténtalo '
            'otra vez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // El usuario puede ser null un instante, entre que la sesión se cierra y
    // el AuthGate descarta esta hoja.
    final usuario = AuthScope.de(context).usuario;
    final error = _error;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          AppSpacing.screenBottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tu cuenta', style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            if (usuario != null) _Identidad(usuario: usuario),
            const SizedBox(height: AppSpacing.xl),
            if (error != null) ...[
              CupoErrorBanner(mensaje: error),
              const SizedBox(height: AppSpacing.md),
            ],
            CupoSecondaryButton(
              label: 'Cerrar sesión',
              leading: const Icon(LucideIcons.logOut, size: AppSizes.icon),
              isLoading: _saliendo,
              onPressed: _cerrarSesion,
            ),
          ],
        ),
      ),
    );
  }
}

class _Identidad extends StatelessWidget {
  const _Identidad({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: _Avatar(iniciales: usuario.iniciales),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nombreParaMostrar,
                  style: AppTypography.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${_rotuloDelRol(usuario.rol)} · ${usuario.email}',
                  style: AppTypography.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _rotuloDelRol(RolUsuario rol) => switch (rol) {
    RolUsuario.estudiante => 'Estudiante',
    RolUsuario.conductor => 'Conductor',
    RolUsuario.administrador => 'Administrador',
  };
}

/// El círculo con las iniciales. El fondo lo pone quien lo usa: el botón lo
/// necesita en su `Material` para que se vea la onda al tocar.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.iniciales});

  final String iniciales;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSizes.iconButton,
      child: Center(
        child: Text(
          iniciales,
          style: AppTypography.label.copyWith(color: AppColors.primaryDeep),
        ),
      ),
    );
  }
}
