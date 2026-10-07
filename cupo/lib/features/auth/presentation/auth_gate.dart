import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/theme.dart';
import '../data/auth_repository.dart';
import '../domain/resolver_destino.dart';
import '../domain/usuario.dart';
import 'auth_routes.dart';
import 'auth_scope.dart';
import 'destino_pantalla.dart';
import 'estado/cargando_screen.dart';
import 'estado/falla_screen.dart';
import 'verify_phone_screen.dart';
import 'welcome_screen.dart';

/// La raíz de la app: decide qué se ve, según haya sesión y en qué estado esté.
///
/// Sustituye al `initialRoute` fijo. El primer ingreso ya no es «la pantalla
/// con la que arranca la app», es «lo que se ve cuando no hay sesión».
///
/// Escucha dos fuentes distintas, y la diferencia entre ellas es exactamente
/// la que hay entre `Future` y `Stream`:
///
/// - **`cambiosDeSesion`** es un `Stream`: entrar, salir y refrescar el token
///   son muchos eventos a lo largo del tiempo.
/// - **`cargarUsuarioActual()`** es un `Future`: la fila de `usuarios` se lee
///   una vez, al abrir sesión.
/// - **`observarUsuario()`** vuelve a ser un `Stream`, porque esa fila cambia
///   por debajo: el administrador aprueba, rechaza o suspende, y la app tiene
///   que reaccionar sin que la persona haga nada.
///
/// Este widget construye el [MaterialApp] en vez de vivir dentro de él, y eso
/// tiene un motivo: el [AuthScope] va en `builder`, o sea **por encima** del
/// `Navigator`. Si estuviera dentro de `home`, las pantallas empujadas encima
/// —registro, login— quedarían fuera de su alcance y no podrían llegar al
/// repositorio.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.repositorio});

  final AuthRepository repositorio;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Llave del `Navigator` del [MaterialApp] de abajo. Hace falta porque el
  /// `context` de este widget está por encima de ese `Navigator`, y
  /// `Navigator.of(context)` no lo encontraría.
  final _navegadorKey = GlobalKey<NavigatorState>();

  /// Suscripciones vivas. Hay que cancelarlas en [dispose] o la app sigue
  /// escuchando eventos de un widget que ya no existe.
  StreamSubscription<AuthState>? _suscripcionSesion;
  StreamSubscription<Usuario>? _suscripcionUsuario;

  Usuario? _usuario;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    // Supabase emite un primer evento con la sesión guardada en el teléfono,
    // así que no hace falta preguntar por ella aparte: si la hay, llega sola.
    _suscripcionSesion = widget.repositorio.cambiosDeSesion.listen(
      _alCambiarLaSesion,
      onError: _mostrarFalla,
    );
  }

  @override
  void dispose() {
    _suscripcionSesion?.cancel();
    _suscripcionUsuario?.cancel();
    super.dispose();
  }

  Future<void> _alCambiarLaSesion(AuthState estado) async {
    final sesion = estado.session;

    if (sesion == null) {
      await _suscripcionUsuario?.cancel();
      _suscripcionUsuario = null;
      if (!mounted) return;
      setState(() {
        _usuario = null;
        _error = null;
        _cargando = false;
      });
      _volverALaRaiz();
      return;
    }

    // Un refresco de token llega como un evento más, pero el usuario es el
    // mismo: no hace falta volver a leer la fila.
    if (_usuario?.id == sesion.user.id &&
        estado.event == AuthChangeEvent.tokenRefreshed) {
      return;
    }

    await _cargarYObservar(sesion.user.id);
  }

  Future<void> _cargarYObservar(String idUsuario) async {
    if (mounted) setState(() => _cargando = true);

    try {
      // Primero la lectura única: es la que decide la pantalla inicial.
      final usuario = await widget.repositorio.cargarUsuarioActual();
      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _error = null;
        _cargando = false;
      });
      _volverALaRaiz();

      // Y después el stream, para enterarse de los cambios que haga el
      // administrador mientras la app está abierta.
      await _suscripcionUsuario?.cancel();
      _suscripcionUsuario = widget.repositorio
          .observarUsuario(idUsuario)
          .listen(
            (actualizado) {
              if (mounted) setState(() => _usuario = actualizado);
            },
            // Si Realtime falla, la app sigue funcionando con lo que ya leyó:
            // se pierde la reacción en vivo, no la sesión.
            onError: (Object _) {},
          );
    } catch (e) {
      _mostrarFalla(e);
    }
  }

  /// Descarta las pantallas que el primer ingreso dejó apiladas.
  ///
  /// Registro y login se empujan sobre el `Navigator`. Cuando la sesión
  /// cambia, este widget cambia lo que hay en la raíz, pero lo apilado encima
  /// seguiría tapándolo.
  void _volverALaRaiz() {
    final navegador = _navegadorKey.currentState;
    if (navegador != null && navegador.canPop()) {
      navegador.popUntil((ruta) => ruta.isFirst);
    }
  }

  void _mostrarFalla(Object e) {
    if (!mounted) return;
    setState(() {
      _error = e is AuthFallo ? e.mensaje : e.toString();
      _cargando = false;
    });
  }

  Future<void> _reintentar() async {
    final id = widget.repositorio.idUsuarioActual;
    if (id == null) {
      await widget.repositorio.salir();
      return;
    }
    await _cargarYObservar(id);
  }

  /// Qué se ve en la raíz, según el estado de la cuenta.
  Widget _contenido() {
    final usuario = _usuario;
    final error = _error;

    if (_cargando) return const CargandoScreen();

    if (error != null) {
      return FallaScreen(
        mensaje: error,
        onReintentar: _reintentar,
        onSalir: widget.repositorio.salir,
      );
    }

    // Sin sesión: el primer ingreso.
    if (usuario == null) return const WelcomeScreen();

    // Con sesión: una sola línea decide todo, y es la tabla del apartado 6.
    return destinoPantalla(destinoDe(usuario));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cupo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: _navegadorKey,

      home: _contenido(),

      // Solo las rutas del primer ingreso. Registro e inicio de sesión no
      // están: viven dentro de la hoja de la bienvenida. Las pantallas de
      // después de la sesión tampoco se empujan por nombre: las elige la
      // tabla del apartado 6, y si además se pudieran empujar habría dos
      // fuentes de verdad.
      routes: {AuthRoutes.verifyPhone: (_) => const VerifyPhoneScreen()},

      // Por encima del Navigator: así el AuthScope alcanza también a las
      // pantallas empujadas.
      builder: (context, child) => AuthScope(
        repositorio: widget.repositorio,
        usuario: _usuario,
        child: child!,
      ),
    );
  }
}
