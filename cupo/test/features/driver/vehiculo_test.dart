import 'package:cupo/features/driver/domain/licencia.dart';
import 'package:cupo/features/driver/domain/vehiculo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReglasVehiculo.normalizarPlaca', () {
    test('quita espacios y guiones y pasa a mayúsculas', () {
      expect(ReglasVehiculo.normalizarPlaca('ab-123 cd'), 'AB123CD');
      expect(ReglasVehiculo.normalizarPlaca(' a1b2c3 '), 'A1B2C3');
    });
  });

  group('ReglasVehiculo.validarPlaca', () {
    test('acepta 6 y 7 caracteres, con o sin separadores', () {
      expect(ReglasVehiculo.validarPlaca('AB123CD'), isNull);
      expect(ReglasVehiculo.validarPlaca('ab-123-cd'), isNull);
      expect(ReglasVehiculo.validarPlaca('ABC12D'), isNull);
    });

    test('pide la placa si está vacía', () {
      expect(ReglasVehiculo.validarPlaca('  - '), 'Escribe la placa.');
    });

    test('rechaza longitudes que la base no admite', () {
      expect(ReglasVehiculo.validarPlaca('AB12'), isNotNull);
      expect(ReglasVehiculo.validarPlaca('AB123CDE'), isNotNull);
    });
  });

  group('ReglasVehiculo.validarAnio', () {
    test('vacío es válido porque el año es opcional', () {
      expect(ReglasVehiculo.validarAnio('', anioActual: 2026), isNull);
    });

    test('acepta desde 1970 hasta el año que viene', () {
      expect(ReglasVehiculo.validarAnio('1970', anioActual: 2026), isNull);
      expect(ReglasVehiculo.validarAnio('2027', anioActual: 2026), isNull);
    });

    test('rechaza años fuera de rango o que no son números', () {
      expect(ReglasVehiculo.validarAnio('1969', anioActual: 2026), isNotNull);
      expect(ReglasVehiculo.validarAnio('2028', anioActual: 2026), isNotNull);
      expect(ReglasVehiculo.validarAnio('abc', anioActual: 2026), isNotNull);
    });
  });

  group('Vehiculo', () {
    const hiace = Vehiculo(
      id: 'v1',
      placa: 'AB123CD',
      marca: 'Toyota',
      modelo: 'Hiace',
      color: 'Blanca',
      capacidad: 14,
      anio: 2015,
    );

    test('arma el nombre y el detalle para mostrar', () {
      expect(hiace.nombre, 'Toyota Hiace 2015');
      expect(hiace.detalle, 'AB123CD · Blanca · 14 puestos');
    });

    test('sin año, el nombre no deja hueco; un puesto va en singular', () {
      const carro = Vehiculo(
        id: 'v2',
        placa: 'ABC12D',
        marca: 'Chevrolet',
        modelo: 'Aveo',
        color: 'Gris',
        capacidad: 1,
      );
      expect(carro.nombre, 'Chevrolet Aveo');
      expect(carro.detalle, endsWith('1 puesto'));
    });

    test('lee la fila de Supabase', () {
      final leido = Vehiculo.fromMap({
        'id': 'v1',
        'placa': 'AB123CD',
        'marca': 'Toyota',
        'modelo': 'Hiace',
        'anio': 2015,
        'color': 'Blanca',
        'capacidad': 14,
      });
      expect(leido.nombre, hiace.nombre);
      expect(leido.capacidad, 14);
    });

    test('el borrador no manda conductor_id: lo pone la base', () {
      const borrador = VehiculoBorrador(
        placa: 'AB123CD',
        marca: 'Toyota',
        modelo: 'Hiace',
        color: 'Blanca',
        capacidad: 14,
      );
      expect(borrador.toMap().containsKey('conductor_id'), isFalse);
    });
  });

  group('ReglasLicencia', () {
    final hoy = DateTime(2026, 10, 26);

    test('lee fechas reales y rechaza las que no existen', () {
      expect(ReglasLicencia.leerFecha('15/03/2027'), DateTime(2027, 3, 15));
      expect(ReglasLicencia.leerFecha('31/02/2027'), isNull);
      expect(ReglasLicencia.leerFecha('00/05/2027'), isNull);
      expect(ReglasLicencia.leerFecha('15/03/27'), isNull);
    });

    test('la licencia que vence hoy todavía es vigente', () {
      expect(ReglasLicencia.validarVencimiento('26/10/2026', hoy: hoy), isNull);
    });

    test('rechaza la licencia vencida y la fecha mal escrita', () {
      expect(
        ReglasLicencia.validarVencimiento('25/10/2026', hoy: hoy),
        'Tu licencia está vencida.',
      );
      expect(
        ReglasLicencia.validarVencimiento('2027-03-15', hoy: hoy),
        'Escribe la fecha como DD/MM/AAAA.',
      );
    });

    test('escribe la fecha como la lee', () {
      final fecha = DateTime(2027, 3, 5);
      expect(ReglasLicencia.escribirFecha(fecha), '05/03/2027');
      expect(
        ReglasLicencia.leerFecha(ReglasLicencia.escribirFecha(fecha)),
        fecha,
      );
    });
  });
}
