import 'dart:async';
import 'dart:ui' show Color;

import 'package:geolocator/geolocator.dart';

import '../domain/simulador.dart';
import 'fuente_de_ubicacion.dart';

/// El reloj de una simulación: avanza a saltos de tiempo simulado, uno por
/// muestra. Así, a ×20, las horas de captura siguen 5 s separadas y el
/// reporte SQL mide igual que con un GPS de verdad.
class RelojSimulado {
  RelojSimulado(this.inicio);

  final DateTime inicio;
  Duration _avance = Duration.zero;

  DateTime ahora() => inicio.add(_avance);

  void avanzarA(Duration t) => _avance = t;
}

/// Una fuente de ubicación que no usa el GPS: recorre la ruta planificada
/// con [SimuladorDeRecorrido] y entrega una posición cada `intervalo /
/// multiplicador` de tiempo real (a ×20, cada 0,25 s).
///
/// No pide permisos ni levanta el servicio en primer plano: funciona en el
/// navegador y con el teléfono quieto. Al llegar al final avisa por
/// [alLlegar] y deja de emitir.
class FuenteSimulada extends FuenteDeUbicacion {
  FuenteSimulada({
    required this.simulador,
    this.multiplicador = 1,
    DateTime? inicio,
  }) : assert(multiplicador > 0),
       reloj = RelojSimulado(inicio ?? DateTime.now());

  final SimuladorDeRecorrido simulador;

  /// ×1, ×5 o ×20: cuánto más rápido que el tiempo real.
  final int multiplicador;

  final RelojSimulado reloj;

  /// Se llama una vez, después de la última muestra.
  void Function()? alLlegar;

  Timer? _timer;
  bool _llego = false;

  bool get llego => _llego;

  @override
  Future<bool> servicioActivo() async => true;

  @override
  Future<LocationPermission> permiso() async => LocationPermission.whileInUse;

  @override
  Future<LocationPermission> pedirPermiso() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> posicionActual() async =>
      _aPosicion(simulador.muestras().first);

  @override
  Stream<Position> posiciones({
    required Duration intervalo,
    required bool wakelock,
    required String tituloAviso,
    required String textoAviso,
    Color? acento,
  }) {
    final muestras = simulador.muestras();
    late final StreamController<Position> salida;
    var siguiente = 0;

    void tic() {
      if (siguiente >= muestras.length) {
        _timer?.cancel();
        if (!_llego) {
          _llego = true;
          // Un intervalo después de la última: ahí se cierra el recorrido.
          reloj.avanzarA(muestras.last.t + simulador.intervalo);
          alLlegar?.call();
        }
        return;
      }
      final m = muestras[siguiente++];
      reloj.avanzarA(m.t);
      // En el corte de señal el reloj sigue, pero no llega nada.
      if (!m.perdida) salida.add(_aPosicion(m));
    }

    salida = StreamController<Position>(
      onListen: () {
        tic();
        _timer = Timer.periodic(
          Duration(
            microseconds: simulador.intervalo.inMicroseconds ~/ multiplicador,
          ),
          (_) => tic(),
        );
      },
      // Al cancelar (terminar, detener, salir) se para el reloj y se cierra.
      onCancel: () {
        _timer?.cancel();
        unawaited(salida.close());
      },
    );
    return salida.stream;
  }

  Position _aPosicion(MuestraSimulada m) => Position(
    latitude: m.punto.lat,
    longitude: m.punto.lng,
    timestamp: reloj.inicio.add(m.t),
    accuracy: m.precisionM,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: m.rumbo,
    headingAccuracy: 5,
    speed: m.velocidadMs,
    speedAccuracy: 0.5,
  );
}
