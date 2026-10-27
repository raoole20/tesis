/// La semana de servicio del conductor y lo que le deben, para el prototipo
/// de las pestañas «Semana» y «Cuentas».
///
/// **Son datos de ejemplo**, igual que [TurnoDelConductor.ejemplo], y cuadran
/// con él: los ids de pasajero son los mismos, el lunes es el «hoy» de ese
/// turno y la suma de los saldos es su `porCobrar`. Las tablas de turnos,
/// asistencias y cobros llegan con la Iteración 2.
library;

import 'turno_del_conductor.dart';

/// Un día con servicio y cómo viene la asistencia.
class DiaDeServicio {
  const DiaDeServicio({
    required this.dia,
    required this.fecha,
    required this.van,
    required this.sinConfirmar,
    required this.noVan,
    this.esHoy = false,
  });

  /// «Lunes».
  final String dia;

  /// «12 oct».
  final String fecha;

  final int van;
  final int sinConfirmar;
  final int noVan;
  final bool esHoy;

  int get inscritos => van + sinConfirmar + noVan;
}

class SemanaDelConductor {
  const SemanaDelConductor({required this.rango, required this.dias});

  /// «12 al 16 de octubre».
  final String rango;
  final List<DiaDeServicio> dias;

  static const ejemplo = SemanaDelConductor(
    rango: '12 al 16 de octubre',
    dias: [
      // El lunes es el turno de ejemplo: 9 van, Josué sin confirmar y
      // María Fernanda no va.
      DiaDeServicio(
        dia: 'Lunes',
        fecha: '12 oct',
        van: 9,
        sinConfirmar: 1,
        noVan: 1,
        esHoy: true,
      ),
      DiaDeServicio(
        dia: 'Martes',
        fecha: '13 oct',
        van: 10,
        sinConfirmar: 1,
        noVan: 0,
      ),
      DiaDeServicio(
        dia: 'Miércoles',
        fecha: '14 oct',
        van: 8,
        sinConfirmar: 3,
        noVan: 0,
      ),
      DiaDeServicio(
        dia: 'Jueves',
        fecha: '15 oct',
        van: 7,
        sinConfirmar: 3,
        noVan: 1,
      ),
      DiaDeServicio(
        dia: 'Viernes',
        fecha: '16 oct',
        van: 6,
        sinConfirmar: 5,
        noVan: 0,
      ),
    ],
  );
}

/// Lo que debe un pasajero de la nómina esta semana.
class SaldoDePasajero {
  const SaldoDePasajero({
    required this.idPasajero,
    required this.monto,
    required this.pagado,
    required this.detalle,
  });

  /// El mismo id de [PasajeroDelDia.id].
  final String idPasajero;

  /// En dólares.
  final double monto;
  final bool pagado;

  /// «5 viajes · pagó por pago móvil».
  final String detalle;
}

class CuentasDelConductor {
  const CuentasDelConductor({
    required this.cierre,
    required this.precioSemanal,
    required this.saldos,
  });

  /// Qué día se liquida: «viernes 16 de octubre».
  final String cierre;
  final double precioSemanal;
  final List<SaldoDePasajero> saldos;

  /// Los saldos con el pasajero de [turno] al que pertenecen.
  static List<(PasajeroDelDia, SaldoDePasajero)> conPasajeros(
    TurnoDelConductor turno,
    List<SaldoDePasajero> saldos,
  ) {
    final porId = {for (final p in turno.pasajeros) p.id: p};
    return [
      for (final s in saldos)
        if (porId[s.idPasajero] case final pasajero?) (pasajero, s),
    ];
  }

  // 5 viajes a $1,10. Siete pendientes suman los $38,50 del turno.
  static const ejemplo = CuentasDelConductor(
    cierre: 'viernes 16 de octubre',
    precioSemanal: 5.5,
    saldos: [
      SaldoDePasajero(
        idPasajero: 'p1',
        monto: 5.5,
        pagado: true,
        detalle: 'Pagó por pago móvil',
      ),
      SaldoDePasajero(
        idPasajero: 'p2',
        monto: 5.5,
        pagado: false,
        detalle: '5 viajes esta semana',
      ),
      SaldoDePasajero(
        idPasajero: 'p3',
        monto: 5.5,
        pagado: true,
        detalle: 'Pagó en efectivo',
      ),
      SaldoDePasajero(
        idPasajero: 'p4',
        monto: 5.5,
        pagado: false,
        detalle: '5 viajes esta semana',
      ),
      SaldoDePasajero(
        idPasajero: 'p5',
        monto: 5.5,
        pagado: false,
        detalle: '5 viajes esta semana',
      ),
      SaldoDePasajero(
        idPasajero: 'p6',
        monto: 5.5,
        pagado: false,
        detalle: '5 viajes esta semana',
      ),
      SaldoDePasajero(
        idPasajero: 'p7',
        monto: 5.5,
        pagado: true,
        detalle: 'Pagó por pago móvil',
      ),
      SaldoDePasajero(
        idPasajero: 'p8',
        monto: 5.5,
        pagado: false,
        detalle: '5 viajes esta semana',
      ),
      SaldoDePasajero(
        idPasajero: 'p9',
        monto: 5.5,
        pagado: false,
        detalle: '5 viajes esta semana',
      ),
      SaldoDePasajero(
        idPasajero: 'p10',
        monto: 5.5,
        pagado: true,
        detalle: 'Pagó por transferencia',
      ),
      SaldoDePasajero(
        idPasajero: 'p11',
        monto: 5.5,
        pagado: false,
        detalle: '5 viajes esta semana',
      ),
    ],
  );
}
