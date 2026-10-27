import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/cola_de_envio.dart';
import '../domain/muestra_rastreo.dart';
import '../domain/protocolo_rastreo.dart';

/// En qué va la prueba.
enum EtapaPrueba {
  /// Eligiendo la configuración.
  lista,

  /// El flujo de ubicación corre, pero todavía no llega la primera: el reloj
  /// de las fases no ha empezado.
  buscandoGps,

  enCurso,

  /// Pasaron las tres fases.
  terminada,

  /// La persona la detuvo antes de tiempo.
  detenida;

  bool get activa => this == buscandoGps || this == enCurso;

  bool get cerrada => this == terminada || this == detenida;
}

/// Lo que se decide antes de empezar.
class ConfigPrueba {
  const ConfigPrueba({
    required this.duracion,
    required this.wakelock,
    required this.permiso,
    this.bateriaSinRestriccion,
    this.dispositivo,
    this.intervalo = ProtocoloRastreo.intervaloPorOmision,
  });

  final DuracionPrueba duracion;
  final bool wakelock;
  final PermisoRastreo permiso;
  final bool? bateriaSinRestriccion;
  final String? dispositivo;
  final Duration intervalo;

  ProtocoloRastreo get protocolo =>
      ProtocoloRastreo(duracionFase: duracion.porFase, intervalo: intervalo);
}

/// Abre el flujo de ubicaciones con la configuración de la prueba.
typedef AbrirPosiciones = Stream<Position> Function(ConfigPrueba config);

/// Manda filas ya armadas de `spike_posiciones`. Si falla, lanza.
typedef EnviarFilas = Future<void> Function(List<Map<String, Object?>> filas);

/// Avisa que empezó una fase, o que terminó la prueba si [fase] es `null`.
typedef AlCambiarDeFase = void Function(
  FaseRastreo? fase,
  SesionRastreo sesion,
);

/// Traduce el estado de Flutter al espejo de `domain/`.
EstadoApp estadoAppDe(AppLifecycleState? estado) => switch (estado) {
  // Sin estado todavía: la app acaba de arrancar y está a la vista.
  null || AppLifecycleState.resumed => EstadoApp.resumed,
  AppLifecycleState.inactive => EstadoApp.inactive,
  AppLifecycleState.paused => EstadoApp.paused,
  AppLifecycleState.hidden => EstadoApp.hidden,
  AppLifecycleState.detached => EstadoApp.detached,
};

/// Corre una sesión del spike de rastreo: escucha el GPS, numera y fecha
/// cada muestra, la encola, la manda a Supabase y lleva el reloj de las
/// fases.
///
/// Todo lo de plataforma entra inyectado (flujo de ubicaciones, envío,
/// estado de la app y de la pantalla, reloj), para que se pueda probar sin
/// teléfono.
///
/// Las fases se cuentan con la hora del teléfono (`DateTime.now()`) y no con
/// un `Stopwatch`: el reloj monótono de Android se detiene mientras el
/// procesador duerme, y con la pantalla apagada eso desfasaría las fases.
class RastreadorDePrueba extends ChangeNotifier {
  RastreadorDePrueba({
    required this._abrirPosiciones,
    required this._enviar,
    EstadoApp Function()? estadoApp,
    Future<bool?> Function()? pantallaEncendida,
    DateTime Function()? reloj,
    Random? azar,
    this.alCambiarDeFase,
    this.periodoReloj = const Duration(seconds: 1),
  }) : _estadoApp =
           estadoApp ??
           (() => estadoAppDe(WidgetsBinding.instance.lifecycleState)),
       _pantallaEncendida = pantallaEncendida ?? (() async => null),
       _reloj = reloj ?? DateTime.now,
       _azar = azar ?? Random.secure();

  final AbrirPosiciones _abrirPosiciones;
  final EnviarFilas _enviar;
  final EstadoApp Function() _estadoApp;
  final Future<bool?> Function() _pantallaEncendida;
  final DateTime Function() _reloj;
  final Random _azar;

  final AlCambiarDeFase? alCambiarDeFase;

  /// Cada cuánto se revisa el reloj de las fases y se refresca la pantalla.
  final Duration periodoReloj;

  EtapaPrueba _etapa = EtapaPrueba.lista;
  ConfigPrueba? _config;
  SesionRastreo? _sesion;
  FaseRastreo? _fase;
  ColaDeEnvio? _cola;
  StreamSubscription<Position>? _suscripcion;
  Timer? _tic;
  int _seq = 0;
  DateTime? _buscandoDesde;
  DateTime? _cerradaEn;
  DateTime? _ultimoIntento;
  DateTime? _errorEnvioEn;
  String? _errorGps;
  DateTime? _errorGpsEn;
  bool _desechado = false;

