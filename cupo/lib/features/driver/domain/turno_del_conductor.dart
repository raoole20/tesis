/// El turno de hoy del conductor y su nómina, para el prototipo del inicio.
///
/// **Son datos de ejemplo.** Las tablas de la operación (unidades, rutas,
/// turnos, cupos, inscripciones y cobros) todavía no existen: llegan con la
/// Iteración 2. Mientras tanto, [TurnoDelConductor.ejemplo] cumple el mismo
/// papel que `TransportShift.mockShifts` en las pantallas del estudiante.
library;

import 'package:latlong2/latlong.dart';

/// Qué dijo el pasajero sobre el viaje de hoy.
enum AsistenciaHoy { va, noVa, sinConfirmar }

class PasajeroDelDia {
  const PasajeroDelDia({
    required this.id,
    required this.nombre,
    required this.parada,
    required this.hora,
    required this.asistencia,
  });

  final String id;
  final String nombre;

  /// Dónde lo recoge, como lo nombra la gente.
  final String parada;

  /// A qué hora pasa por esa parada: «12:14 pm».
  final String hora;

  final AsistenciaHoy asistencia;

  /// «Génesis Materán» → «GM».
  String get iniciales {
    final partes = nombre.split(' ').where((p) => p.isNotEmpty).toList();
    final primera = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return '$primera$ultima'.toUpperCase();
  }
}

/// Una parada del recorrido, en orden de recogida.
class ParadaDelTurno {
  const ParadaDelTurno({
    required this.nombre,
    required this.hora,
    required this.punto,
  });

  /// Como la nombra la gente: «C.C. Las Delicias». Es la misma cadena que
  /// [PasajeroDelDia.parada], y así se cuentan los pasajeros de cada una.
  final String nombre;
  final String hora;
  final LatLng punto;
}

class TurnoDelConductor {
  const TurnoDelConductor({
    required this.nombre,
    required this.salida,
    required this.llegada,
    required this.origen,
    required this.destino,
    required this.vehiculo,
    required this.placa,
    required this.puestosTotales,
    required this.paradas,
    required this.puntoDestino,
    required this.pasajeros,
    required this.solicitudesNuevas,
    required this.porCobrar,
    required this.pasajerosConSaldo,
  });

  /// «Turno de la tarde».
  final String nombre;
  final String salida;
  final String llegada;
  final String origen;
  final String destino;
  final String vehiculo;
  final String placa;
  final int puestosTotales;

  /// El recorrido: las paradas en orden y, al final, [puntoDestino].
  final List<ParadaDelTurno> paradas;

  /// Dónde termina el recorrido: la entrada de la universidad.
  final LatLng puntoDestino;

  /// Los inscritos en el turno, en el orden en que se recogen.
  final List<PasajeroDelDia> pasajeros;

  /// Estudiantes que pidieron un puesto y esperan respuesta.
  final int solicitudesNuevas;

  /// Lo que le deben esta semana, en dólares.
  final double porCobrar;
  final int pasajerosConSaldo;

  int get puestosOcupados => pasajeros.length;
  int get puestosLibres => puestosTotales - puestosOcupados;

  int cuantos(AsistenciaHoy asistencia) =>
      pasajeros.where((p) => p.asistencia == asistencia).length;

  /// Los inscritos que se recogen en [parada].
  List<PasajeroDelDia> pasajerosDe(ParadaDelTurno parada) =>
      pasajeros.where((p) => p.parada == parada.nombre).toList();

  /// Los puntos de la línea del recorrido, del origen al destino.
  List<LatLng> get trazado => [
    for (final parada in paradas) parada.punto,
    puntoDestino,
  ];

