import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../data/canal_dispositivo.dart';
import '../data/fuente_de_ubicacion.dart';
import '../data/fuente_simulada.dart';
import '../data/servicio_de_rutas.dart';
import '../data/spike_rastreo_repository.dart';
import '../domain/estado_en_barra.dart';
import '../domain/geo.dart';
import '../domain/muestra_rastreo.dart';
import '../domain/protocolo_rastreo.dart';
import '../domain/reporte_fase.dart';
import '../domain/reporte_ruta.dart';
import '../domain/ruta_planificada.dart';
import '../domain/seguimiento.dart';
import '../domain/simulador.dart';
import '../domain/traza.dart';
import 'mapa_recorrido.dart';
import 'rastreador_de_prueba.dart';

part 'recorrido_widgets.dart';

/// «Prueba de rastreo» — spike de HU-011, solo en modo debug.
///
/// Responde una pregunta: ¿Cupo sigue mandando la ubicación del conductor a
/// Supabase con la app minimizada y con la pantalla apagada? Tiene dos modos:
///
/// - **Por fases:** tres fases seguidas por reloj (app abierta, minimizada,
///   pantalla apagada), sin salir de casa. Resultado: `spike_reporte()`.
/// - **Recorrido real:** una ruta de verdad en carro (por omisión,
///   [RutaDePrueba.porOmision]), con el teléfono usado como de costumbre. La
///   ruta planificada se traza con OSRM y se dibuja sobre el mapa; al llegar,
///   «Terminar recorrido». Resultado: `spike_reporte_ruta()` y el mapa con la
///   traza, que sirve de figura para la tesis.
///
/// Cada muestra va a `spike_posiciones`. El protocolo y cómo leer el
/// resultado están en `docs/producto/spike-rastreo.md`.
///
/// Se entra desde el inicio del conductor, con un botón que solo existe en
/// las compilaciones de depuración.
class PruebaRastreoScreen extends StatefulWidget {
  const PruebaRastreoScreen({
    super.key,
    this.repositorio,
    this.ubicacion,
    this.canal,
    this.rutas,
  });

  /// Por omisión, los reales. Las pruebas pasan unos falsos.
  final SpikeRastreoRepository? repositorio;
  final FuenteDeUbicacion? ubicacion;
  final CanalDispositivo? canal;
  final ServicioDeRutas? rutas;

  @override
  State<PruebaRastreoScreen> createState() => _PruebaRastreoScreenState();
}

/// A qué pantalla de Ajustes manda el error de arranque.
enum _Ajustes { ubicacion, app }

/// Los tres modos del selector.
enum _Modo { fases, recorrido, simulacion }

/// Una ruta recalculada que todavía no llega a Supabase.
typedef _Recalculo = ({
  DateTime en,
  PuntoGeo desde,
  RutaPlanificada ruta,
  double? desvioM,
});

class _PruebaRastreoScreenState extends State<PruebaRastreoScreen> {
  late final SpikeRastreoRepository _repo =
      widget.repositorio ?? SpikeRastreoRepository();
  late final FuenteDeUbicacion _ubicacion =
      widget.ubicacion ?? const FuenteDeUbicacion();
  late final CanalDispositivo _canal = widget.canal ?? const CanalDispositivo();
  late final ServicioDeRutas _rutas = widget.rutas ?? const ServicioDeRutas();

  late final RastreadorDePrueba _rastreador = RastreadorDePrueba(
    abrirPosiciones: _abrirPosiciones,
    enviar: _repo.insertar,
    estadoTelefono: _canal.estadoAlCapturar,
    alCambiarDeFase: _alCambiarDeFase,
    registrarSesion: _registrarSesion,
  );

  late final AppLifecycleListener _ciclo;

  _Modo _modo = _Modo.fases;
  DuracionPrueba _duracion = DuracionPrueba.estandar;
  bool _wakelock = true;

  bool get _esRecorrido => _modo != _Modo.fases;
  bool get _simular => _modo == _Modo.simulacion;

  // Recorrido real y simulación. La llegada es fija (la URBE); la salida, la
  // ubicación actual (o la de respaldo de [RutaDePrueba.porOmision]).
  RutaDePrueba _ruta = RutaDePrueba.porOmision;
  bool _buscandoPartida = false;
  bool _partidaPedida = false;
  bool _partidaDelGps = false;
  String? _avisoPartida;
  RutaPlanificada? _planificada;
  bool _trazando = false;
  String? _errorRuta;
  PuntoGeo? _domicilio;
  _Toque? _toque;
  int _pedidoDeRuta = 0;
  ReporteRuta? _reporteRuta;
  List<PuntoTraza>? _traza;

  // Simulación.
  double _velocidadKmh = 30;
  int _multiplicador = 5;
  bool _simularCorte = false;
  bool _simularDesvio = false;
  FuenteSimulada? _fuenteSimulada;

  // En vivo: lo que falta, el desvío, el recálculo y la llegada.
  SeguimientoDeRuta? _seguimiento;
  int _ultimaSeqSeguida = 0;
  RutaPlanificada? _rutaVigente;
  bool _recalculando = false;
  int _recalculos = 0;
  String? _avisoRuta;
  bool _llego = false;
  final List<_Recalculo> _recalculosPendientes = [];

  // La notificación en vivo (y, en web, el título de la pestaña).
  DateTime? _inicioReal;
  DateTime? _ultimaPublicacion;
  EtapaPrueba? _etapaPublicada;
  FaseRastreo? _fasePublicada;
  int _seqPublicada = 0;

  InfoDispositivo? _info;
  LocationPermission? _permiso;
  bool? _notificaciones;

  bool _preparando = false;
  String? _errorInicio;
  _Ajustes? _ajustesDelError;

  List<ReporteFase>? _reporte;
  bool _cargandoReporte = false;
  String? _errorReporte;

  @override
  void initState() {
    super.initState();
    _ciclo = AppLifecycleListener(onResume: _alVolver);
    _rastreador.addListener(_seguirUnidad);
    // Después de _seguirUnidad, así ya ve lo que falta actualizado.
    _rastreador.addListener(_publicarEnBarra);
    unawaited(_leerTelefono());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    _rastreador.removeListener(_seguirUnidad);
    _rastreador.removeListener(_publicarEnBarra);
    unawaited(_canal.cerrarEstado());
    _tituloPestana('Cupo');
    _rastreador.dispose();
    unawaited(_canal.mantenerPantallaEncendida(false));
    super.dispose();
  }

  // ───────────────────────────────────────────────────────── acciones ─────

  /// El permiso y la batería pueden haber cambiado en Ajustes.
  Future<void> _leerTelefono() async {
    final info = await _canal.info();
    LocationPermission? permiso;
    try {
      permiso = await _ubicacion.permiso();
    } on Exception {
      // Sin plataforma de ubicación (pruebas, escritorio): se ve «sin
      // permiso todavía» y el arranque lo vuelve a intentar.
    }
    if (!mounted) return;
    setState(() {
      _info = info;
      _permiso = permiso;
    });
  }

  void _alVolver() {
    unawaited(_leerTelefono());
    unawaited(_rastreador.reintentar());
    if (_rastreador.etapa.cerrada && _reporte == null && !_cargandoReporte) {
      unawaited(_cargarReporte());
    }
  }

