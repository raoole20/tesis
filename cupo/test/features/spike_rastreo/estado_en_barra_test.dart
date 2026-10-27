import 'package:cupo/features/spike_rastreo/domain/estado_en_barra.dart';
import 'package:cupo/features/spike_rastreo/domain/muestra_rastreo.dart';
import 'package:cupo/features/spike_rastreo/domain/protocolo_rastreo.dart';
import 'package:flutter_test/flutter_test.dart';

EstadoEnBarra _recorrido({
  bool simulada = false,
  int enviadas = 128,
  int pendientes = 0,
  bool sinRed = false,
  int segundos = 5,
  double? restante = 3200,
  double? recorrido = 2200,
}) => estadoEnBarra(
  modo: ModoPrueba.recorrido,
  simulada: simulada,
  buscandoGps: false,
  enviadas: enviadas,
  pendientes: pendientes,
  sinRed: sinRed,
  desdeUltima: Duration(seconds: segundos),
  restanteM: restante,
  recorridoM: recorrido,
);

void main() {
  group('títulos por modo', () {
    test('recorrido real, simulación y fases', () {
      expect(_recorrido().titulo, 'Recorrido a la URBE en curso');
      expect(_recorrido(simulada: true).titulo, 'Simulación en curso');
      expect(
        estadoEnBarra(
          modo: ModoPrueba.fases,
          simulada: false,
          buscandoGps: false,
          enviadas: 0,
          pendientes: 0,
          sinRed: false,
        ).titulo,
        'Prueba de rastreo en curso',
      );
    });
  });

  test('el recorrido dice lo enviado, lo pendiente, la última y lo que '
      'falta', () {
    final e = _recorrido();
    expect(
      e.texto,
      '128 enviadas · 0 pendientes · última hace 5 s · faltan 3,2 km',
    );
    expect(e.corto, '● 128 · 3,2 km');
  });

  test('la barra del recorrido es lo recorrido sobre el total', () {
    // 2,2 km hechos de 5,4: 407 de 1000.
    expect(_recorrido().progreso, 407);
    expect(_recorrido(restante: 0).progreso, 1000);
    expect(_recorrido(restante: null).progreso, isNull);
  });

  test('pendientes sin red se notan', () {
    expect(
      _recorrido(pendientes: 6, sinRed: true).texto,
      '128 enviadas · ⚠ 6 pendientes, sin conexión · última hace 5 s · '
      'faltan 3,2 km',
    );
    // Pendientes en vuelo, pero con red: sin alarma.
    expect(_recorrido(pendientes: 1).texto, contains('1 pendientes'));
    expect(_recorrido(pendientes: 1).texto, isNot(contains('⚠')));
  });

  group('sin ubicación', () {
    test('hasta 30 s es normal', () {
      final e = _recorrido(segundos: 30);
      expect(e.texto, contains('última hace 30 s'));
      expect(e.texto, isNot(contains('Sin ubicación')));
      expect(e.corto, startsWith('●'));
    });

    test('pasados 30 s lo dice primero, y en minutos desde los 2', () {
      final e = _recorrido(segundos: 45);
      expect(e.texto, startsWith('Sin ubicación hace 45 s · 128 enviadas'));
      expect(e.texto, isNot(contains('última hace')));
      expect(e.corto, startsWith('○'));
      expect(
        _recorrido(segundos: 185).texto,
        startsWith('Sin ubicación hace 3 min'),
      );
      expect(umbralSinUbicacion, const Duration(seconds: 30));
    });
  });

  test('en fases dice la fase, qué hacer, y la barra es el avance', () {
    final e = estadoEnBarra(
      modo: ModoPrueba.fases,
      simulada: false,
      buscandoGps: false,
      enviadas: 130,
      pendientes: 0,
      sinRed: false,
      fase: FaseRastreo.minimizada,
      desdeUltima: const Duration(seconds: 4),
      avanceFases: 0.5,
    );
    expect(
      e.texto,
      'Fase 2 de 3 · minimiza la app · 130 enviadas · 0 pendientes · '
      'última hace 4 s',
    );
    expect(e.progreso, 500);
    expect(e.texto, isNot(contains('faltan')));
  });

  test('antes de la primera ubicación: buscando GPS', () {
    final e = estadoEnBarra(
      modo: ModoPrueba.recorrido,
      simulada: false,
      buscandoGps: true,
      enviadas: 0,
      pendientes: 0,
      sinRed: false,
    );
    expect(e.texto, 'Buscando señal GPS…');
    expect(e.progreso, isNull);
  });

  group('resumen final', () {
    test('cobertura y veredicto', () {
      expect(
        resumenEnBarra(simulada: false, coberturaPct: 96, pasa: true).texto,
        '96 % · PASA',
      );
      expect(
        resumenEnBarra(simulada: false, coberturaPct: 87.14, pasa: false).texto,
        '87,1 % · NO PASA',
      );
      expect(
        resumenEnBarra(simulada: false, coberturaPct: 50).texto,
        '50 % · resultado parcial',
      );
      expect(
        resumenEnBarra(simulada: false).texto,
        'Abre Cupo para ver el resultado',
      );
    });

    test('la simulación lo aclara', () {
      final r = resumenEnBarra(simulada: true, coberturaPct: 99, pasa: true);
      expect(r.titulo, 'Simulación terminada');
      expect(r.texto, '99 % · PASA · no es evidencia');
    });
  });

  test('distanciaCorta', () {
    expect(distanciaCorta(3240), '3,2 km');
    expect(distanciaCorta(3000), '3 km');
    expect(distanciaCorta(820.4), '820 m');
  });
}