  EtapaPrueba get etapa => _etapa;
  ConfigPrueba? get config => _config;
  SesionRastreo? get sesion => _sesion;

  /// La fase en curso; `null` antes de la primera ubicación y al terminar.
  FaseRastreo? get fase => _etapa == EtapaPrueba.enCurso ? _fase : null;

  /// Tiempo desde la primera ubicación. Se congela al cerrar la sesión.
  Duration get transcurrido {
    final sesion = _sesion;
    if (sesion == null) return Duration.zero;
    final hasta = _cerradaEn ?? _reloj();
    final t = hasta.difference(sesion.inicio);
    final total = sesion.protocolo.total;
    if (t.isNegative) return Duration.zero;
    return t > total ? total : t;
  }

  /// Lo que falta para el siguiente cambio de fase.
  Duration get restanteEnFase {
    final sesion = _sesion;
    if (sesion == null || _etapa != EtapaPrueba.enCurso) return Duration.zero;
    return sesion.protocolo.restanteEn(transcurrido);
  }

  /// Cuánto lleva buscando la primera ubicación.
  Duration get buscando {
    final desde = _buscandoDesde;
    if (desde == null || _etapa != EtapaPrueba.buscandoGps) {
      return Duration.zero;
    }
    return _reloj().difference(desde);
  }

  int get capturadas => _cola?.capturadas ?? 0;
  int get enviadas => _cola?.enviadas ?? 0;
  int get pendientes => _cola?.pendientes ?? 0;
  int get fallosDeEnvio => _cola?.fallos ?? 0;

  /// El último envío fallido, aunque la cola ya se haya puesto al día.
  Object? get errorEnvio => _cola?.ultimoError;
  DateTime? get errorEnvioEn => _errorEnvioEn;

  /// El último problema del flujo de ubicación, ya redactado.
  String? get errorGps => _errorGps;
  DateTime? get errorGpsEn => _errorGpsEn;

  /// Abre el flujo de ubicación. El reloj de las fases arranca con la
  /// primera ubicación que llegue.
  void iniciar(ConfigPrueba config) {
    if (_etapa.activa) return;
    _config = config;
    _sesion = null;
    _fase = null;
    _seq = 0;
    _cerradaEn = null;
    _ultimoIntento = null;
    _errorEnvioEn = null;
    _errorGps = null;
    _errorGpsEn = null;
    _cola = ColaDeEnvio(enviar: _enviarLote);
    _etapa = EtapaPrueba.buscandoGps;
    _buscandoDesde = _reloj();
    _suscripcion = _abrirPosiciones(config).listen(
      (posicion) => unawaited(_alLlegar(posicion)),
      onError: _alFallarGps,
      onDone: _alCerrarseElFlujo,
    );
    _tic?.cancel();
    _tic = Timer.periodic(periodoReloj, (_) => revisarReloj());
    notifyListeners();
  }

  /// Corta la prueba antes de tiempo. Lo pendiente se sigue reintentando.
  Future<void> detener() => _cerrar(EtapaPrueba.detenida);

  /// Vuelve a la configuración para otra corrida. Solo con la cola vacía,
  /// para no perder muestras de la anterior.
  void reiniciar() {
    if (!_etapa.cerrada || pendientes > 0) return;
    _etapa = EtapaPrueba.lista;
    _sesion = null;
    _fase = null;
    notifyListeners();
  }

  /// Intenta mandar lo pendiente ya, sin esperar al próximo tic.
  Future<void> reintentar() => _vaciar();

  /// Avanza el reloj de las fases y reintenta lo pendiente. La llama un
  /// `Timer` cada [periodoReloj]; las pruebas la llaman a mano.
  @visibleForTesting
  void revisarReloj() {
    final sesion = _sesion;
    if (_etapa == EtapaPrueba.enCurso && sesion != null) {
      final fase = sesion.protocolo.faseEn(_reloj().difference(sesion.inicio));
      if (fase == null) {
        unawaited(_cerrar(EtapaPrueba.terminada));
        return;
      }
      _cambiarDeFase(fase, sesion);
    }

    // Sin muestras nuevas (GPS trabado, prueba cerrada), lo pendiente se
    // reintenta igual, a lo sumo una vez por intervalo.
    final cola = _cola;
    final intervalo =
        _config?.intervalo ?? ProtocoloRastreo.intervaloPorOmision;
    final ultimo = _ultimoIntento;
    if (cola != null &&
        cola.pendientes > 0 &&
        !cola.enviando &&
        (ultimo == null || _reloj().difference(ultimo) >= intervalo)) {
      unawaited(_vaciar());
    }

    if (_etapa.cerrada && (cola == null || cola.pendientes == 0)) {
      _tic?.cancel();
      _tic = null;
    }
    notifyListeners();
  }

