import 'dart:async';

import 'package:cupo/features/spike_rastreo/domain/cola_de_envio.dart';
import 'package:cupo/features/spike_rastreo/domain/muestra_rastreo.dart';
import 'package:cupo/features/spike_rastreo/domain/protocolo_rastreo.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 10, 26, 14);

MuestraRastreo _muestra(int seq) => MuestraRastreo(
  seq: seq,
  lat: 10.69,
  lng: -71.63,
  capturadaEn: _t0.add(Duration(seconds: 5 * seq)),
  estadoApp: EstadoApp.paused,
  fase: FaseRastreo.minimizada,
);

/// Un envío falso que guarda cada lote y falla mientras [sinRed] sea true.
class _Envio {
  bool sinRed = false;
  final List<List<EnvioDeMuestra>> lotes = [];

  Future<void> call(List<EnvioDeMuestra> lote) async {
    if (sinRed) throw Exception('Failed host lookup');
    lotes.add(lote);
  }

  List<int> get seqs => [
    for (final lote in lotes) ...lote.map((e) => e.muestra.seq),
  ];
}

void main() {
  test('con red, cada muestra sale en su primer intento', () async {
    final envio = _Envio();
    final cola = ColaDeEnvio(enviar: envio.call);

    cola.encolar(_muestra(1));
    cola.encolar(_muestra(2));
    expect(cola.pendientes, 2);

    expect(await cola.vaciar(), isTrue);
    expect(cola.capturadas, 2);
    expect(cola.enviadas, 2);
    expect(cola.pendientes, 0);
    expect(envio.seqs, [1, 2]);
    expect(envio.lotes.single.map((e) => e.intento), [1, 1]);
  });

  test('sin red la muestra se queda con su seq y su hora de captura, y sale '
      'en el siguiente intento', () async {
    final envio = _Envio()..sinRed = true;
    final cola = ColaDeEnvio(enviar: envio.call);
    final original = _muestra(7);

    cola.encolar(original);
    expect(await cola.vaciar(), isFalse);
    expect(await cola.vaciar(), isFalse);
    expect(cola.pendientes, 1);
    expect(cola.enviadas, 0);
    expect(cola.fallos, 2);
    expect(cola.ultimoError, isA<Exception>());

    envio.sinRed = false;
    expect(await cola.vaciar(), isTrue);

    final llegada = envio.lotes.single.single;
    expect(llegada.muestra.seq, 7);
    expect(llegada.muestra.capturadaEn, original.capturadaEn);
    expect(llegada.intento, 3);
    // El error queda a la vista aunque la cola se haya puesto al día.
    expect(cola.ultimoError, isNotNull);
  });

  test('una cola larga sale por lotes y en orden', () async {
    final envio = _Envio();
    final cola = ColaDeEnvio(enviar: envio.call, tamanoLote: 2);

    for (var seq = 1; seq <= 5; seq++) {
      cola.encolar(_muestra(seq));
    }
    expect(await cola.vaciar(), isTrue);

    expect(envio.lotes.map((l) => l.length), [2, 2, 1]);
    expect(envio.seqs, [1, 2, 3, 4, 5]);
  });

  test('si un lote falla, los anteriores cuentan como enviados', () async {
    var llamadas = 0;
    final cola = ColaDeEnvio(
      tamanoLote: 2,
      enviar: (lote) async {
        llamadas++;
        if (llamadas == 2) throw Exception('timeout');
      },
    );

    for (var seq = 1; seq <= 5; seq++) {
      cola.encolar(_muestra(seq));
    }
    expect(await cola.vaciar(), isFalse);
    expect(cola.enviadas, 2);
    expect(cola.pendientes, 3);
  });

  test('no hay dos envíos a la vez y lo que llega durante uno sale en ese '
      'mismo vaciado', () async {
    final enVuelo = Completer<void>();
    final lotes = <List<int>>[];
    final cola = ColaDeEnvio(
      enviar: (lote) async {
        lotes.add([for (final e in lote) e.muestra.seq]);
        if (lotes.length == 1) await enVuelo.future;
      },
    );

    cola.encolar(_muestra(1));
    final primero = cola.vaciar();
    expect(cola.enviando, isTrue);

    cola.encolar(_muestra(2));
    expect(await cola.vaciar(), isFalse, reason: 'ya hay uno en vuelo');

    enVuelo.complete();
    expect(await primero, isTrue);
    expect(lotes, [
      [1],
      [2],
    ]);
    expect(cola.enviadas, 2);
  });
}