  Stream<Position> _abrirPosiciones(ConfigPrueba config) {
    final recorrido = config.modo == ModoPrueba.recorrido;
    final simulada = _fuenteSimulada;
    final fuente = config.simulada && simulada != null ? simulada : _ubicacion;
    return fuente.posiciones(
      intervalo: config.intervalo,
      wakelock: config.wakelock,
      tituloAviso: recorrido
          ? 'Cupo · Recorrido real en curso'
          : 'Cupo · Prueba de rastreo',
      textoAviso: recorrido
          ? 'Al llegar y estacionar, abre Cupo y toca «Terminar recorrido».'
          : 'Midiendo si tu ubicación llega a Cupo. Sigue los avisos de '
                'cada fase.',
      acento: AppColors.primary,
    );
  }

  /// Guarda el plan del recorrido en `spike_recorridos`. En el modo por
  /// fases no hay plan.
  Future<void> _registrarSesion(SesionRastreo sesion) async {
    if (sesion.modo != ModoPrueba.recorrido) return;
    await _repo.registrarRecorrido(
      sesionId: sesion.id,
      ruta: _ruta,
      idaYVuelta: false,
      planificada: _planificada,
      domicilio: _domicilio,
      simulada: sesion.simulada,
    );
  }

  void _elegirModo(_Modo modo) {
    setState(() => _modo = modo);
    switch (modo) {
      case _Modo.fases:
        return;
      // El recorrido real sale de donde está el teléfono.
      case _Modo.recorrido when !_partidaDelGps && !_buscandoPartida:
        unawaited(_buscarPartida());
      case _Modo.recorrido:
        return;
      // La simulación no necesita el GPS ni su permiso: sale de la salida de
      // respaldo (o de la que ya había). «Salir desde mi ubicación actual»
      // la cambia.
      case _Modo.simulacion when !_partidaPedida:
        setState(() => _partidaPedida = true);
        unawaited(_trazarRuta());
      case _Modo.simulacion:
        return;
    }
  }

  /// La salida del recorrido es donde está el teléfono. Mientras se busca, el
  /// mapa se queda en la URBE; si no se puede (sin permiso, sin GPS, sin
  /// señal), se usa la salida de respaldo y se avisa.
  Future<void> _buscarPartida() async {
    setState(() {
      _partidaPedida = true;
      _buscandoPartida = true;
      _avisoPartida = null;
    });
    try {
      final aqui = await _ubicacion.posicionActual();
      if (!mounted) return;
      setState(() {
        _ruta = _ruta.copyWith(inicio: PuntoGeo(aqui.latitude, aqui.longitude));
        _partidaDelGps = true;
      });
    } catch (e) {
      // Cualquier falla (permiso, servicio, señal, plataforma) lleva al
      // respaldo: la prueba se puede hacer igual.
      if (!mounted) return;
      setState(() {
        _ruta = _ruta.copyWith(inicio: RutaDePrueba.porOmision.inicio);
        _partidaDelGps = false;
        _avisoPartida =
            'No se pudo leer tu ubicación: se usa la salida de respaldo '
            '(Av. 61). Toca «Salida» y luego el mapa para elegir otra.';
      });
    } finally {
      if (mounted) setState(() => _buscandoPartida = false);
    }
    if (mounted) unawaited(_trazarRuta());
  }

  /// Sigue a la unidad con cada muestra nueva: lo que falta, el desvío, el
  /// recálculo y la llegada. Corre antes que el `ListenableBuilder`, así la
  /// vista ya ve los valores nuevos.
  void _seguirUnidad() {
    final r = _rastreador;
    final ultima = r.ultima;
    final seguimiento = _seguimiento;
    if (!r.esRecorrido ||
        !r.etapa.activa ||
        ultima == null ||
        seguimiento == null ||
        ultima.seq == _ultimaSeqSeguida) {
      return;
    }
    _ultimaSeqSeguida = ultima.seq;
    final aqui = PuntoGeo(ultima.lat, ultima.lng);
    final evento = seguimiento.actualizar(aqui, ultima.capturadaEn);
    if (evento.acabaDeLlegar) _avisarLlegada();
    if (evento.recalcular && _planificada != null && !_recalculando) {
      unawaited(_recalcular(aqui, ultima.capturadaEn, seguimiento.desvioM));
    }
  }

  /// Publica la notificación en vivo: en cada hito (arranque, primera
  /// muestra, cambio de fase o de etapa) y, si no, como mucho una vez cada
  /// 5 s. El tic de un segundo del rastreador la despierta aunque no lleguen
  /// muestras, y así aparece «Sin ubicación hace 45 s».
  void _publicarEnBarra() {
    final r = _rastreador;
    if (r.etapa.cerrada && (_etapaPublicada?.activa ?? false)) {
      // La prueba terminó: se quita la en vivo y, con el reporte, queda el
      // resumen (ver _publicarResumen).
      _etapaPublicada = r.etapa;
      unawaited(_canal.cerrarEstado());
      return;
    }
    if (!r.etapa.activa) return;

    final ahora = DateTime.now();
    final seq = r.ultima?.seq ?? 0;
    final hito =
        r.etapa != _etapaPublicada ||
        r.fase != _fasePublicada ||
        (_seqPublicada == 0 && seq > 0);
    final ultima = _ultimaPublicacion;
    if (!hito &&
        ultima != null &&
        ahora.difference(ultima) < const Duration(seconds: 5)) {
      return;
    }
    _ultimaPublicacion = ahora;
    _etapaPublicada = r.etapa;
    _fasePublicada = r.fase;
    _seqPublicada = seq;

    final config = r.config;
    final sesion = r.sesion;
    final modo = config?.modo ?? ModoPrueba.fases;
    final estado = estadoEnBarra(
      modo: modo,
      simulada: config?.simulada ?? false,
      buscandoGps: r.etapa == EtapaPrueba.buscandoGps,
      enviadas: r.enviadas,
      pendientes: r.pendientes,
      sinRed: r.sinRed,
      fase: r.fase,
      desdeUltima: r.desdeUltima,
      restanteM: _seguimiento?.restanteM,
      recorridoM: r.distanciaM,
      avanceFases: sesion != null && modo == ModoPrueba.fases
          ? r.transcurrido.inMilliseconds /
                sesion.protocolo.total.inMilliseconds
          : null,
    );
    unawaited(
      _canal.mostrarEstado(
        titulo: estado.titulo,
        texto: estado.texto,
        inicio: _inicioReal,
        progreso: estado.progreso,
        maximo: EstadoEnBarra.maximo,
        acento: AppColors.primary,
      ),
    );
    _tituloPestana('${estado.corto} · Cupo');
  }

  /// El resumen que queda en la barra al terminar, descartable.
  void _publicarResumen() {
    final r = _rastreador;
    final sesion = r.sesion;
    if (!r.etapa.cerrada || sesion == null) return;
    final EstadoEnBarra resumen;
    if (sesion.modo == ModoPrueba.recorrido) {
      final reporte = _reporteRuta;
      resumen = resumenEnBarra(
        simulada: sesion.simulada,
        coberturaPct: reporte?.coberturaPct,
        pasa: reporte?.cumple,
      );
    } else {
      final fases = _reporte;
      final coberturas = [
        for (final f in fases ?? const <ReporteFase>[]) ?f.coberturaPct,
      ];
      resumen = resumenEnBarra(
        simulada: false,
        coberturaPct: coberturas.isEmpty
            ? null
            : coberturas.reduce((a, b) => a < b ? a : b),
        pasa: fases == null ? null : veredictoRastreo(fases),
      );
    }
    unawaited(
      _canal.mostrarEstado(
        titulo: resumen.titulo,
        texto: resumen.texto,
        fijo: false,
        acento: AppColors.primary,
      ),
    );
    _tituloPestana('${resumen.corto} · Cupo');
  }