  Future<void> _alLlegar(Position posicion) async {
    if (!_etapa.activa) return;
    final config = _config;
    if (config == null) return;
    final ahora = _reloj();

    var sesion = _sesion;
    if (sesion == null) {
      sesion = SesionRastreo(
        id: SesionRastreo.nuevoId(_azar),
        inicio: ahora,
        protocolo: config.protocolo,
        wakelock: config.wakelock,
        permiso: config.permiso,
        bateriaSinRestriccion: config.bateriaSinRestriccion,
        dispositivo: config.dispositivo,
      );
      _sesion = sesion;
      _etapa = EtapaPrueba.enCurso;
    }

    final fase = sesion.protocolo.faseEn(ahora.difference(sesion.inicio));
    if (fase == null) {
      await _cerrar(EtapaPrueba.terminada);
      return;
    }
    _cambiarDeFase(fase, sesion);

    // El número y la hora se fijan antes de esperar a la plataforma: son los
    // de la captura, pase lo que pase después.
    final seq = ++_seq;
    final estado = _estadoApp();
    final pantalla = await _pantallaEncendida().timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );

    _cola?.encolar(
      MuestraRastreo(
        seq: seq,
        lat: posicion.latitude,
        lng: posicion.longitude,
        precisionM: posicion.accuracy,
        fijadaEn: posicion.timestamp,
        capturadaEn: ahora,
        estadoApp: estado,
        pantallaEncendida: pantalla,
        fase: fase,
      ),
    );
    notifyListeners();
    await _vaciar();
  }

  void _cambiarDeFase(FaseRastreo fase, SesionRastreo sesion) {
    if (fase == _fase) return;
    _fase = fase;
    alCambiarDeFase?.call(fase, sesion);
  }

  void _alFallarGps(Object error) {
    _errorGps = switch (error) {
      LocationServiceDisabledException() =>
        'Se apagó la ubicación del teléfono.',
      PermissionDeniedException() => 'Se quitó el permiso de ubicación.',
      _ => 'El GPS reportó un error: $error',
    };
    _errorGpsEn = _reloj();
    notifyListeners();
  }

  void _alCerrarseElFlujo() {
    if (!_etapa.activa) return;
    // El reloj sigue: el silencio que venga se verá como brecha en el
    // reporte, que es lo honesto.
    _errorGps = 'Android cerró el flujo de ubicación.';
    _errorGpsEn = _reloj();
    notifyListeners();
  }

  Future<void> _cerrar(EtapaPrueba etapa) async {
    if (!_etapa.activa) return;
    final sesion = _sesion;
    _etapa = etapa;
    _cerradaEn = sesion != null && etapa == EtapaPrueba.terminada
        ? sesion.inicio.add(sesion.protocolo.total)
        : _reloj();
    // Cancelar suelta el servicio en primer plano y su notificación. No se
    // espera: la etapa ya cambió, así que una ubicación rezagada se ignora.
    unawaited(_suscripcion?.cancel());
    _suscripcion = null;
    notifyListeners();
    if (etapa == EtapaPrueba.terminada && sesion != null) {
      alCambiarDeFase?.call(null, sesion);
    }
    await _vaciar();
  }

  Future<void> _enviarLote(List<EnvioDeMuestra> lote) {
    final sesion = _sesion;
    if (sesion == null) {
      throw StateError('No hay muestras sin una sesión abierta.');
    }
    final enviadaEn = _reloj();
    return _enviar([
      for (final envio in lote)
        envio.muestra.fila(
          sesion,
          intentos: envio.intento,
          enviadaEn: enviadaEn,
        ),
    ]);
  }

  Future<void> _vaciar() async {
    final cola = _cola;
    if (cola == null || cola.enviando || cola.pendientes == 0) return;
    _ultimoIntento = _reloj();
    final fallosAntes = cola.fallos;
    await cola.vaciar();
    if (cola.fallos > fallosAntes) _errorEnvioEn = _reloj();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_desechado) super.notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    _tic?.cancel();
    unawaited(_suscripcion?.cancel());
    super.dispose();
  }
}