  static const ejemplo = TurnoDelConductor(
    nombre: 'Turno de la tarde',
    salida: '12:10 pm',
    llegada: '12:52 pm',
    origen: 'Las Delicias',
    destino: 'URBE',
    vehiculo: 'Toyota Hiace blanca',
    placa: 'AB123CD',
    puestosTotales: 14,
    // Coordenadas aproximadas, puestas a mano sobre el mapa de Maracaibo.
    // La línea une las paradas en recta: el trazado por calles llega cuando
    // se decida el motor de ruteo (DA-19).
    paradas: [
      ParadaDelTurno(
        nombre: 'Av. 5 de Julio con 3F',
        hora: '12:10 pm',
        punto: LatLng(10.6560, -71.6180),
      ),
      ParadaDelTurno(
        nombre: 'C.C. Las Delicias',
        hora: '12:16 pm',
        punto: LatLng(10.6625, -71.6290),
      ),
      ParadaDelTurno(
        nombre: 'Plaza de la República',
        hora: '12:22 pm',
        punto: LatLng(10.6700, -71.6240),
      ),
      ParadaDelTurno(
        nombre: 'Av. Delicias con 72',
        hora: '12:27 pm',
        punto: LatLng(10.6775, -71.6300),
      ),
      ParadaDelTurno(
        nombre: 'Circunvalación 2, Makro',
        hora: '12:38 pm',
        punto: LatLng(10.6880, -71.6390),
      ),
      ParadaDelTurno(
        nombre: 'Av. Guajira, Plaza para Todos',
        hora: '12:46 pm',
        punto: LatLng(10.6950, -71.6355),
      ),
    ],
    puntoDestino: LatLng(10.6978, -71.6335),
    solicitudesNuevas: 2,
    porCobrar: 38.5,
    pasajerosConSaldo: 7,
    pasajeros: [
      PasajeroDelDia(
        id: 'p1',
        nombre: 'Génesis Materán',
        parada: 'Av. 5 de Julio con 3F',
        hora: '12:10 pm',
        asistencia: AsistenciaHoy.va,
      ),
      PasajeroDelDia(
        id: 'p2',
        nombre: 'Andrés Urdaneta',
        parada: 'Av. 5 de Julio con 3F',
        hora: '12:10 pm',
        asistencia: AsistenciaHoy.va,
      ),
      PasajeroDelDia(
        id: 'p3',
        nombre: 'María Fernanda Paz',
        parada: 'C.C. Las Delicias',
        hora: '12:16 pm',
        asistencia: AsistenciaHoy.noVa,
      ),
      PasajeroDelDia(
        id: 'p4',
        nombre: 'Luis Ángel Rincón',
        parada: 'C.C. Las Delicias',
        hora: '12:16 pm',
        asistencia: AsistenciaHoy.va,
      ),
      PasajeroDelDia(
        id: 'p5',
        nombre: 'Daniela Chirinos',
        parada: 'Plaza de la República',
        hora: '12:22 pm',
        asistencia: AsistenciaHoy.va,
      ),
      PasajeroDelDia(
        id: 'p6',
        nombre: 'Josué Villalobos',
        parada: 'Plaza de la República',
        hora: '12:22 pm',
        asistencia: AsistenciaHoy.sinConfirmar,
      ),
      PasajeroDelDia(
        id: 'p7',
        nombre: 'Valentina Añez',
        parada: 'Av. Delicias con 72',
        hora: '12:27 pm',
        asistencia: AsistenciaHoy.va,
      ),
      PasajeroDelDia(
        id: 'p8',
        nombre: 'Carlos Montiel',
        parada: 'Av. Delicias con 72',
        hora: '12:27 pm',
        asistencia: AsistenciaHoy.va,
      ),
      PasajeroDelDia(
        id: 'p9',
        nombre: 'Rosángela Fuenmayor',
        parada: 'Circunvalación 2, Makro',
        hora: '12:38 pm',
        asistencia: AsistenciaHoy.va,
      ),
      PasajeroDelDia(
        id: 'p10',
        nombre: 'Kevin Bracho',
        parada: 'Circunvalación 2, Makro',
        hora: '12:38 pm',
        asistencia: AsistenciaHoy.va,
      ),
      PasajeroDelDia(
        id: 'p11',
        nombre: 'Yusmary Pirela',
        parada: 'Av. Guajira, Plaza para Todos',
        hora: '12:46 pm',
        asistencia: AsistenciaHoy.va,
      ),
    ],
  );
}
