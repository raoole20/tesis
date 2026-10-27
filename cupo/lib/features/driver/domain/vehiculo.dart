/// Una fila de `public.vehiculos` (HU-004).
class Vehiculo {
  const Vehiculo({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.capacidad,
    this.anio,
  });

  final String id;

  /// Normalizada: mayúsculas, sin espacios ni guiones (`AB123CD`).
  final String placa;
  final String marca;
  final String modelo;
  final String color;

  /// Asientos para pasajeros. Limita los cupos de los turnos que la usan.
  final int capacidad;
  final int? anio;

  factory Vehiculo.fromMap(Map<String, dynamic> map) {
    return Vehiculo(
      id: map['id'] as String,
      placa: map['placa'] as String,
      marca: map['marca'] as String,
      modelo: map['modelo'] as String,
      color: map['color'] as String,
      capacidad: (map['capacidad'] as num).toInt(),
      anio: (map['anio'] as num?)?.toInt(),
    );
  }

  /// «Toyota Hiace 2015».
  String get nombre => [marca, modelo, ?anio?.toString()].join(' ');

  /// «AB123CD · Blanca · 14 puestos».
  String get detalle =>
      '$placa · $color · $capacidad ${capacidad == 1 ? 'puesto' : 'puestos'}';
}

/// Lo que el conductor llena en el formulario, listo para guardarse.
class VehiculoBorrador {
  const VehiculoBorrador({
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.capacidad,
    this.anio,
  });

  final String placa;
  final String marca;
  final String modelo;
  final String color;
  final int capacidad;
  final int? anio;

  /// Las columnas que el grant deja escribir. `conductor_id` no va: lo pone
  /// el default `auth.uid()` de la tabla.
  Map<String, dynamic> toMap() => {
    'placa': placa,
    'marca': marca,
    'modelo': modelo,
    'anio': anio,
    'color': color,
    'capacidad': capacidad,
  };
}

/// Reglas del formulario. Repiten las restricciones `check` de la tabla para
/// avisar antes de ir al servidor; la última palabra la tiene la base.
abstract final class ReglasVehiculo {
  static const int capacidadMinima = 1;

  /// Un autobús escolar grande. La base no pone tope; la app sí, para que el
  /// selector no crezca sin fin.
  static const int capacidadMaxima = 45;

  static const int capacidadInicial = 4;

  static const int anioMinimo = 1970;

  /// «ab-123 cd» → «AB123CD».
  static String normalizarPlaca(String texto) =>
      texto.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  static String? validarPlaca(String texto) {
    final placa = normalizarPlaca(texto);
    if (placa.isEmpty) return 'Escribe la placa.';
    if (placa.length < 6 || placa.length > 7) {
      return 'La placa lleva 6 o 7 letras y números, como AB123CD.';
    }
    return null;
  }

  /// El año es opcional: vacío es válido.
  static String? validarAnio(String texto, {required int anioActual}) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return null;
    final anio = int.tryParse(limpio);
    if (anio == null || anio < anioMinimo || anio > anioActual + 1) {
      return 'Escribe un año entre $anioMinimo y ${anioActual + 1}.';
    }
    return null;
  }
}
