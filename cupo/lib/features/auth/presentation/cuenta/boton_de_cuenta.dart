import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../../../theme/theme.dart';
import '../../../driver/presentation/vehiculo_screen.dart';
import '../../biometria/servicio_huella.dart';
import '../../data/auth_repository.dart';
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

  /// Si la huella está activa para quien está adentro. `null` mientras se
  /// consulta, y para siempre si el teléfono no tiene lector (o es la web):
  /// en ese caso la opción no se muestra.
  bool? _huellaActiva;
  bool _huellaConsultada = false;
  bool _cambiandoHuella = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_huellaConsultada) {
      _huellaConsultada = true;
      _consultarHuella();
    }
  }

  Future<void> _consultarHuella() async {
    final scope = AuthScope.de(context);
    final huella = scope.huella;
    final usuario = scope.usuario;
    if (huella == null || usuario == null) return;
    if (!await huella.disponible()) return;
    final activa = await huella.activaPara(usuario.email);
    if (mounted) setState(() => _huellaActiva = activa);
  }

  /// Encender: huella, luego la clave en un diálogo, y se guarda. Apagar:
  /// se borra lo guardado, sin pedir nada.
  Future<void> _cambiarHuella(bool encender) async {
    final scope = AuthScope.de(context);
    final huella = scope.huella;
    final usuario = scope.usuario;
    if (huella == null || usuario == null || _cambiandoHuella) return;

    setState(() {
      _cambiandoHuella = true;
      _error = null;
    });

    var activa = !encender;
    String? error;
    try {
      if (!encender) {
        await huella.desactivar();
        activa = false;
      } else {
        final resultado = await huella.confirmarHuella();
        if (!mounted) return;
        if (resultado is HuellaRechazada) error = resultado.mensaje;
        if (resultado is HuellaAprobada) {
          final guardada = await showDialog<bool>(
            context: context,
            builder: (_) => _DialogoClave(
              onConfirmar: (clave) => huella.activar(
                email: usuario.email,
                clave: clave,
                verificar: (email, clave) => scope.repositorio.verificarClave(
                  email: email,
                  clave: clave,
                ),
              ),
            ),
          );
          activa = guardada == true;
        }
      }
    } catch (_) {
      error = encender
          ? 'No se pudo activar la huella. Inténtalo otra vez.'
          : 'No se pudo desactivar la huella. Inténtalo otra vez.';
    }

    if (!mounted) return;
    setState(() {
      _cambiandoHuella = false;
      _huellaActiva = activa;
      _error = error;
    });
  }

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

  /// Cierra la hoja y abre [pantalla] encima de la que la mostró.
  void _abrir(Widget pantalla) {
    final navegador = Navigator.of(context);
    navegador.pop();
    navegador.push(MaterialPageRoute<void>(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    // El usuario puede ser null un instante, entre que la sesión se cierra y
    // el AuthGate descarta esta hoja.
    final usuario = AuthScope.de(context).usuario;
    final error = _error;
    final huellaActiva = _huellaActiva;

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
            if (usuario?.rol == RolUsuario.conductor) ...[
              const SizedBox(height: AppSpacing.md),
              OpcionDeCuenta(
                icono: LucideIcons.carFront,
                titulo: 'Tu vehículo',
                descripcion: 'Regístralo, edita sus datos o elimínalo',
                onPressed: () => _abrir(const VehiculoScreen()),
              ),
            ],
            if (usuario != null && huellaActiva != null) ...[
              const SizedBox(height: AppSpacing.md),
              OpcionDeCuenta(
                icono: LucideIcons.fingerprint,
                titulo: 'Entrar con huella',
                descripcion: 'Entra en este teléfono sin escribir tu clave',
                onPressed: _cambiandoHuella
                    ? null
                    : () => _cambiarHuella(!huellaActiva),
                final_: Semantics(
                  label: 'Entrar con huella',
                  child: Switch(
                    value: huellaActiva,
                    onChanged: _cambiandoHuella ? null : _cambiarHuella,
                  ),
                ),
              ),
            ],
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

/// Pide la clave una sola vez, al activar la huella, y la comprueba antes de
/// cerrarse: así nunca se guarda una clave equivocada.
///
/// Se cierra con `true` si [onConfirmar] terminó bien; con `null` si se
/// canceló.
class _DialogoClave extends StatefulWidget {
  const _DialogoClave({required this.onConfirmar});

  /// Comprueba y guarda. Lanza [AuthFallo] si la clave no sirve.
  final Future<void> Function(String clave) onConfirmar;

  @override
  State<_DialogoClave> createState() => _DialogoClaveState();
}

class _DialogoClaveState extends State<_DialogoClave> {
  final _clave = TextEditingController();
  bool _comprobando = false;
  String? _error;

  @override
  void dispose() {
    _clave.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_comprobando) return;
    if (_clave.text.isEmpty) {
      setState(() => _error = 'Escribe tu clave.');
      return;
    }

    setState(() {
      _comprobando = true;
      _error = null;
    });
    try {
      await widget.onConfirmar(_clave.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _comprobando = false;
          _error = e is AuthFallo
              ? e.mensaje
              : 'No se pudo guardar la huella. Inténtalo otra vez.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;

    return AlertDialog(
      title: Text('Confirma tu clave', style: AppTypography.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'La guardamos cifrada en este teléfono y solo se usa después '
              'de leer tu huella. Escríbela una vez para comprobarla.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            CupoField(
              label: 'Clave',
              child: CupoPasswordInput(
                controller: _clave,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirmar(),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.md),
              CupoErrorBanner(mensaje: error),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _comprobando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _comprobando ? null : _confirmar,
          child: Text(_comprobando ? 'Comprobando…' : 'Activar'),
        ),
      ],
    );
  }
}

/// Una fila de la hoja de la cuenta: mosaico con el icono, título y
/// descripción, y una flecha. Si se pasa [final_], va en lugar de la flecha
/// (por ejemplo, un interruptor).
class OpcionDeCuenta extends StatelessWidget {
  const OpcionDeCuenta({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.onPressed,
    this.final_,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback? onPressed;
  final Widget? final_;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: const BorderSide(color: AppColors.border, width: AppSizes.border),
      ),
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: AppSizes.choiceIconTile,
                height: AppSizes.choiceIconTile,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundMuted,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  icono,
                  size: AppSizes.icon,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: AppTypography.bodyStrong),
                    Text(descripcion, style: AppTypography.helper),
                  ],
                ),
              ),
              final_ ??
                  const Icon(
                    LucideIcons.chevronRight,
                    size: AppSizes.icon,
                    color: AppColors.textSupport,
                  ),
            ],
          ),
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
