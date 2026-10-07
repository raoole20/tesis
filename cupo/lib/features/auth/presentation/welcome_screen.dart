import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../onboarding/presentation/set_home_screen.dart';
import 'sign_in_form.dart';
import 'sign_up_form.dart';

/// Qué muestra la hoja de la bienvenida.
enum ModoAcceso { bienvenida, iniciarSesion, crearCuenta }

/// L1 — Bienvenida, y también L2 y L4.
///
/// Es una sola pantalla. En [ModoAcceso.bienvenida] la foto ocupa casi todo
/// y la hoja de abajo ofrece los dos caminos. Al elegir uno, la hoja **crece**
/// hasta dejar la foto como cabecera compacta, y su contenido pasa a ser el
/// formulario ([SignInForm] o [SignUpForm]). Volver la pliega otra vez.
///
/// No hay rutas en medio: el formulario vive dentro de la hoja, así que el
/// paso de un camino al otro («Créala», «Inicia sesión») cambia el contenido
/// sin plegar nada. El botón «atrás» del sistema también pliega la hoja en
/// vez de cerrar la app.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.modoInicial = ModoAcceso.bienvenida});

  /// Con qué abre la hoja. Las pruebas lo usan para entrar directo a un
  /// formulario.
  final ModoAcceso modoInicial;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  /// Lo que tarda la hoja en crecer o plegarse.
  static const Duration _duracionHoja = Duration(milliseconds: 420);

  /// Lo que tarda el cruce entre un contenido y otro de la hoja.
  static const Duration _duracionContenido = Duration(milliseconds: 260);

  late ModoAcceso _modo = widget.modoInicial;

  /// 0 = hoja plegada (bienvenida), 1 = hoja desplegada (formulario).
  late final AnimationController _despliegue = AnimationController(
    vsync: this,
    duration: _duracionHoja,
    value: widget.modoInicial == ModoAcceso.bienvenida ? 0 : 1,
  );

  late final Animation<double> _curva = CurvedAnimation(
    parent: _despliegue,
    curve: Curves.easeInOutCubic,
  );

  @override
  void dispose() {
    _despliegue.dispose();
    super.dispose();
  }

  void _abrir(ModoAcceso modo) {
    setState(() => _modo = modo);
    _despliegue.forward();
  }

  void _volver() {
    FocusScope.of(context).unfocus();
    setState(() => _modo = ModoAcceso.bienvenida);
    _despliegue.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final margenInferior = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: _modo == ModoAcceso.bienvenida,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _volver();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: LayoutBuilder(
            builder: (context, caja) {
              // Dónde empieza la hoja en cada extremo. Plegada, deja a la
              // foto todo menos su propio alto; desplegada, deja la cabecera
              // compacta.
              const topeDesplegada =
                  AppSizes.heroCompact - AppSizes.heroOverlap;
              final topePlegada = math.max(
                topeDesplegada,
                caja.maxHeight - AppSizes.welcomeSheet - margenInferior,
              );

              return AnimatedBuilder(
                animation: _curva,
                builder: (context, hoja) {
                  final t = _curva.value;
                  final tope = lerpDouble(topePlegada, topeDesplegada, t)!;

                  return Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        height: tope + AppSizes.heroOverlap,
                        child: CupoHero(
                          compactness: t,
                          headline: 'Tu puesto fijo hasta la URBE',
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: tope,
                        right: 0,
                        bottom: 0,
                        child: hoja!,
                      ),
                    ],
                  );
                },
                child: CupoSheet(
                  child: SafeArea(
                    top: false,
                    child: AnimatedSwitcher(
                      duration: _duracionContenido,
                      layoutBuilder: (actual, anteriores) => Stack(
                        fit: StackFit.expand,
                        children: [...anteriores, ?actual],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_modo),
                        child: _contenido(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    return switch (_modo) {
      ModoAcceso.bienvenida => _Caminos(
        onIniciarSesion: () => _abrir(ModoAcceso.iniciarSesion),
        onCrearCuenta: () => _abrir(ModoAcceso.crearCuenta),
      ),
      ModoAcceso.iniciarSesion => SignInForm(
        onVolver: _volver,
        onCrearCuenta: () => _abrir(ModoAcceso.crearCuenta),
      ),
      ModoAcceso.crearCuenta => SignUpForm(
        onVolver: _volver,
        onIniciarSesion: () => _abrir(ModoAcceso.iniciarSesion),
      ),
    };
  }
}

/// Contenido de la hoja plegada: los dos caminos, el recorrido de invitado y
/// el aviso legal al pie.
///
/// Se desplaza si no cabe —letra grande del sistema, pantalla baja—, y si
/// sobra alto, el aviso legal se queda abajo.
class _Caminos extends StatelessWidget {
  const _Caminos({required this.onIniciarSesion, required this.onCrearCuenta});

  final VoidCallback onIniciarSesion;
  final VoidCallback onCrearCuenta;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, caja) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: caja.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                CupoPrimaryButton(
                  label: 'Iniciar sesión',
                  onPressed: onIniciarSesion,
                ),
                const SizedBox(height: AppSpacing.sm),
                CupoSecondaryButton(
                  label: 'Crear cuenta',
                  onPressed: onCrearCuenta,
                ),
                const SizedBox(height: AppSpacing.md),
                // Recorrido del estudiante con datos de ejemplo, sin crear
                // cuenta: sirve para la demostración al tutor.
                Center(
                  child: CupoLink(
                    label: 'Explorar como invitado',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SetHomeScreen(),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: AppSpacing.md),
                Text.rich(
                  TextSpan(
                    style: AppTypography.legal,
                    children: [
                      const TextSpan(text: 'Al continuar aceptas los '),
                      TextSpan(
                        text: 'Términos',
                        style: AppTypography.legalStrong,
                      ),
                      const TextSpan(text: ' y el '),
                      TextSpan(
                        text: 'Aviso de privacidad',
                        style: AppTypography.legalStrong,
                      ),
                      const TextSpan(
                        text:
                            '. Cupo es un servicio independiente, no '
                            'afiliado a la universidad.',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
