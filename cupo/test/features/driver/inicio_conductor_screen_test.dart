import 'package:cupo/features/auth/domain/rol_usuario.dart';
import 'package:cupo/features/driver/data/zonas_repository.dart';
import 'package:cupo/features/driver/domain/turno_del_conductor.dart';
import 'package:cupo/features/driver/domain/zona.dart';
import 'package:cupo/features/driver/presentation/inicio_conductor_screen.dart';
import 'package:cupo/features/driver/presentation/mapa_ruta_del_dia.dart';
import 'package:cupo/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../soporte/banco_de_pruebas.dart';

class _ZonasFalsas extends ZonasRepository {
  _ZonasFalsas({this.falla = false});

  final bool falla;

  @override
  Future<List<Zona>> catalogo() async {
    if (falla) throw const ZonasFallo('No hay conexión.');
    return const [
      Zona(id: 'z1', nombre: 'Las Delicias', municipio: 'Maracaibo'),
      Zona(id: 'z2', nombre: 'Pomona', municipio: 'Maracaibo'),
    ];
  }

  @override
  Future<Set<String>> misZonas() async => {'z1'};
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const turno = TurnoDelConductor.ejemplo;

  Future<void> montar(WidgetTester tester, {bool falla = false}) async {
    await montarPantalla(
      tester,
      InicioConductorScreen(
        repositorio: _ZonasFalsas(falla: falla),
        hoy: DateTime(2026, 10, 12),
      ),
      usuario: usuarioDePrueba(rol: RolUsuario.conductor),
    );
    await tester.pump();
  }

  Future<void> tocarBoton(WidgetTester tester, String rotulo) async {
    final boton = find.widgetWithText(CupoPrimaryButton, rotulo);
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pump();
  }

  /// Toca la fila de un pasajero. Primero la lleva al centro: lo que queda
  /// detrás de la acción fija del viaje no se puede tocar.
  Future<void> tocarPasajero(WidgetTester tester, String nombre) async {
    final fila = find.text(nombre);
    await tester.scrollUntilVisible(fila, 200);
    // A media pantalla, lejos de la acción fija del pie.
    await Scrollable.ensureVisible(tester.element(fila), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(fila.hitTestable());
    await tester.pump();
  }

  testWidgets('saluda con la fecha y muestra el turno de hoy', (tester) async {
    await montar(tester);

    expect(find.text('Lunes 12 de octubre'), findsOneWidget);
    expect(find.text('Hola, Génesis'), findsOneWidget);
    expect(find.text(turno.salida), findsOneWidget);
    expect(find.text('Por salir'), findsOneWidget);
    expect(find.text('11 de 14 puestos ocupados'), findsOneWidget);
    // La acción del viaje se ve sin desplazar nada.
    expect(
      find.widgetWithText(CupoPrimaryButton, 'Empezar viaje').hitTestable(),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('2 solicitudes nuevas'), 200);
    expect(find.text('2 solicitudes nuevas'), findsOneWidget);
  });

  testWidgets('la nómina resume quién va y lista a todos', (tester) async {
    await montar(tester);

    const resumen = '9 van · 1 no va · 1 sin confirmar';
    await tester.scrollUntilVisible(find.text(resumen), 200);
    expect(find.text(resumen), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Yusmary Pirela'), 200);
    expect(find.text('Yusmary Pirela'), findsOneWidget);
  });

  testWidgets('con el viaje en curso, tocar a un pasajero lo sube', (
    tester,
  ) async {
    await montar(tester);

    await tocarBoton(tester, 'Empezar viaje');
    expect(find.text('En curso'), findsOneWidget);
    const pista = 'Toca a cada pasajero cuando se monte.';
    await tester.scrollUntilVisible(find.text(pista), 200);
    expect(find.text(pista), findsOneWidget);

    await tocarPasajero(tester, 'Génesis Materán');
    expect(find.text('A bordo'), findsOneWidget);

    // Quien no va no se puede marcar a bordo.
    await tocarPasajero(tester, 'María Fernanda Paz');
    expect(find.text('A bordo'), findsOneWidget);

    // La acción es fija: se toca sin volver arriba.
    await tocarBoton(tester, 'Terminar viaje');
    await tester.scrollUntilVisible(find.text('Terminado'), -200);
    expect(find.text('Terminado'), findsOneWidget);
  });

  testWidgets('muestra las zonas reales del conductor', (tester) async {
    await montar(tester);

    await tester.scrollUntilVisible(find.text('Tus zonas de trabajo'), 200);
    expect(find.text('Las Delicias'), findsOneWidget);
    expect(find.text('Pomona'), findsNothing);
  });

  testWidgets('si las zonas no cargan, el inicio sigue sin esa sección', (
    tester,
  ) async {
    await montar(tester, falla: true);

    await tester.scrollUntilVisible(find.text('Cerrar sesión'), 200);
    expect(find.text('Tus zonas de trabajo'), findsNothing);
  });

  group('ruta de hoy', () {
    testWidgets('el mapa ocupa todo el fondo y la hoja va encima', (
      tester,
    ) async {
      await montar(tester);

      final pantalla = tester.getSize(find.byType(Scaffold));
      final mapa = tester.getSize(find.byType(FlutterMap));
      expect(mapa.width, pantalla.width);
      // Todo el alto menos la barra inferior.
      final barra = tester.getSize(find.byType(BottomNavigationBar));
      expect(mapa.height, closeTo(pantalla.height - barra.height, 1));

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MapaRutaDelDia),
          matching: find.byType(MarcadorParada),
        ),
        findsNWidgets(turno.paradas.length),
      );
      expect(find.byTooltip('Tu unidad'), findsNothing);
    });

    testWidgets('las paradas van como pasos dentro de la hoja', (tester) async {
      await montar(tester);

      await tester.scrollUntilVisible(find.byType(PasosDeLaRuta), 200);
      expect(find.text('Ruta de hoy'), findsOneWidget);
      expect(find.text('6 paradas · llegas ${turno.llegada}'), findsOneWidget);
      expect(find.text('12:10 pm · 2 pasajeros'), findsOneWidget);

      // Tocar un paso mueve el mapa sin romper nada.
      await tester.tap(find.text('12:10 pm · 2 pasajeros'));
      await tester.pumpAndSettle();
    });

    testWidgets('con el viaje en curso se ve la unidad', (tester) async {
      await montar(tester);

      await tocarBoton(tester, 'Empezar viaje');
      await tester.pumpAndSettle();

      expect(find.byTooltip('Tu unidad'), findsOneWidget);
    });
  });
}
