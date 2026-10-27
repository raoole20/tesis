import 'dart:async';
import 'dart:math';

import 'package:cupo/features/spike_rastreo/domain/muestra_rastreo.dart';
import 'package:cupo/features/spike_rastreo/domain/protocolo_rastreo.dart';
import 'package:cupo/features/spike_rastreo/presentation/rastreador_de_prueba.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

/// Un banco con reloj, GPS y Supabase de mentira.
class _Banco {
  _Banco() {
    rastreador = RastreadorDePrueba(
      abrirPosiciones: (config) {
        configAbierta = config;
        return gps.stream;
      },
      enviar: (filas) async {
        if (sinRed) throw Exception('Failed host lookup');
        enviadas.addAll(filas);
      },
      estadoApp: () => estado,
      pantallaEncendida: () async => pantalla,
      reloj: () => ahora,
      azar: Random(1),
      alCambiarDeFase: (fase, _) => avisos.add(fase),
      // El tic real no corre en las pruebas: se llama a revisarReloj().
      periodoReloj: const Duration(days: 1),
    );
  }

  late final RastreadorDePrueba rastreador;
  final gps = StreamController<Position>();
  DateTime ahora = DateTime.utc(2026, 10, 26, 14);
  EstadoApp estado = EstadoApp.resumed;
  bool? pantalla = true;
  bool sinRed = false;
  ConfigPrueba? configAbierta;
  final List<Map<String, Object?>> enviadas = [];
  final List<FaseRastreo?> avisos = [];

  static const config = ConfigPrueba(
    duracion: DuracionPrueba.corta,
    wakelock: true,
    permiso: PermisoRastreo.mientrasSeUsa,
    dispositivo: 'Teléfono de prueba',
  );

  void avanzar(Duration d) => ahora = ahora.add(d);

  /// Manda una ubicación y deja correr lo asíncrono.
  Future<void> ubicacion() async {
    gps.add(
      Position(
        latitude: 10.6978,
        longitude: -71.6335,
        timestamp: ahora,
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
    await pumpEventQueue();
  }
}

void main() {
  late _Banco banco;

  setUp(() => banco = _Banco());
  tearDown(() => banco.rastreador.dispose());

  test('el reloj de las fases arranca con la primera ubicación', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    expect(r.etapa, EtapaPrueba.buscandoGps);
    expect(r.sesion, isNull);
    expect(banco.configAbierta?.wakelock, isTrue);

    banco.avanzar(const Duration(seconds: 20));
    await banco.ubicacion();

    expect(r.etapa, EtapaPrueba.enCurso);
    expect(r.sesion?.inicio, banco.ahora);
    expect(r.fase, FaseRastreo.primerPlano);
    expect(banco.avisos, [FaseRastreo.primerPlano]);
    expect(banco.enviadas.single['seq'], 1);
    expect(banco.enviadas.single['fase'], '1_primer_plano');
  });

  test('cada muestra lleva su número, su fase, el estado de la app y el de '
      'la pantalla', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    await banco.ubicacion();

    banco
      ..avanzar(const Duration(minutes: 2, seconds: 5))
      ..estado = EstadoApp.paused;
    await banco.ubicacion();

    banco
      ..avanzar(const Duration(minutes: 2))
      ..pantalla = false;
    await banco.ubicacion();

    expect(banco.enviadas.map((f) => f['seq']), [1, 2, 3]);
    expect(banco.enviadas.map((f) => f['fase']), [
      '1_primer_plano',
      '2_minimizada',
      '3_pantalla_apagada',
    ]);
    expect(banco.enviadas.map((f) => f['estado_app']), [
      'resumed',
      'paused',
      'paused',
    ]);
    expect(banco.enviadas.map((f) => f['pantalla_encendida']), [
      true,
      true,
      false,
    ]);
    expect(banco.avisos, FaseRastreo.values);
    expect(r.capturadas, 3);
    expect(r.enviadas, 3);
  });

  test('la fase cambia con el reloj aunque no lleguen ubicaciones', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    await banco.ubicacion();

    banco.avanzar(const Duration(minutes: 2));
    r.revisarReloj();
    expect(r.fase, FaseRastreo.minimizada);
    expect(banco.avisos.last, FaseRastreo.minimizada);
    expect(r.restanteEnFase, const Duration(minutes: 2));
  });

  test('al cumplirse el total la prueba termina sola, suelta el GPS y '
      'avisa', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    await banco.ubicacion();
    expect(banco.gps.hasListener, isTrue);

    banco.avanzar(const Duration(minutes: 6));
    r.revisarReloj();
    await pumpEventQueue();

    expect(r.etapa, EtapaPrueba.terminada);
    expect(banco.gps.hasListener, isFalse);
    expect(banco.avisos.last, isNull);
    expect(r.transcurrido, const Duration(minutes: 6));
  });

  test('una ubicación que llega pasado el total no se guarda', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    await banco.ubicacion();

    banco.avanzar(const Duration(minutes: 6, seconds: 1));
    await banco.ubicacion();

    expect(r.etapa, EtapaPrueba.terminada);
    expect(banco.enviadas, hasLength(1));
  });

  test('sin red, la muestra espera y sale después con su seq, su hora de '
      'captura y el intento contado', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    banco.sinRed = true;
    await banco.ubicacion();
    final capturada = banco.ahora;

    expect(r.pendientes, 1);
    expect(r.enviadas, 0);
    expect(r.errorEnvio, isNotNull);
    expect(r.errorEnvioEn, banco.ahora);

    banco
      ..sinRed = false
      ..avanzar(const Duration(seconds: 30));
    r.revisarReloj();
    await pumpEventQueue();

    expect(r.pendientes, 0);
    final fila = banco.enviadas.single;
    expect(fila['seq'], 1);
    expect(fila['capturada_en'], capturada.toIso8601String());
    expect(fila['enviada_en'], banco.ahora.toIso8601String());
    expect(fila['intentos'], 2);
  });

  test('detener corta el GPS y no acepta más muestras', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    await banco.ubicacion();

    await r.detener();
    expect(r.etapa, EtapaPrueba.detenida);
    expect(banco.gps.hasListener, isFalse);
    // Detener no es terminar: no hay aviso de fin.
    expect(banco.avisos, [FaseRastreo.primerPlano]);

    r.reiniciar();
    expect(r.etapa, EtapaPrueba.lista);
    expect(r.sesion, isNull);
  });

  test('un error del GPS queda a la vista sin cortar la prueba', () async {
    final r = banco.rastreador..iniciar(_Banco.config);
    await banco.ubicacion();

    banco.gps.addError(const LocationServiceDisabledException());
    await pumpEventQueue();

    expect(r.errorGps, 'Se apagó la ubicación del teléfono.');
    expect(r.etapa, EtapaPrueba.enCurso);
  });

  test('estadoAppDe traduce cada AppLifecycleState', () {
    expect(estadoAppDe(null), EstadoApp.resumed);
    expect(estadoAppDe(AppLifecycleState.resumed), EstadoApp.resumed);
    expect(estadoAppDe(AppLifecycleState.inactive), EstadoApp.inactive);
    expect(estadoAppDe(AppLifecycleState.paused), EstadoApp.paused);
    expect(estadoAppDe(AppLifecycleState.hidden), EstadoApp.hidden);
    expect(estadoAppDe(AppLifecycleState.detached), EstadoApp.detached);
  });
}
