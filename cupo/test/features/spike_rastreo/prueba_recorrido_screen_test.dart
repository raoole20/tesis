import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cupo/features/spike_rastreo/data/canal_dispositivo.dart';
import 'package:cupo/features/spike_rastreo/data/fuente_de_ubicacion.dart';
import 'package:cupo/features/spike_rastreo/data/servicio_de_rutas.dart';
import 'package:cupo/features/spike_rastreo/data/spike_rastreo_repository.dart';
import 'package:cupo/features/spike_rastreo/domain/geo.dart';
import 'package:cupo/features/spike_rastreo/domain/reporte_ruta.dart';
import 'package:cupo/features/spike_rastreo/domain/ruta_planificada.dart';
import 'package:cupo/features/spike_rastreo/domain/traza.dart';
import 'package:cupo/features/spike_rastreo/presentation/mapa_recorrido.dart';
import 'package:cupo/features/spike_rastreo/presentation/prueba_rastreo_screen.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:cupo/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../soporte/banco_de_pruebas.dart';

/// Donde «está» el teléfono en las pruebas: cerca de la Av. 61.
const _aqui = PuntoGeo(10.7021, -71.6040);

Position _posicion(PuntoGeo p) => Position(
  latitude: p.lat,
  longitude: p.lng,
  timestamp: DateTime.now(),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class _UbicacionFalsa extends FuenteDeUbicacion {
  _UbicacionFalsa({this.sinUbicacion = false});

  final bool sinUbicacion;
  final gps = StreamController<Position>.broadcast();
  String? textoAviso;
  int permisosPedidos = 0;
  int flujosAbiertos = 0;

  @override
  Future<bool> servicioActivo() async => true;

  @override
  Future<LocationPermission> permiso() async => LocationPermission.whileInUse;

  @override
  Future<LocationPermission> pedirPermiso() async {
    permisosPedidos++;
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> posicionActual() async {
    permisosPedidos++;
    if (sinUbicacion) {
      throw const PermissionDeniedException('Sin permiso de ubicación');
    }
    return _posicion(_aqui);
  }

  @override
  Stream<Position> posiciones({
    required Duration intervalo,
    required bool wakelock,
    required String tituloAviso,
    required String textoAviso,
    Color? acento,
  }) {
    flujosAbiertos++;
    this.textoAviso = textoAviso;
    return gps.stream;
  }
}

class _CanalFalso extends CanalDispositivo {
  bool? pantallaFija;
  final List<
    ({
      String titulo,
      String texto,
      bool fijo,
      int? progreso,
      DateTime? inicio,
      int? color,
    })
  >
  estados = [];
  int cierres = 0;

  @override
  Future<bool> mostrarEstado({
    required String titulo,
    required String texto,
    DateTime? inicio,
    int? progreso,
    int maximo = 1000,
    bool fijo = true,
    Color? acento,
  }) async {
    estados.add((
      titulo: titulo,
      texto: texto,
      fijo: fijo,
      progreso: progreso,
      inicio: inicio,
      color: acento?.toARGB32(),
    ));
    return true;
  }

  @override
  Future<void> cerrarEstado() async => cierres++;

  @override
  Future<InfoDispositivo?> info() async => const InfoDispositivo(
    fabricante: 'samsung',
    modelo: 'SM-A515F',
    android: '13',
    sdk: 33,
    bateriaSinRestriccion: false,
    bateriaPct: 92,
    cargando: true,
  );

  @override
  Future<bool> pedirNotificaciones() async => true;

  @override
  Future<EstadoAlCapturar?> estadoAlCapturar() async =>
      const EstadoAlCapturar(pantallaEncendida: false, bateriaPct: 91);

  @override
  Future<void> mantenerPantallaEncendida(bool activo) async {
    pantallaFija = activo;
  }

  @override
  Future<bool> avisar({required String titulo, required String texto}) async =>
      true;
}

/// OSRM sin red: siempre la ruta real guardada de la Av. 61 a la URBE.
class _RutasFalsas extends ServicioDeRutas {
  _RutasFalsas({this.falla = false});

  final bool falla;
  final List<List<PuntoGeo>> pedidas = [];

  @override
  Future<RutaPlanificada> trazar(List<PuntoGeo> paradas) async {
    pedidas.add(paradas);
    if (falla) {
      throw const RutaFallo('No hay conexión con el servidor de rutas.');
    }
    return RutaPlanificada.desdeOsrm(
      jsonDecode(
        File('test/features/spike_rastreo/datos/osrm_ida.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    );
  }
}

class _RepoFalso extends SpikeRastreoRepository {
  final List<Map<String, Object?>> filas = [];
  final List<String> recorridos = [];
  final List<DateTime> recalculos = [];
  RutaPlanificada? planRegistrado;
  bool? recorridoSimulado;

  @override
  Future<void> insertar(List<Map<String, Object?>> filas) async {
    this.filas.addAll(filas);
  }

  @override
  Future<void> registrarRecorrido({
    required String sesionId,
    required RutaDePrueba ruta,
    required bool idaYVuelta,
    RutaPlanificada? planificada,
    PuntoGeo? domicilio,
    bool simulada = false,
  }) async {
    recorridos.add(sesionId);
    planRegistrado = planificada;
    recorridoSimulado = simulada;
  }

  @override
  Future<void> registrarRutaRecalculada({
    required String sesionId,
    required DateTime calculadaEn,
    required PuntoGeo desde,
    required RutaPlanificada ruta,
    double? desvioM,
    bool simulada = false,
  }) async {
    recalculos.add(calculadaEn);
  }

  @override
  Future<ReporteRuta?> reporteRuta(String sesionId) async =>
      ReporteRuta.fromMap({
        'simulada': filas.any((f) => f['simulada'] == true),
        'completa': true,
        'inicio': '2026-10-27T13:00:00+00:00',
        'fin': '2026-10-27T13:08:00+00:00',
        'duracion_s': 480,
        'distancia_m': 5350,
        'velocidad_media_kmh': 40.1,
        'velocidad_max_gps_kmh': 50,
        'velocidad_max_traza_kmh': 52,
        'esperadas': 96,
        'recibidas': 95,
        'cobertura_pct': 99,
        'brecha_max_s': 10,
        'brecha_max_en': '2026-10-27T13:05:00+00:00',
        'brecha_max_m': 120,
        'brecha_p95_s': 5,
        'brechas_largas': 0,
        'pct_primer_plano': 2,
        'pct_segundo_plano': 49,
        'pct_pantalla_apagada': 49,
        'cobertura_primer_plano': 100,
        'cobertura_segundo_plano': 98.9,
        'cobertura_pantalla_apagada': 98.9,
        'precision_p50_m': 4,
        'precision_p95_m': 9,
        'perdidas': 0,
        'tardias': 0,
        'latencia_mediana_s': 0.6,
        'pct_cargando': 100,
        'bateria_inicio_pct': 92,
        'bateria_fin_pct': 90,
        'ruta_planificada_m': 5386,
        'desvio_mediana_m': 4.2,
        'desvio_p95_m': 12.5,
        'desvio_max_m': 31,
        'pct_muestras_cerca_ruta': 100,
        'pct_ruta_cubierta': 97.4,
        'rutas_recalculadas': recalculos.length,
        'dom_radio_m': null,
        'dom_distancia_min_m': null,
        'dom_entrada_en': null,
        'dom_entrada_m': null,
        'dom_brecha_previa_s': null,
        'dom_muestras_alrededor': 0,
        'dom_aviso_a_tiempo': null,
        'cumple': true,
      });

  @override
  Future<List<PuntoTraza>> traza(String sesionId) async => [
    for (final f in filas) PuntoTraza.fromMap(f),
  ];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _UbicacionFalsa ubicacion;
  late _CanalFalso canal;
  late _RepoFalso repo;
  late _RutasFalsas rutas;

  Future<void> montar(
    WidgetTester tester, {
    bool rutaFalla = false,
    bool sinUbicacion = false,
  }) async {
    ubicacion = _UbicacionFalsa(sinUbicacion: sinUbicacion);
    canal = _CanalFalso();
    repo = _RepoFalso();
    rutas = _RutasFalsas(falla: rutaFalla);
    await montarPantalla(
      tester,
      PruebaRastreoScreen(
        repositorio: repo,
        ubicacion: ubicacion,
        canal: canal,
        rutas: rutas,
      ),
    );
    await tester.pump();
  }

  Future<void> elegir(WidgetTester tester, String modo) async {
    await tester.tap(find.text(modo));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  Future<void> tocar(WidgetTester tester, Finder boton) async {
    await tester.ensureVisible(boton);
    await tester.pump();
    await tester.tap(boton);
    await tester.pump();
    await tester.pump();
  }

  Future<void> desmontar(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  /// Dónde está el marcador de la unidad en el mapa.
  LatLng? unidad(WidgetTester tester) {
    for (final capa in tester.widgetList<MarkerLayer>(
      find.byType(MarkerLayer),
    )) {
      for (final m in capa.markers) {
        if (m.key == const ValueKey('marcador-unidad')) return m.point;
      }
    }
    return null;
  }

  /// Los metros de «Faltan 4,1 km» / «Faltan 820 m».
  double? faltan(WidgetTester tester) {
    final textos = tester
        .widgetList<Text>(find.textContaining('Faltan '))
        .map((t) => t.data ?? '');
    if (textos.isEmpty) return null;
    final texto = textos.first.replaceFirst('Faltan ', '').replaceAll(',', '.');
    final numero = double.parse(texto.split(' ').first);
    return texto.endsWith('km') ? numero * 1000 : numero;
  }

  testWidgets('el selector ofrece los tres modos; por omisión, por fases', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text('Prueba por fases'), findsOneWidget);
    expect(find.text('Recorrido real'), findsOneWidget);
    expect(find.text('Simular recorrido'), findsOneWidget);
    expect(find.text('10 minutos por fase'), findsOneWidget);
    expect(find.byType(MapaRecorrido), findsNothing);
    expect(rutas.pedidas, isEmpty);

    await desmontar(tester);
  });

  testWidgets('el recorrido sale de la ubicación actual y llega a la URBE', (
    tester,
  ) async {
    await montar(tester);
    await elegir(tester, 'Recorrido real');

    expect(rutas.pedidas.single, [_aqui, RutaDePrueba.porOmision.llegada]);
    expect(find.byType(MapaRecorrido), findsOneWidget);
    expect(find.text('De tu ubicación a la URBE'), findsOneWidget);
    expect(
      find.text('5,4 km · ≈8 min sin tráfico (según OSRM)'),
      findsOneWidget,
    );
    expect(find.textContaining('Avenida 61 → Calle 44 A'), findsOneWidget);
    expect(
      find.widgetWithText(CupoPrimaryButton, 'Empezar recorrido'),
      findsOneWidget,
    );
    expect(find.text('10 minutos por fase'), findsNothing);

    await desmontar(tester);
  });

  testWidgets('el mapa del plan encuadra la salida y la URBE', (tester) async {
    await montar(tester);
    await elegir(tester, 'Recorrido real');
    await tester.pump(const Duration(milliseconds: 100));

    final camara = MapCamera.of(tester.element(find.byType(BrujulaMapa).first));
    final urbe = RutaDePrueba.porOmision.llegada;
    expect(
      camara.visibleBounds.contains(LatLng(urbe.lat, urbe.lng)),
      isTrue,
      reason: 'La URBE tiene que verse',
    );
    expect(
      camara.visibleBounds.contains(LatLng(_aqui.lat, _aqui.lng)),
      isTrue,
      reason: 'La salida tiene que verse',
    );

    await desmontar(tester);
  });

  testWidgets('sin ubicación usa la salida de respaldo y lo avisa', (
    tester,
  ) async {
    await montar(tester, sinUbicacion: true);
    await elegir(tester, 'Recorrido real');

    expect(find.textContaining('salida de respaldo'), findsOneWidget);
    expect(rutas.pedidas.single.first, RutaDePrueba.porOmision.inicio);

    await desmontar(tester);
  });

  testWidgets('si OSRM no responde, el recorrido se puede hacer igual', (
    tester,
  ) async {
    await montar(tester, rutaFalla: true);
    await elegir(tester, 'Recorrido real');

    expect(
      find.textContaining('Puedes hacer el recorrido igual'),
      findsOneWidget,
    );
    await tocar(
      tester,
      find.widgetWithText(CupoPrimaryButton, 'Empezar recorrido'),
    );
    expect(find.text('Buscando señal GPS…'), findsOneWidget);

    await desmontar(tester);
  });

  testWidgets('recorrido real: registra el plan, muestra lo que falta, '
      'termina con la marca de cierre y muestra el resultado', (tester) async {
    await montar(tester);
    await elegir(tester, 'Recorrido real');
    await tocar(
      tester,
      find.widgetWithText(CupoPrimaryButton, 'Empezar recorrido'),
    );
    expect(ubicacion.textoAviso, contains('Terminar recorrido'));
    expect(canal.pantallaFija, isNull);

    ubicacion.gps.add(_posicion(_aqui));
    await tester.pump();
    await tester.pump();
    ubicacion.gps.add(_posicion(const PuntoGeo(10.7025, -71.6040)));
    await tester.pump();
    await tester.pump();

    expect(find.text('RECORRIDO REAL · EN CURSO'), findsOneWidget);
    expect(find.byTooltip('Tu unidad'), findsOneWidget);
    expect(faltan(tester), inInclusiveRange(4500, 5500));
    expect(repo.recorridos, hasLength(1));
    expect(repo.recorridoSimulado, isFalse);
    expect(repo.filas.first['simulada'], false);
    expect(repo.filas.first['modo'], 'recorrido');

    await tocar(
      tester,
      find.widgetWithText(CupoPrimaryButton, 'Terminar recorrido'),
    );
    expect(find.text('¿Ya estacionaste?'), findsOneWidget);
    await tester.tap(find.text('Terminar'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(repo.filas.last['cierre'], true);
    expect(find.text('Cumple'), findsOneWidget);
    expect(find.textContaining('SESIÓN SIMULADA'), findsNothing);
    expect(find.byType(MapaRecorrido), findsOneWidget);

    await tocar(tester, find.text('Ver mapa a pantalla completa'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MapaRecorridoScreen), findsOneWidget);
    expect(
      find.text('Recorrido real · Prueba: tu ubicación → URBE'),
      findsOneWidget,
    );

    await desmontar(tester);
  });

  group('simulación', () {
    Future<void> empezarSimulacion(
      WidgetTester tester, {
      bool desvio = false,
    }) async {
      await montar(tester);
      await elegir(tester, 'Simular recorrido');
      await tocar(tester, find.text('50 km/h'));
      await tocar(tester, find.text('×20'));
      if (desvio) await tocar(tester, find.text('Simular un desvío'));
      await tocar(
        tester,
        find.widgetWithText(CupoPrimaryButton, 'Empezar simulación'),
      );
    }

    /// A ×20, una muestra cada 0,25 s de tiempo real.
    Future<void> avanzar(WidgetTester tester, int muestras) async {
      for (var i = 0; i < muestras; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    testWidgets('la unidad avanza, lo que falta baja y al llegar sale el '
        'resultado marcado como simulado', (tester) async {
      await empezarSimulacion(tester);

      // Sin GPS: no se pide la ubicación ni su permiso, ni se abre el flujo
      // real. Sale de la salida de respaldo.
      expect(ubicacion.flujosAbiertos, 0);
      expect(ubicacion.permisosPedidos, 0);
      expect(find.text('SIMULACIÓN · NO ES EVIDENCIA'), findsOneWidget);

      // La notificación en vivo: de entrada, con el cronómetro y el color de
      // la marca.
      expect(canal.estados, isNotEmpty);
      expect(canal.estados.first.titulo, 'Simulación en curso');
      expect(canal.estados.first.fijo, isTrue);
      expect(canal.estados.first.inicio, isNotNull);
      expect(canal.estados.first.color, AppColors.primary.toARGB32());

      await avanzar(tester, 2);
      final antes = unidad(tester);
      final faltabaAntes = faltan(tester);
      await avanzar(tester, 20);
      final despues = unidad(tester);
      final faltaDespues = faltan(tester);

      expect(antes, isNotNull);
      expect(despues, isNot(antes));
      expect(faltaDespues, lessThan(faltabaAntes!));
      // 20 muestras a 50 km/h: unos 1,4 km menos.
      expect(faltabaAntes - faltaDespues!, closeTo(1389, 150));

      // Con la primera muestra se actualizó: enviadas, lo que falta y la
      // barra de progreso.
      final enVivo = canal.estados.lastWhere((e) => e.texto.contains('faltan'));
      expect(enVivo.texto, contains('enviadas'));
      expect(enVivo.progreso, isNotNull);

      // La ruta mide 5,4 km: a 50 km/h son ~78 muestras.
      await avanzar(tester, 70);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('SESIÓN SIMULADA'), findsOneWidget);
      expect(find.byType(MapaRecorrido), findsOneWidget);
      expect(repo.filas.every((f) => f['simulada'] == true), isTrue);
      expect(repo.filas.first['permiso'], 'no_aplica');
      expect(repo.filas.last['cierre'], true);
      expect(repo.recorridoSimulado, isTrue);

      // Al terminar: se quita la en vivo y queda el resumen, descartable.
      expect(canal.cierres, greaterThanOrEqualTo(1));
      final resumen = canal.estados.last;
      expect(resumen.fijo, isFalse);
      expect(resumen.titulo, 'Simulación terminada');
      expect(resumen.texto, '99 % · PASA · no es evidencia');

      // El reloj simulado: las capturas van cada 5 s aunque a ×20 llegaron
      // cada 0,25 s.
      final horas = [
        for (final f in repo.filas.where((f) => f['cierre'] == false))
          DateTime.parse(f['capturada_en']! as String),
      ];
      expect(horas[1].difference(horas[0]), const Duration(seconds: 5));

      await desmontar(tester);
    });

    testWidgets('un desvío dispara el recálculo de la ruta con OSRM', (
      tester,
    ) async {
      await empezarSimulacion(tester, desvio: true);
      expect(rutas.pedidas, hasLength(1));

      // El desvío empieza al 30 % del recorrido (~23 muestras) y dura 45 s.
      await avanzar(tester, 40);

      expect(rutas.pedidas.first.first, RutaDePrueba.porOmision.inicio);
      expect(rutas.pedidas.length, greaterThanOrEqualTo(2));
      // La ruta nueva sale de donde está la unidad y llega a la URBE.
      final nueva = rutas.pedidas[1];
      expect(nueva.last, RutaDePrueba.porOmision.llegada);
      expect(nueva.first, isNot(RutaDePrueba.porOmision.inicio));
      expect(repo.recalculos, hasLength(rutas.pedidas.length - 1));
      expect(find.textContaining('Ruta recalculada'), findsWidgets);
      // El OSRM falso devuelve siempre la misma línea: si el desvío dura más
      // de 30 s, se recalcula otra vez, pero nunca antes de 30 s.
      for (var i = 1; i < repo.recalculos.length; i++) {
        expect(
          repo.recalculos[i].difference(repo.recalculos[i - 1]),
          greaterThanOrEqualTo(const Duration(seconds: 30)),
        );
      }

      await avanzar(tester, 60);
      await desmontar(tester);
    });
  });
}