  /// En web no hay barra de notificaciones: el estado va en el título de la
  /// pestaña. Flutter web traduce esto a `document.title`, sin importar nada
  /// de la plataforma; en Android no se llama.
  void _tituloPestana(String texto) {
    if (!kIsWeb) return;
    unawaited(
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
          label: texto,
          primaryColor: AppColors.primary.toARGB32(),
        ),
      ),
    );
  }

  /// La unidad se salió de la ruta: una nueva desde donde está hasta la
  /// URBE. La regla de [SeguimientoDeRuta] ya limita la frecuencia.
  Future<void> _recalcular(PuntoGeo desde, DateTime en, double? desvio) async {
    _recalculando = true;
    try {
      final ruta = await _rutas.trazar([desde, _ruta.llegada]);
      if (!mounted) return;
      _seguimiento?.cambiarRuta(ruta.puntos);
      _recalculosPendientes.add((
        en: en,
        desde: desde,
        ruta: ruta,
        desvioM: desvio,
      ));
      setState(() {
        _rutaVigente = ruta;
        _recalculos++;
        _avisoRuta =
            'Ruta recalculada ($_recalculos) a las ${horaCorta(en)}: te saliste '
            '${_distancia(desvio)} de la ruta.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ruta recalculada',
            style: AppTypography.meta.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
      unawaited(_guardarRecalculos());
    } on RutaFallo catch (e) {
      if (mounted) {
        setState(
          () => _avisoRuta =
              'Te saliste de la ruta y no se pudo recalcular: ${e.mensaje}',
        );
      }
    } finally {
      _recalculando = false;
    }
  }

  /// Manda a Supabase las rutas recalculadas que falten. Sin red, se quedan
  /// para el próximo intento (el siguiente recálculo o el reporte).
  Future<void> _guardarRecalculos() async {
    final sesion = _rastreador.sesion;
    if (sesion == null) return;
    for (final r in List.of(_recalculosPendientes)) {
      try {
        await _repo.registrarRutaRecalculada(
          sesionId: sesion.id,
          calculadaEn: r.en,
          desde: r.desde,
          ruta: r.ruta,
          desvioM: r.desvioM,
          simulada: sesion.simulada,
        );
        _recalculosPendientes.remove(r);
      } on SpikeRastreoFallo {
        return;
      }
    }
  }

  void _avisarLlegada() {
    setState(() => _llego = true);
    unawaited(HapticFeedback.vibrate());
    // En la simulación termina sola; en el real termina la persona.
    if (!_simular) {
      unawaited(
        _canal.avisar(
          titulo: 'Llegaste a la URBE',
          texto: 'Cuando estaciones, abre Cupo y toca «Terminar recorrido».',
        ),
      );
    }
  }

  /// Pide a OSRM la ruta por las calles. Si falla, el recorrido se hace
  /// igual, sin ruta planificada.
  Future<void> _trazarRuta() async {
    final pedido = ++_pedidoDeRuta;
    setState(() {
      _trazando = true;
      _errorRuta = null;
    });
    try {
      final ruta = await _rutas.trazar(_ruta.paradas());
      // Si mientras tanto se pidió otra (se movió un punto), esta sobra.
      if (!mounted || pedido != _pedidoDeRuta) return;
      setState(() => _planificada = ruta);
    } on RutaFallo catch (e) {
      if (!mounted || pedido != _pedidoDeRuta) return;
      setState(() {
        _planificada = null;
        _errorRuta = e.mensaje;
      });
    } finally {
      if (mounted && pedido == _pedidoDeRuta) {
        setState(() => _trazando = false);
      }
    }
  }

  void _tocarMapa(PuntoGeo punto) {
    switch (_toque) {
      case _Toque.inicio:
        setState(() {
          _ruta = _ruta.copyWith(inicio: punto);
          // Elegida a mano: el recorrido real no la vuelve a pisar con el GPS.
          _partidaDelGps = true;
          _avisoPartida = null;
        });
        unawaited(_trazarRuta());
      case _Toque.domicilio:
        setState(() => _domicilio = punto);
      case null:
        return;
    }
  }

  Future<void> _terminarRecorrido() async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Ya estacionaste?', style: AppTypography.titleMedium),
        content: Text(
          'Termina el recorrido solo con el carro detenido. Lo que pase '
          'después ya no se mide.',
          style: AppTypography.meta,
        ),
        actions: [
          CupoLink(
            label: 'Todavía no',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: AppSpacing.md),
          CupoLink(
            label: 'Terminar',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (respuesta != true || !mounted) return;
    await _rastreador.terminarRecorrido();
  }

  Future<void> _copiarGeojson() async {
    final sesion = _rastreador.sesion;
    if (sesion == null) return;
    final mensajero = ScaffoldMessenger.of(context);
    String mensaje;
    try {
      final texto = await _repo.geojson(sesion.id);
      await Clipboard.setData(ClipboardData(text: texto));
      mensaje = 'GeoJSON copiado: pégalo en geojson.io o en QGIS.';
    } on SpikeRastreoFallo catch (e) {
      mensaje = e.mensaje;
    }
    mensajero.showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: AppTypography.meta.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
  }

  void _verMapa() {
    final traza = _traza;
    final reporte = _reporteRuta;
    if (traza == null) return;
    final dispositivo = _rastreador.sesion?.dispositivo;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MapaRecorridoScreen(
            titulo:
                '${_rastreador.sesion?.simulada == true ? 'Simulación (no es evidencia)' : 'Recorrido real'} · ${_ruta.nombre}',
            subtitulo: [
              if (reporte != null) _fechaCorta(reporte.inicio.toLocal()),
              ?dispositivo,
              if (reporte != null)
                'cobertura ${_decimal(reporte.coberturaPct)} %',
            ].join(' · '),
            conRuta: _planificada != null,
            conDomicilio: _domicilio != null,
            mapa: mapaDelResultado(
              traza: traza,
              planificada: _planificada,
              ruta: _ruta,
              domicilio: _domicilio,
            ),
          ),
        ),
      ),
    );
  }

  static String _fechaCorta(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
      '${horaCorta(fecha)}';

  Future<void> _empezar() async {
    setState(() {
      _preparando = true;
      _errorInicio = null;
      _ajustesDelError = null;
      _reporte = null;
      _reporteRuta = null;
      _traza = null;
      _errorReporte = null;
      _toque = null;
      _seguimiento = null;
      _ultimaSeqSeguida = 0;
      _rutaVigente = null;
      _recalculos = 0;
      _avisoRuta = null;
      _llego = false;
      _recalculosPendientes.clear();
      _inicioReal = DateTime.now();
      _ultimaPublicacion = null;
      _etapaPublicada = null;
      _fasePublicada = null;
      _seqPublicada = 0;
    });

    if (_esRecorrido) {
      _seguimiento = SeguimientoDeRuta(
        ruta: _planificada?.puntos ?? const [],
        destino: _ruta.llegada,
      );
    }

    if (_simular) {
      await _empezarSimulacion();
      return;
    }

    try {
      if (!await _ubicacion.servicioActivo()) {
        _fallarInicio(
          'La ubicación del teléfono está apagada. Actívala y vuelve a '
          'intentar.',
          _Ajustes.ubicacion,
        );
        return;
      }

      var permiso = await _ubicacion.permiso();
      if (permiso == LocationPermission.denied) {
        permiso = await _ubicacion.pedirPermiso();
      }
      final PermisoRastreo nivel;
      switch (permiso) {
        case LocationPermission.always:
          nivel = PermisoRastreo.siempre;
        case LocationPermission.whileInUse:
          nivel = PermisoRastreo.mientrasSeUsa;
        case LocationPermission.deniedForever:
          _fallarInicio(
            'Cupo tiene la ubicación bloqueada. Actívala en Ajustes › '
            'Permisos › Ubicación.',
            _Ajustes.app,
          );
          return;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          _fallarInicio(
            'Sin permiso de ubicación no hay nada que medir. Toca «Empezar '
            'prueba» otra vez y elige «Mientras se usa la app».',
          );
          return;
      }

      // Sin este permiso el servicio corre igual, pero no se ven ni su
      // notificación fija ni los avisos de cambio de fase.
      final notificaciones = await _canal.pedirNotificaciones();
      final info = await _canal.info();
      if (!mounted) return;
      setState(() {
        _permiso = permiso;
        _notificaciones = notificaciones;
        _info = info ?? _info;
      });

      // Sin esto, la pantalla se apagaría sola a mitad de la fase 1. En el
      // recorrido no: el conductor usa el teléfono como siempre.
      if (_modo == _Modo.fases) {
        await _canal.mantenerPantallaEncendida(true);
      }
      _rastreador.iniciar(
        ConfigPrueba(
          modo: _esRecorrido ? ModoPrueba.recorrido : ModoPrueba.fases,
          duracion: _duracion,
          wakelock: _wakelock,
          permiso: nivel,
          bateriaSinRestriccion: _info?.bateriaSinRestriccion,
          dispositivo: _info?.descripcion,
        ),
      );
    } on Exception catch (e) {
      _fallarInicio('No se pudo arrancar el GPS: $e');
    } finally {
      if (mounted) setState(() => _preparando = false);
    }
  }

  /// La simulación no usa el GPS: no pide permisos ni levanta el servicio.
  /// Recorre la ruta de OSRM (o, si no hubo, la recta de la salida a la URBE)
  /// con el reloj simulado, y al llegar termina sola.
  Future<void> _empezarSimulacion() async {
    try {
      final info = await _canal.info();
      final linea = _planificada?.puntos ?? _ruta.paradas();
      final fuente = FuenteSimulada(
        simulador: SimuladorDeRecorrido(
          linea: linea,
          velocidadKmh: _velocidadKmh,
          corte: _simularCorte,
          desvio: _simularDesvio,
        ),
        multiplicador: _multiplicador,
      );
      fuente.alLlegar = () => unawaited(_rastreador.terminarRecorrido());
      _fuenteSimulada = fuente;
      if (!mounted) return;
      setState(() => _info = info ?? _info);
      _rastreador.iniciar(
        ConfigPrueba(
          modo: ModoPrueba.recorrido,
          simulada: true,
          wakelock: false,
          permiso: PermisoRastreo.noAplica,
          reloj: fuente.reloj.ahora,
          bateriaSinRestriccion: info?.bateriaSinRestriccion,
          dispositivo:
              info?.descripcion ??
              (kIsWeb ? 'Navegador (simulación)' : 'Simulación'),
        ),
      );
    } finally {
      if (mounted) setState(() => _preparando = false);
    }
  }

  void _fallarInicio(String mensaje, [_Ajustes? ajustes]) {
    if (!mounted) return;
    setState(() {
      _errorInicio = mensaje;
      _ajustesDelError = ajustes;
    });
  }

  void _alCambiarDeFase(FaseRastreo? fase, SesionRastreo sesion) {
    if (sesion.modo == ModoPrueba.recorrido) {
      // El recorrido lo termina la persona, con la app a la vista.
      if (fase == null) unawaited(_cargarReporte());
      return;
    }
    unawaited(HapticFeedback.vibrate());

    String finDe(FaseRastreo f) =>
        horaCorta(sesion.inicio.add(sesion.protocolo.finDe(f)));
    final aviso = switch (fase) {
      // La persona está mirando la pantalla: basta con la vibración.
      FaseRastreo.primerPlano => null,
      FaseRastreo.minimizada => (
        'Fase 2 de 3: minimiza Cupo',
        'Toca Inicio y usa el teléfono normal, con la pantalla encendida, '
            'hasta las ${finDe(FaseRastreo.minimizada)}.',
      ),
      FaseRastreo.pantallaApagada => (
        'Fase 3 de 3: apaga la pantalla',
        'Bloquea el teléfono con el botón de encendido y no lo toques hasta '
            'las ${finDe(FaseRastreo.pantallaApagada)}.',
      ),
      null => (
        'Prueba de rastreo terminada',
        'Desbloquea el teléfono y abre Cupo para ver el resultado.',
      ),
    };
    if (aviso != null) {
      unawaited(_canal.avisar(titulo: aviso.$1, texto: aviso.$2));
    }

    if (fase == null) {
      unawaited(_canal.mantenerPantallaEncendida(false));
      unawaited(_cargarReporte());
    }
  }

  Future<void> _detener() async {
    final seguro = await _confirmarDetener();
    if (!seguro || !mounted) return;
    await _rastreador.detener();
    unawaited(_canal.mantenerPantallaEncendida(false));
    unawaited(_cargarReporte());
  }

  Future<bool> _confirmarDetener() async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Detener la prueba?', style: AppTypography.titleMedium),
        content: Text(
          'Lo que falta de la prueba contará como hueco en el resultado.',
          style: AppTypography.meta,
        ),
        actions: [
          CupoLink(
            label: 'Seguir midiendo',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: AppSpacing.md),
          CupoLink(
            label: 'Detener',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }

  Future<void> _salirDuranteLaPrueba() async {
    final navegador = Navigator.of(context);
    final seguro = await _confirmarDetener();
    if (!seguro || !mounted) return;
    await _rastreador.detener();
    if (mounted) navegador.pop();
  }

  Future<void> _cargarReporte() async {
    final sesion = _rastreador.sesion;
    if (sesion == null || !mounted) return;
    setState(() {
      _cargandoReporte = true;
      _errorReporte = null;
    });
    try {
      if (sesion.modo == ModoPrueba.recorrido) {
        await _guardarRecalculos();
        final reporte = await _repo.reporteRuta(sesion.id);
        final traza = await _repo.traza(sesion.id);
        if (mounted) {
          setState(() {
            _reporteRuta = reporte;
            _traza = traza;
          });
        }
      } else {
        final reporte = await _repo.reporte(sesion.id);
        if (mounted) setState(() => _reporte = reporte);
      }
    } on SpikeRastreoFallo catch (e) {
      if (mounted) setState(() => _errorReporte = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargandoReporte = false);
    }
    if (mounted) _publicarResumen();
  }

  void _nuevaPrueba() {
    _rastreador.reiniciar();
    setState(() {
      _reporte = null;
      _reporteRuta = null;
      _traza = null;
      _errorReporte = null;
      _notificaciones = null;
    });
  }

  Future<void> _copiarSesion(String id) async {
    final mensajero = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: id));
    mensajero.showSnackBar(
      SnackBar(
        content: Text(
          'Sesión copiada',
          style: AppTypography.meta.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
  }

  Future<void> _abrirAjustesDelError() async {
    switch (_ajustesDelError) {
      case _Ajustes.ubicacion:
        await _ubicacion.abrirAjustesUbicacion();
      case _Ajustes.app:
        await _ubicacion.abrirAjustesApp();
      case null:
        return;
    }
  }

  /// Segundo paso del permiso: «Permitir todo el tiempo».
  Future<void> _pedirSegundoPlano() async {
    try {
      final permiso = await _ubicacion.pedirPermiso();
      if (mounted) setState(() => _permiso = permiso);
    } on Exception {
      await _ubicacion.abrirAjustesApp();
    }
  }

  // ─────────────────────────────────────────────────────────── vista ──────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _rastreador,
      builder: (context, _) {
        final r = _rastreador;

        return PopScope(
          canPop: !r.etapa.activa,
          onPopInvokedWithResult: (salio, _) {
            if (!salio) unawaited(_salirDuranteLaPrueba());
          },
          child: CupoScreen(
            leading: const CupoBackButton(),
            footer: _pie(r),
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Prueba de rastreo', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text(switch (_modo) {
                _Modo.fases =>
                  '¿Cupo sigue enviando tu ubicación con la app '
                      'minimizada y con la pantalla apagada? Son tres fases '
                      'seguidas y la app te avisa cuándo cambiar.',
                _Modo.recorrido =>
                  '¿Cupo sigue enviando tu ubicación durante una ruta de '
                      'verdad, desde donde estás hasta la URBE, con el '
                      'teléfono usado como siempre?',
                _Modo.simulacion =>
                  'La unidad recorre la ruta hasta la URBE sin GPS, para '
                      'ver cómo se mueve en el mapa y probar el envío y el '
                      'reporte. Nunca cuenta como evidencia.',
              }, style: AppTypography.body),
              const SizedBox(height: AppSpacing.xl),
              ...switch (r.etapa) {
                EtapaPrueba.lista => _configuracion(),
                EtapaPrueba.buscandoGps => _buscandoGps(r),
                EtapaPrueba.enCurso =>
                  r.esRecorrido ? _enCursoRecorrido(r) : _enCurso(r),
                EtapaPrueba.terminada || EtapaPrueba.detenida =>
                  r.esRecorrido ? _resultadoRecorrido(r) : _resultado(r),
              },
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _pie(RastreadorDePrueba r) {
    return switch (r.etapa) {
      EtapaPrueba.lista => CupoPrimaryButton(
        label: switch (_modo) {
          _Modo.fases => 'Empezar prueba',
          _Modo.recorrido => 'Empezar recorrido',
          _Modo.simulacion => 'Empezar simulación',
        },
        isLoading: _preparando,
        onPressed: _preparando ? null : _empezar,
      ),
      EtapaPrueba.enCurso when r.esRecorrido && r.config?.simulada == true =>
        CupoPrimaryButton(
          label: 'Terminar simulación',
          onPressed: _rastreador.terminarRecorrido,
        ),
      EtapaPrueba.enCurso when r.esRecorrido => CupoPrimaryButton(
        label: 'Terminar recorrido',
        onPressed: _terminarRecorrido,
      ),
      EtapaPrueba.buscandoGps || EtapaPrueba.enCurso => CupoSecondaryButton(
        label: 'Detener prueba',
        onPressed: _detener,
      ),
      EtapaPrueba.terminada || EtapaPrueba.detenida => CupoPrimaryButton(
        label: r.pendientes > 0 ? 'Enviando lo pendiente…' : 'Nueva prueba',
        onPressed: r.pendientes > 0 ? null : _nuevaPrueba,
      ),
    };
  }

  List<Widget> _configuracion() {
    final errorInicio = _errorInicio;

    final recorrido = _esRecorrido;

    return [
      Text('Qué medir', style: AppTypography.label),
      const SizedBox(height: AppSpacing.xs),
      for (final (modo, icono, titulo, descripcion) in const [
        (
          _Modo.fases,
          LucideIcons.timer,
          'Prueba por fases',
          '30 min en tres fases, sin salir de casa.',
        ),
        (
          _Modo.recorrido,
          LucideIcons.car,
          'Recorrido real',
          'Desde donde estás hasta la URBE, en carro.',
        ),
        (
          _Modo.simulacion,
          LucideIcons.play,
          'Simular recorrido',
          'La unidad se mueve sola por la ruta. Sin GPS; no es evidencia.',
        ),
      ]) ...[
        CupoCheckTile(
          icono: icono,
          titulo: titulo,
          descripcion: descripcion,
          seleccionado: _modo == modo,
          onPressed: () => _elegirModo(modo),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
      const SizedBox(height: AppSpacing.md),
      if (recorrido) ...[
        _PanelPlan(
          ruta: _ruta,
          planificada: _planificada,
          trazando: _trazando,
          errorRuta: _errorRuta,
          buscandoPartida: _buscandoPartida,
          avisoPartida: _avisoPartida,
          domicilio: _domicilio,
          toque: _toque,
          onToque: (t) => setState(() => _toque = t),
          onTapMapa: _tocarMapa,
          onReintentar: _trazarRuta,
          onUsarMiUbicacion: _buscarPartida,
          onQuitarDomicilio: () => setState(() => _domicilio = null),
        ),
        if (_simular) ...[
          const SizedBox(height: AppSpacing.md),
          _PanelSimulacion(
            velocidadKmh: _velocidadKmh,
            multiplicador: _multiplicador,
            corte: _simularCorte,
            desvio: _simularDesvio,
            onVelocidad: (v) => setState(() => _velocidadKmh = v),
            onMultiplicador: (m) => setState(() => _multiplicador = m),
            onCorte: () => setState(() => _simularCorte = !_simularCorte),
            onDesvio: () => setState(() => _simularDesvio = !_simularDesvio),
          ),
        ],
      ] else ...[
        Text('Duración de cada fase', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        for (final opcion in DuracionPrueba.values) ...[
          CupoCheckTile(
            icono: switch (opcion) {
              DuracionPrueba.corta => LucideIcons.zap,
              DuracionPrueba.estandar => LucideIcons.timer,
              DuracionPrueba.larga => LucideIcons.hourglass,
            },
            titulo: '${opcion.porFase.inMinutes} minutos por fase',
            descripcion: switch (opcion) {
              DuracionPrueba.corta =>
                'Ensayo de 6 minutos para ver que todo funciona. No cuenta '
                    'como evidencia.',
              DuracionPrueba.estandar =>
                '30 minutos en total. Es la prueba que cuenta.',
              DuracionPrueba.larga => 'Una hora: le da tiempo a Android de entrar en reposo profundo.',
            },
            seleccionado: _duracion == opcion,
            onPressed: () => setState(() => _duracion = opcion),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
      if (!_simular) ...[
        const SizedBox(height: AppSpacing.md),
        Text('Servicio de ubicación', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        CupoCheckTile(
          icono: LucideIcons.cpu,
          titulo: 'Mantener el procesador despierto',
          descripcion: 'Wake lock del servicio. Recomendado; quítalo solo para comparar.',
          seleccionado: _wakelock,
          onPressed: () => setState(() => _wakelock = !_wakelock),
        ),
        const SizedBox(height: AppSpacing.xl),
        _EstadoTelefono(
          info: _info,
          permiso: _permiso,
          onSegundoPlano: _pedirSegundoPlano,
          onBateria: _canal.abrirAjustesBateria,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      if (recorrido && !_simular) ...[
        const _Aviso(
          texto:
              'Por seguridad: configura todo y toca «Empezar recorrido» '
              'antes de arrancar. Manejando no toques el teléfono; solo un '
              'acompañante, o tú con el carro estacionado.',
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (!_simular)
        CupoInfoBanner(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Antes de empezar', style: AppTypography.metaStrong),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                recorrido
                    ? '1. Batería cargada. Para medir lo peor, sin cargador; '
                          'con el cargador del carro también vale, y queda '
                          'registrado.\n'
                          '2. Primera mitad con Cupo minimizada (WhatsApp o '
                          'Waze abiertos); segunda mitad con la pantalla '
                          'bloqueada.\n'
                          '3. Datos móviles encendidos.'
                    : '1. Desconecta el cargador: cargando, Android no ahorra '
                          'batería y la prueba no dice nada.\n'
                          '2. Sube el tiempo de espera de la pantalla al máximo, '
                          'para que no se apague sola en la fase 2.\n'
                          '3. Deja los datos móviles o el wifi encendidos.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      if (errorInicio != null) ...[
        const SizedBox(height: AppSpacing.md),
        CupoErrorBanner(mensaje: errorInicio),
        if (_ajustesDelError != null)
          CupoLink(label: 'Abrir Ajustes', onPressed: _abrirAjustesDelError),
      ],
    ];
  }

  List<Widget> _buscandoGps(RastreadorDePrueba r) {
    final tarda = r.buscando > const Duration(minutes: 1);

    return [
      _Tarjeta(
        fondo: AppColors.primarySoft,
        icono: LucideIcons.satelliteDish,
        etiqueta: 'PREPARANDO',
        titulo: 'Buscando señal GPS…',
        texto: tarda
            ? 'Está tardando. Acércate a una ventana o sal al aire libre.'
            : 'La prueba arranca con la primera ubicación. Deja Cupo abierta.',
        pie: 'Buscando desde hace ${formatoCronometro(r.buscando)}',
      ),
      ..._avisoNotificaciones(),
      ..._errores(r),
    ];
  }

  List<Widget> _enCurso(RastreadorDePrueba r) {
    final sesion = r.sesion;
    final fase = r.fase;
    if (sesion == null || fase == null) return const [];
    final cambio = sesion.inicio.add(sesion.protocolo.finDe(fase));
    final ultima = fase == FaseRastreo.pantallaApagada;

    return [
      _Tarjeta(
        fondo: AppColors.primarySoft,
        icono: _iconoDe(fase),
        etiqueta: 'FASE ${fase.numero} DE 3',
        titulo: _tituloDe(fase),
        texto: _instruccionDe(fase),
        pie:
            'Quedan ${formatoCronometro(r.restanteEnFase)} · '
            '${ultima ? 'termina' : 'cambia'} a las ${horaCorta(cambio)}',
      ),
      ..._avisoNotificaciones(),
      const SizedBox(height: AppSpacing.md),
      _Contadores(rastreador: r),
      ..._errores(r),
      const SizedBox(height: AppSpacing.xl),
      _Cronograma(sesion: sesion, actual: fase),
      const SizedBox(height: AppSpacing.xl),
      _Sesion(id: sesion.id, onCopiar: () => _copiarSesion(sesion.id)),
    ];
  }

  List<Widget> _resultado(RastreadorDePrueba r) {
    final sesion = r.sesion;
    final reporte = _reporte;
    final errorReporte = _errorReporte;

    if (sesion == null) {
      // Se detuvo antes de la primera ubicación: no hay nada que reportar.
      return [
        const _Tarjeta(
          fondo: AppColors.backgroundAlt,
          icono: LucideIcons.circleSlash,
          etiqueta: 'SIN DATOS',
          titulo: 'La prueba no llegó a empezar',
          texto: 'Se detuvo antes de la primera ubicación.',
        ),
        ..._errores(r),
      ];
    }

    return [
      if (reporte != null)
        _Veredicto(reporte: reporte, detenida: r.etapa == EtapaPrueba.detenida)
      else if (errorReporte != null)
        CupoErrorBanner(mensaje: errorReporte)
      else
        const _Tarjeta(
          fondo: AppColors.backgroundAlt,
          icono: LucideIcons.chartColumn,
          etiqueta: 'RESULTADO',
          titulo: 'Calculando…',
          texto: 'Leyendo el reporte de la sesión en Supabase.',
        ),
      if (reporte != null) ...[
        const SizedBox(height: AppSpacing.md),
        for (final fase in reporte) ...[
          _FilaReporte(fase: fase),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
      Align(
        alignment: Alignment.centerLeft,
        child: CupoLink(
          label: _cargandoReporte ? 'Actualizando…' : 'Actualizar resultado',
          onPressed: _cargandoReporte ? null : _cargarReporte,
        ),
      ),
      if (r.pendientes > 0) ...[
        const SizedBox(height: AppSpacing.xs),
        _Aviso(
          texto:
              'Faltan ${r.pendientes} muestras por llegar a Supabase; se '
              'reintentan solas. Actualiza el resultado cuando lleguen.',
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      _Contadores(rastreador: r),
      ..._errores(r),
      const SizedBox(height: AppSpacing.xl),
      _Sesion(id: sesion.id, onCopiar: () => _copiarSesion(sesion.id)),
    ];
  }

  List<Widget> _enCursoRecorrido(RastreadorDePrueba r) {
    final sesion = r.sesion;
    if (sesion == null) return const [];
    final ultima = r.ultima;
    final simulada = sesion.simulada;
    final seguimiento = _seguimiento;
    final avisoRuta = _avisoRuta;
    final fuente = _fuenteSimulada;
    final velocidad = ultima?.velocidadMs;

    return [
      _Tarjeta(
        fondo: AppColors.primarySoft,
        icono: simulada ? LucideIcons.play : LucideIcons.car,
        etiqueta: simulada
            ? 'SIMULACIÓN · NO ES EVIDENCIA'
            : 'RECORRIDO REAL · EN CURSO',
        titulo: simulada ? 'La unidad va sola' : 'Maneja normal',
        texto: simulada
            ? 'Recorre la ruta a ${_velocidadKmh.round()} km/h, '
                  '×${fuente?.multiplicador ?? _multiplicador} más rápido '
                  'que el tiempo real. Termina sola al llegar a la URBE.'
            : 'Minimiza Cupo, usa Waze o WhatsApp, o bloquea el teléfono. Al '
                  'llegar y estacionar, abre Cupo y toca «Terminar '
                  'recorrido».',
      ),
      const SizedBox(height: AppSpacing.md),
      _PanelEnVivo(
        restanteM: seguimiento?.restanteM,
        recorridoM: r.distanciaM,
        transcurrido: r.transcurrido,
        velocidadKmh: velocidad == null ? null : velocidad * 3.6,
      ),
      if (_llego) ...[
        const SizedBox(height: AppSpacing.md),
        _Tarjeta(
          fondo: AppColors.successSoft,
          icono: LucideIcons.flag,
          etiqueta: 'LLEGADA',
          titulo: 'Llegaste a la URBE',
          texto: simulada
              ? 'La simulación termina sola.'
              : 'Estaciona y, con el carro detenido, toca «Terminar '
                    'recorrido».',
        ),
      ],
      if (avisoRuta != null) ...[
        const SizedBox(height: AppSpacing.md),
        CupoInfoBanner(child: Text(avisoRuta, style: AppTypography.bodySmall)),
      ],
      if (!simulada) ...[
        const SizedBox(height: AppSpacing.md),
        const _Aviso(texto: 'No toques el teléfono mientras manejas.'),
      ],
      const SizedBox(height: AppSpacing.md),
      ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: SizedBox(
          height: _altoMapa,
          child: MapaRecorrido(
            rutaPlanificada: (_rutaVigente ?? _planificada)?.puntos,
            trazaEnVivo: r.recorridoLocal,
            inicio: _ruta.inicio,
            llegada: _ruta.llegada,
            domicilio: _domicilio,
            radioAvisoM: _domicilio == null ? null : CriterioRuta.radioAvisoM,
            unidad: ultima == null ? null : PuntoGeo(ultima.lat, ultima.lng),
            rumboUnidad: ultima?.rumboDeg,
            seguirUnidad: true,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _Contadores(rastreador: r),
      ..._errores(r),
      const SizedBox(height: AppSpacing.xl),
      _Sesion(id: sesion.id, onCopiar: () => _copiarSesion(sesion.id)),
    ];
  }

  List<Widget> _resultadoRecorrido(RastreadorDePrueba r) {
    final sesion = r.sesion;
    final reporte = _reporteRuta;
    final errorReporte = _errorReporte;

    if (sesion == null) {
      return [
        const _Tarjeta(
          fondo: AppColors.backgroundAlt,
          icono: LucideIcons.circleSlash,
          etiqueta: 'SIN DATOS',
          titulo: 'El recorrido no llegó a empezar',
          texto: 'Se detuvo antes de la primera ubicación.',
        ),
        ..._errores(r),
      ];
    }

    return [
      if (reporte != null)
        _ResultadoRecorrido(
          reporte: reporte,
          traza: _traza,
          planificada: _planificada,
          ruta: _ruta,
          domicilio: _domicilio,
          onVerMapa: _verMapa,
          onCopiarGeojson: _copiarGeojson,
        )
      else if (errorReporte != null)
        CupoErrorBanner(mensaje: errorReporte)
      else
        const _Tarjeta(
          fondo: AppColors.backgroundAlt,
          icono: LucideIcons.chartColumn,
          etiqueta: 'RESULTADO',
          titulo: 'Calculando…',
          texto: 'Leyendo el recorrido en Supabase.',
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: CupoLink(
          label: _cargandoReporte ? 'Actualizando…' : 'Actualizar resultado',
          onPressed: _cargandoReporte ? null : _cargarReporte,
        ),
      ),
      if (r.pendientes > 0) ...[
        const SizedBox(height: AppSpacing.xs),
        _Aviso(
          texto:
              'Faltan ${r.pendientes} muestras por llegar a Supabase; se '
              'reintentan solas. Actualiza el resultado cuando lleguen.',
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      _Contadores(rastreador: r),
      ..._errores(r),
      const SizedBox(height: AppSpacing.xl),
      _Sesion(id: sesion.id, onCopiar: () => _copiarSesion(sesion.id)),
    ];
  }

  List<Widget> _avisoNotificaciones() {
    if (_notificaciones != false) return const [];
    return const [
      SizedBox(height: AppSpacing.md),
      _Aviso(
        texto:
            'Sin permiso de notificaciones no verás los avisos de cambio de '
            'fase: guíate por las horas de esta pantalla.',
      ),
    ];
  }

  List<Widget> _errores(RastreadorDePrueba r) {
    final errorGps = r.errorGps;
    final errorGpsEn = r.errorGpsEn;
    final errorEnvio = r.errorEnvio;
    final errorEnvioEn = r.errorEnvioEn;

    return [
      if (errorGps != null && errorGpsEn != null) ...[
        const SizedBox(height: AppSpacing.md),
        CupoErrorBanner(
          mensaje: 'GPS, a las ${horaCorta(errorGpsEn)}: $errorGps',
        ),
      ],
      if (errorEnvio != null && errorEnvioEn != null) ...[
        const SizedBox(height: AppSpacing.md),
        CupoErrorBanner(
          mensaje:
              'Último error de envío, a las ${horaCorta(errorEnvioEn)}: '
              '$errorEnvio',
        ),
      ],
    ];
  }

  static IconData _iconoDe(FaseRastreo fase) => switch (fase) {
    FaseRastreo.primerPlano => LucideIcons.smartphone,
    FaseRastreo.minimizada => LucideIcons.house,
    FaseRastreo.pantallaApagada => LucideIcons.lock,
  };

  static String _tituloDe(FaseRastreo fase) => switch (fase) {
    FaseRastreo.primerPlano => 'Deja Cupo abierta',
    FaseRastreo.minimizada => 'Minimiza Cupo',
    FaseRastreo.pantallaApagada => 'Apaga la pantalla',
  };

  static String _instruccionDe(FaseRastreo fase) => switch (fase) {
    FaseRastreo.primerPlano =>
      'No toques nada: la pantalla se queda encendida sola.',
    FaseRastreo.minimizada =>
      'Toca Inicio y usa el teléfono normal (WhatsApp, YouTube…) con la '
          'pantalla encendida. No cierres Cupo desde Recientes.',
    FaseRastreo.pantallaApagada =>
      'Bloquea el teléfono con el botón de encendido y déjalo quieto hasta '
          'que llegue el aviso de fin.',
  };
}

// ════════════════════════════════════════════════════════════ piezas ══════

/// Bloque con icono, rótulo, título y texto: la fase en curso, la búsqueda
/// del GPS o el estado del resultado.
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.fondo,
    required this.icono,
    required this.etiqueta,
    required this.titulo,
    required this.texto,
    this.pie,
  });

  final Color fondo;
  final IconData icono;
  final String etiqueta;
  final String titulo;
  final String texto;
  final String? pie;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final pie = this.pie;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: fondo, borderRadius: AppRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Mosaico(icono: icono),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: textos.labelSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(titulo, style: textos.titleLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(texto, style: AppTypography.meta),
                if (pie != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(pie, style: AppTypography.metaStrong),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icono de Lucide en su mosaico cuadrado, como en las opciones.
class _Mosaico extends StatelessWidget {
  const _Mosaico({required this.icono});

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.choiceIconTile,
      height: AppSizes.choiceIconTile,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(icono, size: AppSizes.icon, color: AppColors.primaryDeep),
    );
  }
}

/// Aviso de algo pendiente: `warning` sobre `warningSoft` (regla 7).
class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: AppSizes.icon,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(texto, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}

/// Teléfono, permiso de ubicación y batería: lo que más pesa en el
/// resultado, a la vista antes de empezar.
class _EstadoTelefono extends StatelessWidget {
  const _EstadoTelefono({
    required this.info,
    required this.permiso,
    required this.onSegundoPlano,
    required this.onBateria,
  });

  final InfoDispositivo? info;
  final LocationPermission? permiso;
  final VoidCallback onSegundoPlano;
  final VoidCallback onBateria;

  @override
  Widget build(BuildContext context) {
    final info = this.info;
    final sinRestriccion = info?.bateriaSinRestriccion;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Este teléfono', style: AppTypography.metaStrong),
          const SizedBox(height: AppSpacing.xs),
          _Dato(
            icono: LucideIcons.smartphone,
            texto: info?.descripcion ?? 'Modelo sin identificar',
          ),
          _Dato(
            icono: LucideIcons.mapPin,
            texto: switch (permiso) {
              LocationPermission.always => 'Ubicación: todo el tiempo',
              LocationPermission.whileInUse =>
                'Ubicación: mientras se usa la app',
              LocationPermission.deniedForever => 'Ubicación: bloqueada',
              LocationPermission.denied ||
              LocationPermission.unableToDetermine ||
              null => 'Ubicación: sin permiso todavía',
            },
            enlace: permiso == LocationPermission.whileInUse
                ? CupoLink(
                    label: 'Permitir todo el tiempo',
                    onPressed: onSegundoPlano,
                    style: AppTypography.linkSmall,
                  )
                : null,
          ),
          if (info?.bateriaPct case final nivel?)
            _Dato(
              icono: info?.cargando == true
                  ? LucideIcons.batteryCharging
                  : LucideIcons.battery,
              texto: info?.cargando == true
                  ? 'Carga: $nivel % · enchufado (queda registrado)'
                  : 'Carga: $nivel % · sin cargador',
            ),
          _Dato(
            icono: sinRestriccion == false
                ? LucideIcons.batteryWarning
                : LucideIcons.battery,
            texto: switch (sinRestriccion) {
              true => 'Batería: sin restricciones para Cupo',
              false => 'Batería: optimizada (Android puede frenar a Cupo)',
              null => 'Batería: no se pudo leer',
            },
            enlace: sinRestriccion == false
                ? CupoLink(
                    label: 'Quitar la restricción',
                    onPressed: onBateria,
                    style: AppTypography.linkSmall,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto, this.enlace});

  final IconData icono;
  final String texto;
  final Widget? enlace;

  @override
  Widget build(BuildContext context) {
    final enlace = this.enlace;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: AppSizes.iconSmall, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto, style: AppTypography.bodySmall),
                ?enlace,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Capturadas, enviadas, pendientes y tiempo, en una cuadrícula de 2×2.
class _Contadores extends StatelessWidget {
  const _Contadores({required this.rastreador});

  final RastreadorDePrueba rastreador;

  @override
  Widget build(BuildContext context) {
    final r = rastreador;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Contador(valor: '${r.capturadas}', rotulo: 'Capturadas'),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Contador(valor: '${r.enviadas}', rotulo: 'Enviadas'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _Contador(
                valor: '${r.pendientes}',
                rotulo: r.fallosDeEnvio == 1
                    ? 'Pendientes · 1 fallo'
                    : 'Pendientes · ${r.fallosDeEnvio} fallos',
                pendiente: r.pendientes > 0,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _Contador(
                valor: formatoCronometro(r.transcurrido),
                rotulo: 'Tiempo',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.valor,
    required this.rotulo,
    this.pendiente = false,
  });

  final String valor;
  final String rotulo;

  /// Hay algo esperando: fondo de pendiente (regla 7).
  final bool pendiente;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: pendiente ? AppColors.warningSoft : AppColors.backgroundAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: pendiente ? AppColors.warning : AppColors.border,
          width: AppSizes.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: Theme.of(context).textTheme.headlineSmall),
          Text(rotulo, style: AppTypography.helper),
        ],
      ),
    );
  }
}

/// Las tres fases con su horario, marcando la que corre.
class _Cronograma extends StatelessWidget {
  const _Cronograma({required this.sesion, required this.actual});

  final SesionRastreo sesion;
  final FaseRastreo actual;

  @override
  Widget build(BuildContext context) {
    final protocolo = sesion.protocolo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Horario de la prueba', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        for (final fase in FaseRastreo.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                Icon(
                  fase.numero < actual.numero
                      ? LucideIcons.circleCheck
                      : fase == actual
                      ? LucideIcons.circleDot
                      : LucideIcons.circle,
                  size: AppSizes.icon,
                  color: fase.numero > actual.numero
                      ? AppColors.textSupport
                      : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Fase ${fase.numero} · '
                    '${_PruebaRastreoScreenState._tituloDe(fase)}',
                    style: fase == actual
                        ? AppTypography.metaStrong
                        : AppTypography.meta,
                  ),
                ),
                Text(
                  '${horaCorta(sesion.inicio.add(protocolo.inicioDe(fase)))} – '
                  '${horaCorta(sesion.inicio.add(protocolo.finDe(fase)))}',
                  style: AppTypography.meta,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// El identificador de la sesión, para buscarla en Supabase.
class _Sesion extends StatelessWidget {
  const _Sesion({required this.id, required this.onCopiar});

  final String id;
  final VoidCallback onCopiar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sesión', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xxs),
        SelectableText(id, style: AppTypography.helper),
        CupoLink(label: 'Copiar', onPressed: onCopiar),
      ],
    );
  }
}

/// El veredicto de la sesión, con el criterio a la vista.
class _Veredicto extends StatelessWidget {
  const _Veredicto({required this.reporte, required this.detenida});

  final List<ReporteFase> reporte;
  final bool detenida;

  @override
  Widget build(BuildContext context) {
    final veredicto = veredictoRastreo(reporte);
    final criterio =
        'Criterio: cobertura ≥ ${CriterioRastreo.coberturaMinima.round()} % y '
        'brecha máxima ≤ ${CriterioRastreo.brechaMaxima.round()} s en las '
        'tres fases.';

    return switch (veredicto) {
      true => _Tarjeta(
        fondo: AppColors.successSoft,
        icono: LucideIcons.circleCheck,
        etiqueta: 'RESULTADO',
        titulo: 'Cumple en las tres fases',
        texto: criterio,
      ),
      false => _Tarjeta(
        fondo: AppColors.dangerSoft,
        icono: LucideIcons.circleX,
        etiqueta: 'RESULTADO',
        titulo: 'No cumple',
        texto: criterio,
      ),
      null => _Tarjeta(
        fondo: AppColors.backgroundAlt,
        icono: LucideIcons.circleDashed,
        etiqueta: 'RESULTADO PARCIAL',
        titulo: detenida ? 'Prueba detenida antes de tiempo' : 'Faltan datos',
        texto: 'Las fases sin completar no cuentan. $criterio',
      ),
    };
  }
}

/// Una fase del reporte: sus números y si cumple.
class _FilaReporte extends StatelessWidget {
  const _FilaReporte({required this.fase});

  final ReporteFase fase;

  @override
  Widget build(BuildContext context) {
    final f = fase;
    final (texto, tinta, fondo) = switch ((f.completa, f.cumple)) {
      (true, true) => ('Cumple', AppColors.success, AppColors.successSoft),
      (true, false) => ('No cumple', AppColors.danger, AppColors.dangerSoft),
      _ => ('Incompleta', AppColors.textSecondary, AppColors.backgroundMuted),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fase ${f.fase.numero} · '
                  '${_PruebaRastreoScreenState._tituloDe(f.fase)}',
                  style: AppTypography.metaStrong,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: fondo,
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(
                  texto,
                  style: AppTypography.label.copyWith(color: tinta),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Cobertura ${_numero(f.coberturaPct)} % '
            '(${f.recibidas} de ${f.esperadas})',
            style: AppTypography.bodySmall,
          ),
          Text(
            'Brecha máx. ${_numero(f.brechaMaxS)} s · '
            'p95 ${_numero(f.brechaP95S)} s',
            style: AppTypography.bodySmall,
          ),
          Text(
            'Perdidas ${f.perdidas} · tardías ${f.tardias} · latencia '
            '${_numero(f.latenciaMedianaS)} s',
            style: AppTypography.bodySmall,
          ),
          Text('Estados: ${f.estados}', style: AppTypography.helper),
        ],
      ),
    );
  }

  /// «98,3»: coma decimal, como se escribe en Venezuela.
  static String _numero(double? valor) =>
      valor == null ? '—' : valor.toStringAsFixed(1).replaceAll('.', ',');
}
