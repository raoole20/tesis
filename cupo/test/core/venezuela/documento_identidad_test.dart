import 'package:cupo/core/venezuela/documento_identidad.dart';
import 'package:test/test.dart';

void main() {
  group('cédula (V)', () {
    test('acepta de 6 a 8 dígitos, con o sin puntos', () {
      expect(validarDocumento(TipoDocumento.v, '30111222'), isNull);
      expect(validarDocumento(TipoDocumento.v, '30.111.222'), isNull);
      expect(validarDocumento(TipoDocumento.v, '4567890'), isNull);
      expect(validarDocumento(TipoDocumento.v, '123456'), isNull);
    });

    test('rechaza vacía, corta, larga o en cero', () {
      expect(validarDocumento(TipoDocumento.v, ''), 'Escribe tu cédula.');
      expect(
        validarDocumento(TipoDocumento.v, '12345'),
        'La cédula está incompleta.',
      );
      expect(
        validarDocumento(TipoDocumento.v, '123456789'),
        'La cédula tiene dígitos de más.',
      );
      expect(
        validarDocumento(TipoDocumento.v, '00000000'),
        'Esa cédula no es válida.',
      );
    });

    test('se formatea con puntos de miles', () {
      expect(formatearDocumento(TipoDocumento.v, '30111222'), '30.111.222');
      expect(formatearDocumento(TipoDocumento.v, '4567890'), '4.567.890');
      expect(formatearDocumento(TipoDocumento.v, '301'), '301');
      expect(formatearDocumento(TipoDocumento.v, '3011'), '3.011');
      expect(formatearDocumento(TipoDocumento.v, ''), '');
    });

    test('se guarda sin puntos y con la letra', () {
      expect(normalizarDocumento(TipoDocumento.v, '30.111.222'), 'V-30111222');
    });
  });

  group('RIF (J)', () {
    // RIF públicos de empresas venezolanas, con su verificador real.
    const bancoDeVenezuela = '000029610';
    const cerveceriaPolar = '000063729';

    test('el verificador sale del módulo 11 del SENIAT', () {
      expect(digitoVerificadorRif(TipoDocumento.j, '00002961'), 0);
      expect(digitoVerificadorRif(TipoDocumento.j, '00006372'), 9);
    });

    test('acepta un RIF con el verificador correcto', () {
      expect(validarDocumento(TipoDocumento.j, bancoDeVenezuela), isNull);
      expect(validarDocumento(TipoDocumento.j, '00006372-9'), isNull);
    });

    test('rechaza un verificador equivocado o un largo distinto de 9', () {
      expect(
        validarDocumento(TipoDocumento.j, '000063721'),
        'Ese RIF no es válido. Revisa el último dígito.',
      );
      expect(
        validarDocumento(TipoDocumento.j, '00006372'),
        'El RIF lleva 9 dígitos: 8 del número y el verificador.',
      );
      expect(
        validarDocumento(TipoDocumento.j, ''),
        'Escribe el RIF de la empresa.',
      );
    });

    test('se formatea y se guarda con guion antes del verificador', () {
      expect(formatearDocumento(TipoDocumento.j, '0000636'), '0000636');
      expect(
        formatearDocumento(TipoDocumento.j, cerveceriaPolar),
        '00006372-9',
      );
      expect(
        normalizarDocumento(TipoDocumento.j, cerveceriaPolar),
        'J-00006372-9',
      );
    });
  });
}
