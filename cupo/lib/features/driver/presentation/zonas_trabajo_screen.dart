import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/geo/zonas_maracaibo.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_scope.dart';
import '../data/zonas_repository.dart';
import '../domain/zona.dart';
import 'mapa_ruta_del_dia.dart' show BotonSobreMapa;

/// «Tus zonas de trabajo» (`DestinoAuth.onboardingConductor`).
///
/// La ve el conductor con la cuenta ya aprobada y sin onboarding. Elige los
/// sectores donde recoge estudiantes de dos maneras, que se mantienen en
/// sincronía: tocando la zona en el mapa o marcándola en la lista. Es
/// selección múltiple: un conductor puede trabajar en varias zonas.
///
/// El mapa se puede poner a pantalla completa para elegir con más espacio;
/// ahí la lista se esconde y queda solo el pie con el botón de guardar. Donde
/// dos zonas se solapan, un toque no basta para saber cuál quiso: se le
/// pregunta.
///
/// Al guardar:
/// 1. deja en `conductor_zonas` exactamente las zonas elegidas;
/// 2. llama a `completar_onboarding()`, que exige al menos una;
/// 3. el `AuthGate` ve `onboarding_completo = true` por Realtime y lleva a
///    `inicioConductor`.
class ZonasTrabajoScreen extends StatefulWidget {
  const ZonasTrabajoScreen({super.key, this.repositorio, this.controladorMapa});

  /// Por omisión, el de Supabase. Las pruebas pasan uno falso.
  final ZonasRepository? repositorio;

  /// Por omisión, uno propio. Las pruebas lo pasan para saber en qué punto de
  /// la pantalla cae una zona y poder tocarla.
  final MapController? controladorMapa;

  @override
  State<ZonasTrabajoScreen> createState() => _ZonasTrabajoScreenState();
}

class _ZonasTrabajoScreenState extends State<ZonasTrabajoScreen> {
  /// Todos los vértices del catálogo local: el encuadre inicial los muestra
  /// todos.
  static final List<LatLng> _todoElCatalogo = [
    for (final zona in zonasMaracaibo) ...zona.vertices,
  ];

  late final ZonasRepository _zonas = widget.repositorio ?? ZonasRepository();
  late final MapController _mapa = widget.controladorMapa ?? MapController();

  /// Qué polígonos quedaron bajo el dedo en el último toque. Lo llena la capa
  /// de polígonos de flutter_map durante la detección del toque.
  final LayerHitNotifier<String> _toque = ValueNotifier(null);

  List<Zona>? _catalogo;
  final Set<String> _elegidas = {};

