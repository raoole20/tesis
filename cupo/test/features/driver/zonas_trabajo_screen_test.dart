import 'package:cupo/features/auth/data/auth_repository.dart';
import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:cupo/features/driver/data/zonas_repository.dart';
import 'package:cupo/features/driver/domain/zona.dart';
import 'package:cupo/features/driver/presentation/zonas_trabajo_screen.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../soporte/banco_de_pruebas.dart';

/// Repositorio en memoria: sin Supabase, y deja ver qué se guardó.
class _ZonasFalsas extends ZonasRepository {
  _ZonasFalsas({
    this.zonas = const [],
    this.mias = const {},
    this.fallaAlCargar = false,
  });

  final List<Zona> zonas;
  final Set<String> mias;
  final bool fallaAlCargar;

  Set<String>? guardadas;

  @override
  Future<List<Zona>> catalogo() async {
    if (fallaAlCargar) throw const ZonasFallo('No hay conexión.');
    return zonas;
  }

  @override
  Future<Set<String>> misZonas() async => mias;

  @override
  Future<void> guardarMisZonas(Set<String> ids) async {
    guardadas = {...ids};
  }
}

/// Solo registra que se pidió cerrar el onboarding.
class _AuthFalso extends AuthRepository {
  bool onboardingCompletado = false;

  @override
  Future<void> completarOnboarding() async => onboardingCompletado = true;
}

