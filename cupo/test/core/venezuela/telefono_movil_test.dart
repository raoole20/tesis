import 'package:cupo/core/venezuela/telefono_movil.dart';
import 'package:test/test.dart';

void main() {
  test('están las seis operadoras móviles', () {
    expect(OperadoraMovil.values.map((o) => o.codigo), [
      '0412',
      '0414',
      '0416',
      '0422',
      '0424',
      '0426',
    ]);
  });

  group('validarTelefono', () {
    test('acepta 7 dígitos con operadora elegida', () {
      expect(validarTelefono(OperadoraMovil.o424, '1234567'), isNull);
      expect(validarTelefono(OperadoraMovil.o424, '123 4567'), isNull);
    });

    test('pide la operadora antes que el número', () {
      expect(
        validarTelefono(null, '1234567'),
        'Elige el código de tu operadora.',
      );
    });

    test('rechaza un número vacío o de largo distinto de 7', () {
      expect(validarTelefono(OperadoraMovil.o414, ''), 'Escribe tu teléfono.');
      expect(
        validarTelefono(OperadoraMovil.o414, '123456'),
        'Después del 0414 van 7 dígitos.',
      );
    });
  });

  test('se formatea como «123 4567»', () {
    expect(formatearTelefono('1234567'), '123 4567');
    expect(formatearTelefono('123'), '123');
    expect(formatearTelefono('1234'), '123 4');
  });

  test('se guarda en E.164, como lo entiende WhatsApp', () {
    expect(
      normalizarTelefono(OperadoraMovil.o414, '123 4567'),
      '+584141234567',
    );
    expect(normalizarTelefono(OperadoraMovil.o422, '7654321'), '+584227654321');
  });

  group('separarTelefono', () {
    test('reconoce el número entero, nacional o con +58', () {
      expect(separarTelefono('0414 123 4567'), (
        OperadoraMovil.o414,
        '1234567',
      ));
      expect(separarTelefono('+58 426-765-4321'), (
        OperadoraMovil.o426,
        '7654321',
      ));
    });

    test('devuelve null si no es un móvil completo', () {
      expect(separarTelefono('1234567'), isNull);
      expect(separarTelefono('02617654321'), isNull);
    });
  });
}