  bool _mapaCompleto = false;
  bool _cargando = true;
  bool _guardando = false;
  String? _errorCarga;
  String? _errorGuardado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _toque.dispose();
    if (widget.controladorMapa == null) _mapa.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });

    try {
      final catalogo = await _zonas.catalogo();
      final mias = await _zonas.misZonas();
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _elegidas
          ..clear()
          // Solo las que siguen en el catálogo: una zona dada de baja no se
          // puede volver a guardar.
          ..addAll(mias.where((id) => catalogo.any((z) => z.id == id)));
      });
    } catch (e) {
      if (mounted) setState(() => _errorCarga = _mensajeDe(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Marca o desmarca [zona].
  ///
  /// Desde la lista, el mapa va a la zona recién marcada ([enfocar]); desde
  /// el mapa no, porque la persona ya la está viendo y moverle la cámara bajo
  /// el dedo desorienta.
  void _alternar(Zona zona, {bool enfocar = true}) {
    if (_guardando) return;
    final seleccionar = !_elegidas.contains(zona.id);
    setState(() {
      _errorGuardado = null;
      seleccionar ? _elegidas.add(zona.id) : _elegidas.remove(zona.id);
    });

    final forma = _formaDe(zona);
    if (enfocar && seleccionar && forma != null) {
      _encuadrar(forma.vertices);
    }
  }

  /// Un toque sobre la capa de polígonos.
  void _alTocarMapa() {
    final ids = _toque.value?.hitValues ?? const <String>[];
    final tocadas = [
      for (final zona in _catalogo ?? const <Zona>[])
        if (ids.contains(zona.id)) zona,
    ];

    switch (tocadas) {
      case []:
        return;
      case [final zona]:
        _alternar(zona, enfocar: false);
      default:
        _elegirEntre(tocadas);
    }
  }

  /// Dos o más zonas solapadas bajo el mismo toque: se pregunta cuál.
  Future<void> _elegirEntre(List<Zona> zonas) async {
    final elegida = await showModalBottomSheet<Zona>(
      context: context,
      backgroundColor: AppColors.surface,
      elevation: 0,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (context) => _HojaSolape(zonas: zonas, elegidas: {..._elegidas}),
    );
    if (elegida != null) _alternar(elegida, enfocar: false);
  }

  void _encuadrar(List<LatLng> puntos) {
    _mapa.fitCamera(
      CameraFit.coordinates(
        coordinates: puntos,
        padding: const EdgeInsets.all(AppSpacing.xxl),
      ),
    );
  }

  void _verTodas() {
    final puntos = [
      for (final zona in _catalogo ?? const <Zona>[])
        ...?_formaDe(zona)?.vertices,
    ];
    _encuadrar(puntos.isEmpty ? _todoElCatalogo : puntos);
  }

  void _cambiarTamanoMapa() {
    FocusScope.of(context).unfocus();
    setState(() => _mapaCompleto = !_mapaCompleto);
  }

  Future<void> _guardar() async {
    if (_elegidas.isEmpty) return;
    final auth = AuthScope.de(context).repositorio;

    setState(() {
      _guardando = true;
      _errorGuardado = null;
    });

    try {
      await _zonas.guardarMisZonas(_elegidas);
      await auth.completarOnboarding();
      // No se navega: el AuthGate se entera por Realtime y cambia de pantalla.
    } catch (e) {
      if (mounted) setState(() => _errorGuardado = _mensajeDe(e));
    } finally {
      // También tras un guardado bueno: si Realtime tarda o falla, el botón
      // no se queda girando para siempre y se puede volver a intentar.
      if (mounted) setState(() => _guardando = false);
    }
  }

  static String _mensajeDe(Object? e) => switch (e) {
    ZonasFallo(:final mensaje) => mensaje,
    AuthFallo(:final mensaje) => mensaje,
    _ => 'No pudimos conectar con Cupo. Revisa tu conexión e intenta de nuevo.',
  };

  /// La forma de la zona para el mapa, de la copia local del catálogo.
  static ZonaCobertura? _formaDe(Zona zona) {
    for (final forma in zonasMaracaibo) {
      if (forma.nombre == zona.nombre) return forma;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = _catalogo ?? const <Zona>[];

    // Con el mapa completo, «atrás» lo achica en vez de salir.
    return PopScope(
      canPop: !_mapaCompleto,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _mapaCompleto = false);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          // Las llaves hacen que el mapa conserve su cámara cuando el
          // encabezado y la lista entran o salen de la columna.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_mapaCompleto)
                const Padding(
                  key: ValueKey('encabezado'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.md,
                    AppSpacing.screenH,
                    AppSpacing.md,
                  ),
                  child: _Encabezado(),
                ),
              Expanded(
                key: const ValueKey('mapa'),
                flex: 2,
                child: _mapaDeZonas(catalogo),
              ),
              if (!_mapaCompleto)
                Expanded(
                  key: const ValueKey('lista'),
                  flex: 3,
                  child: _lista(catalogo),
                ),
              _PanelGuardar(
                key: const ValueKey('panel'),
                cantidad: _elegidas.length,
                guardando: _guardando,
                error: _errorGuardado,
                onGuardar: _elegidas.isEmpty || _cargando ? null : _guardar,
                onCerrarSesion: _mapaCompleto
                    ? null
                    : AuthScope.de(context).repositorio.salir,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapaDeZonas(List<Zona> catalogo) {
    final conForma = [
      for (final zona in catalogo)
        if (_formaDe(zona) case final forma?) (zona, forma),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        border: _mapaCompleto
            ? null
            : const Border.symmetric(
                horizontal: BorderSide(color: AppColors.border),
              ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCameraFit: CameraFit.coordinates(
                  coordinates: _todoElCatalogo,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                ),
                // Sin rotación: los nombres de las zonas se leen derechos.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cupo.app',
                  maxZoom: 19,
                ),
                // El GestureDetector solo recibe el toque si cae sobre un
                // polígono; si cae fuera, el mapa lo usa para moverse.
                GestureDetector(
                  onTap: _alTocarMapa,
                  child: PolygonLayer<String>(
                    hitNotifier: _toque,
                    polygons: [
                      for (final (zona, forma) in conForma)
                        _poligono(zona, forma, _elegidas.contains(zona.id)),
                    ],
                  ),
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          if (conForma.isNotEmpty)
            const Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              // Deja libre la columna de botones de la derecha.
              right: AppSpacing.md + AppSizes.iconButton + AppSpacing.sm,
              child: Align(alignment: Alignment.topLeft, child: _Pista()),
            ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Column(
              children: [
                BotonSobreMapa(
                  icono: _mapaCompleto
                      ? LucideIcons.minimize2
                      : LucideIcons.maximize2,
                  mensaje: _mapaCompleto
                      ? 'Achicar el mapa'
                      : 'Ver mapa completo',
                  onPressed: _cambiarTamanoMapa,
                ),
                const SizedBox(height: AppSpacing.xs),
                BotonSobreMapa(
                  icono: LucideIcons.scan,
                  mensaje: 'Ver todas las zonas',
                  onPressed: _verTodas,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Polygon<String> _poligono(Zona zona, ZonaCobertura forma, bool elegida) {
    return Polygon<String>(
      hitValue: zona.id,
      points: forma.vertices,
      color: elegida
          ? AppColors.primary.withValues(alpha: 0.30)
          : AppColors.primarySoft.withValues(alpha: 0.35),
      borderColor: elegida ? AppColors.primaryDeep : AppColors.textSupportSoft,
      borderStrokeWidth: elegida ? 2.5 : 1,
      // Todas llevan su nombre: para tocar una zona hay que saber cuál es.
      label: forma.nombre,
      labelStyle: elegida
          ? AppTypography.metaStrong.copyWith(color: AppColors.primaryDarkest)
          : AppTypography.meta.copyWith(color: AppColors.textSecondary),
      labelPlacementCalculator:
          const PolygonLabelPlacementCalculator.centroid(),
    );
  }

  Widget _lista(List<Zona> catalogo) {
    final errorCarga = _errorCarga;

    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (errorCarga != null) {
      return _Mensaje(
        children: [
          CupoErrorBanner(mensaje: errorCarga),
          const SizedBox(height: AppSpacing.md),
          CupoSecondaryButton(label: 'Reintentar', onPressed: _cargar),
        ],
      );
    }

    if (catalogo.isEmpty) {
      return _Mensaje(
        children: [
          CupoInfoBanner(
            child: Text(
              'Todavía no hay zonas cargadas en Cupo. Avísale al '
              'administrador para que las agregue.',
              style: AppTypography.body,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      itemCount: catalogo.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, i) {
        final zona = catalogo[i];
        return CupoCheckTile(
          icono: LucideIcons.mapPin,
          titulo: zona.nombre,
          descripcion: zona.municipio,
          seleccionado: _elegidas.contains(zona.id),
          onPressed: _guardando ? null : () => _alternar(zona),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tus zonas de trabajo', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Marca los sectores donde recoges estudiantes. Te van a encontrar '
          'los que viven en ellos.',
          style: AppTypography.body,
        ),
      ],
    );
  }
}

/// Aviso flotante sobre el mapa: cómo se elige.
class _Pista extends StatelessWidget {
  const _Pista();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.pointer,
            size: AppSizes.iconSmall,
            color: AppColors.primaryDeep,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Toca una zona para elegirla',
              style: AppTypography.metaStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja que aparece cuando un toque cae sobre zonas solapadas.
class _HojaSolape extends StatelessWidget {
  const _HojaSolape({required this.zonas, required this.elegidas});

  final List<Zona> zonas;
  final Set<String> elegidas;

  @override
  Widget build(BuildContext context) {
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
            Text('Aquí se cruzan varias zonas', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Elige cuál quieres marcar o desmarcar.',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final zona in zonas) ...[
              CupoCheckTile(
                icono: LucideIcons.mapPin,
                titulo: zona.nombre,
                descripcion: zona.municipio,
                seleccionado: elegidas.contains(zona.id),
                onPressed: () => Navigator.of(context).pop(zona),
              ),
              if (zona != zonas.last) const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

/// Contenedor de los estados sin lista: error de carga y catálogo vacío.
class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Pie anclado: cuántas zonas van, el error del guardado y el botón.
class _PanelGuardar extends StatelessWidget {
  const _PanelGuardar({
    super.key,
    required this.cantidad,
    required this.guardando,
    required this.error,
    required this.onGuardar,
    required this.onCerrarSesion,
  });

  final int cantidad;
  final bool guardando;
  final String? error;
  final VoidCallback? onGuardar;

  /// Si es `null`, el enlace no se muestra: con el mapa completo, el pie se
  /// queda con lo mínimo.
  final VoidCallback? onCerrarSesion;

  String get _resumen => switch (cantidad) {
    0 => 'Elige al menos una zona.',
    1 => '1 zona elegida',
    _ => '$cantidad zonas elegidas',
  };

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final onCerrarSesion = this.onCerrarSesion;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            CupoErrorBanner(mensaje: error),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            _resumen,
            style: AppTypography.helper,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          CupoPrimaryButton(
            label: 'Guardar mis zonas',
            onPressed: guardando ? null : onGuardar,
            isLoading: guardando,
          ),
          if (onCerrarSesion != null)
            Center(
              child: CupoLink(
                label: 'Cerrar sesión',
                onPressed: onCerrarSesion,
              ),
            ),
        ],
      ),
    );
  }
}