const _delicias = Zona(
  id: 'z1',
  nombre: 'Las Delicias',
  municipio: 'Maracaibo',
);
const _pomona = Zona(id: 'z2', nombre: 'Pomona', municipio: 'Maracaibo');
// Se solapa con Las Delicias entre las longitudes -71.625 y -71.610.
const _cincoDeJulio = Zona(
  id: 'z4',
  nombre: '5 de Julio',
  municipio: 'Maracaibo',
);
const _sanFrancisco = Zona(
  id: 'z3',
  nombre: 'San Francisco',
  municipio: 'San Francisco',
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> montar(
    WidgetTester tester,
    ZonasRepository repo, {
    AuthRepository? auth,
    MapController? mapa,
  }) async {
    await montarPantalla(
      tester,
      ZonasTrabajoScreen(repositorio: repo, controladorMapa: mapa),
      usuario: usuarioDePrueba(rol: RolUsuario.conductor),
      repositorio: auth,
    );
    await tester.pump();
  }

  CupoPrimaryButton boton(WidgetTester tester) =>
      tester.widget<CupoPrimaryButton>(find.byType(CupoPrimaryButton));

  testWidgets('lista el catálogo con el mapa y sin nada elegido', (
    tester,
  ) async {
    await montar(
      tester,
      _ZonasFalsas(zonas: const [_delicias, _pomona, _sanFrancisco]),
    );

    expect(find.text('Tus zonas de trabajo'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(CupoCheckTile), findsNWidgets(3));
    expect(find.text('Elige al menos una zona.'), findsOneWidget);
    expect(boton(tester).onPressed, isNull);
  });

  testWidgets('elegir zonas habilita el guardado y cuenta las elegidas', (
    tester,
  ) async {
    await montar(tester, _ZonasFalsas(zonas: const [_delicias, _pomona]));

    await tester.tap(find.text('Las Delicias'));
    await tester.pump();
    expect(find.text('1 zona elegida'), findsOneWidget);
    expect(boton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Pomona'));
    await tester.pump();
    expect(find.text('2 zonas elegidas'), findsOneWidget);

    // Volver a tocar la quita.
    await tester.tap(find.text('Pomona'));
    await tester.pump();
    expect(find.text('1 zona elegida'), findsOneWidget);
  });

  testWidgets('guardar deja las zonas elegidas y cierra el onboarding', (
    tester,
  ) async {
    final zonas = _ZonasFalsas(
      zonas: const [_delicias, _pomona, _sanFrancisco],
    );
    final auth = _AuthFalso();
    await montar(tester, zonas, auth: auth);

    await tester.tap(find.text('Las Delicias'));
    await tester.pump();
    await tester.tap(find.text('San Francisco').last);
    await tester.pump();
    await tester.tap(find.byType(CupoPrimaryButton));
    await tester.pump();

    expect(zonas.guardadas, {'z1', 'z3'});
    expect(auth.onboardingCompletado, isTrue);
  });

  testWidgets('preselecciona las que ya tenía, si siguen en el catálogo', (
    tester,
  ) async {
    await montar(
      tester,
      _ZonasFalsas(zonas: const [_delicias, _pomona], mias: {'z2', 'z9'}),
    );

    final pomona = tester.widget<CupoCheckTile>(
      find.widgetWithText(CupoCheckTile, 'Pomona'),
    );
    expect(pomona.seleccionado, isTrue);
    expect(find.text('1 zona elegida'), findsOneWidget);
  });

  testWidgets('si el catálogo no carga, avisa y ofrece reintentar', (
    tester,
  ) async {
    await montar(tester, _ZonasFalsas(fallaAlCargar: true));

    expect(find.text('No hay conexión.'), findsOneWidget);
    expect(
      find.widgetWithText(CupoSecondaryButton, 'Reintentar'),
      findsOneWidget,
    );
  });

  testWidgets('con el catálogo vacío lo dice en vez de quedar en blanco', (
    tester,
  ) async {
    await montar(tester, _ZonasFalsas());

    expect(find.textContaining('Todavía no hay zonas'), findsOneWidget);
    expect(boton(tester).onPressed, isNull);
  });

  group('mapa', () {
    /// Toca el mapa en la coordenada [punto].
    Future<void> tocarEn(
      WidgetTester tester,
      MapController mapa,
      LatLng punto,
    ) async {
      final origen = tester.getTopLeft(find.byType(FlutterMap));
      await tester.tapAt(origen + mapa.camera.latLngToScreenOffset(punto));
      await tester.pumpAndSettle();
    }

    CupoCheckTile fila(WidgetTester tester, String nombre) => tester
        .widget<CupoCheckTile>(find.widgetWithText(CupoCheckTile, nombre));

    testWidgets('se pone a pantalla completa y vuelve', (tester) async {
      await montar(tester, _ZonasFalsas(zonas: const [_delicias, _pomona]));

      await tester.tap(find.byTooltip('Ver mapa completo'));
      await tester.pumpAndSettle();

      expect(find.text('Tus zonas de trabajo'), findsNothing);
      expect(find.byType(CupoCheckTile), findsNothing);
      expect(find.byType(CupoPrimaryButton), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsNothing);

      await tester.tap(find.byTooltip('Achicar el mapa'));
      await tester.pumpAndSettle();

      expect(find.text('Tus zonas de trabajo'), findsOneWidget);
      expect(find.byType(CupoCheckTile), findsNWidgets(2));
    });

    testWidgets('«atrás» con el mapa completo lo achica', (tester) async {
      await montar(tester, _ZonasFalsas(zonas: const [_delicias]));

      await tester.tap(find.byTooltip('Ver mapa completo'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Tus zonas de trabajo'), findsOneWidget);
    });

    testWidgets('tocar una zona en el mapa la marca y la desmarca', (
      tester,
    ) async {
      final mapa = MapController();
      await montar(
        tester,
        _ZonasFalsas(zonas: const [_delicias, _pomona]),
        mapa: mapa,
      );

      // Dentro de Las Delicias y fuera de toda otra zona.
      const punto = LatLng(10.6575, -71.635);

      await tocarEn(tester, mapa, punto);
      expect(fila(tester, 'Las Delicias').seleccionado, isTrue);
      expect(find.text('1 zona elegida'), findsOneWidget);

      await tocarEn(tester, mapa, punto);
      expect(fila(tester, 'Las Delicias').seleccionado, isFalse);
    });

    testWidgets('donde dos zonas se solapan, pregunta cuál', (tester) async {
      final mapa = MapController();
      await montar(
        tester,
        _ZonasFalsas(zonas: const [_delicias, _cincoDeJulio]),
        mapa: mapa,
      );

      await tocarEn(tester, mapa, const LatLng(10.6575, -71.6175));

      expect(find.text('Aquí se cruzan varias zonas'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('5 de Julio'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aquí se cruzan varias zonas'), findsNothing);
      expect(fila(tester, '5 de Julio').seleccionado, isTrue);
      expect(fila(tester, 'Las Delicias').seleccionado, isFalse);
    });
  });
}
