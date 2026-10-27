import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../data/canal_dispositivo.dart';
import '../data/fuente_de_ubicacion.dart';
import '../data/spike_rastreo_repository.dart';
import '../domain/muestra_rastreo.dart';
import '../domain/protocolo_rastreo.dart';
import '../domain/reporte_fase.dart';
import 'rastreador_de_prueba.dart';

/// «Prueba de rastreo» — spike de HU-011, solo en modo debug.
///
/// Responde una pregunta: ¿Cupo sigue mandando la ubicación del conductor a
/// Supabase con la app minimizada y con la pantalla apagada? Corre tres
/// fases seguidas (app abierta, minimizada, pantalla apagada), guarda cada
/// muestra en `spike_posiciones` y al final muestra `spike_reporte()`. El
/// protocolo y cómo leer el resultado están en
/// `docs/producto/spike-rastreo.md`.
///
/// Se entra desde el inicio del conductor, con un botón que solo existe en
/// las compilaciones de depuración.
class PruebaRastreoScreen extends StatefulWidget {
  const PruebaRastreoScreen({
    super.key,
    this.repositorio,
    this.ubicacion,
    this.canal,
  });

  /// Por omisión, los reales. Las pruebas pasan unos falsos.
  final SpikeRastreoRepository? repositorio;
  final FuenteDeUbicacion? ubicacion;
  final CanalDispositivo? canal;

  @override
  State<PruebaRastreoScreen> createState() => _PruebaRastreoScreenState();
}

/// A qué pantalla de Ajustes manda el error de arranque.
enum _Ajustes { ubicacion, app }

class _PruebaRastreoScreenState extends State<PruebaRastreoScreen> {
  late final SpikeRastreoRepository _repo =
      widget.repositorio ?? SpikeRastreoRepository();
  late final FuenteDeUbicacion _ubicacion =
      widget.ubicacion ?? const FuenteDeUbicacion();
  late final CanalDispositivo _canal = widget.canal ?? const CanalDispositivo();

  late final RastreadorDePrueba _rastreador = RastreadorDePrueba(
    abrirPosiciones: _abrirPosiciones,
    enviar: _repo.insertar,
    pantallaEncendida: _canal.pantallaEncendida,
    alCambiarDeFase: _alCambiarDeFase,
  );

  late final AppLifecycleListener _ciclo;

  DuracionPrueba _duracion = DuracionPrueba.estandar;
  bool _wakelock = true;

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
    unawaited(_leerTelefono());
  }

  @override
  void dispose() {
    _ciclo.dispose();
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
    return _ubicacion.posiciones(
      intervalo: config.intervalo,
      wakelock: config.wakelock,
      tituloAviso: 'Cupo · Prueba de rastreo',
      textoAviso:
          'Midiendo si tu ubicación llega a Cupo. Sigue los avisos de '
          'cada fase.',
      acento: AppColors.primary,
    );
  }

  Future<void> _empezar() async {
    setState(() {
      _preparando = true;
      _errorInicio = null;
      _ajustesDelError = null;
      _reporte = null;
      _errorReporte = null;
    });

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

      // Sin esto, la pantalla se apagaría sola a mitad de la fase 1.
      await _canal.mantenerPantallaEncendida(true);
      _rastreador.iniciar(
        ConfigPrueba(
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

  void _fallarInicio(String mensaje, [_Ajustes? ajustes]) {
    if (!mounted) return;
    setState(() {
      _errorInicio = mensaje;
      _ajustesDelError = ajustes;
    });
  }

  void _alCambiarDeFase(FaseRastreo? fase, SesionRastreo sesion) {
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
      final reporte = await _repo.reporte(sesion.id);
      if (mounted) setState(() => _reporte = reporte);
    } on SpikeRastreoFallo catch (e) {
      if (mounted) setState(() => _errorReporte = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargandoReporte = false);
    }
  }

  void _nuevaPrueba() {
    _rastreador.reiniciar();
    setState(() {
      _reporte = null;
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
              Text(
                '¿Cupo sigue enviando tu ubicación con la app minimizada y con '
                'la pantalla apagada? Son tres fases seguidas y la app te '
                'avisa cuándo cambiar.',
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              ...switch (r.etapa) {
                EtapaPrueba.lista => _configuracion(),
                EtapaPrueba.buscandoGps => _buscandoGps(r),
                EtapaPrueba.enCurso => _enCurso(r),
                EtapaPrueba.terminada || EtapaPrueba.detenida => _resultado(r),
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
        label: 'Empezar prueba',
        isLoading: _preparando,
        onPressed: _preparando ? null : _empezar,
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

    return [
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
            DuracionPrueba.larga =>
              'Una hora: le da tiempo a Android de entrar en reposo profundo.',
          },
          seleccionado: _duracion == opcion,
          onPressed: () => setState(() => _duracion = opcion),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
      const SizedBox(height: AppSpacing.md),
      Text('Servicio de ubicación', style: AppTypography.label),
      const SizedBox(height: AppSpacing.xs),
      CupoCheckTile(
        icono: LucideIcons.cpu,
        titulo: 'Mantener el procesador despierto',
        descripcion:
            'Wake lock del servicio. Recomendado; quítalo solo para comparar.',
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
      const SizedBox(height: AppSpacing.md),
      CupoInfoBanner(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Antes de empezar', style: AppTypography.metaStrong),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '1. Desconecta el cargador: cargando, Android no ahorra batería '
              'y la prueba no dice nada.\n'
              '2. Sube el tiempo de espera de la pantalla al máximo, para que '
              'no se apague sola en la fase 2.\n'
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
