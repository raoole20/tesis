import 'package:cupo/features/auth/biometria/almacen_seguro.dart';
import 'package:cupo/features/auth/biometria/autenticador_biometrico.dart';

/// Lector de huellas de mentira: responde lo que la prueba le diga.
///
/// [respuesta] es lo que pasa al poner el dedo: `true` (reconocida), `false`
/// (rechazada) o una excepción que se lanza tal cual, normalmente una
/// `LocalAuthException`.
class AutenticadorFalso implements AutenticadorBiometrico {
  AutenticadorFalso({this.hayLector = true, this.respuesta = true});

  bool hayLector;
  Object respuesta;

  /// Los motivos con que se pidió la huella, en orden.
  final pedidos = <String>[];

  @override
  Future<bool> disponible() async => hayLector;

  @override
  Future<bool> autenticar(String motivo) async {
    pedidos.add(motivo);
    final r = respuesta;
    if (r is bool) return r;
    throw r;
  }
}

/// Almacén cifrado de mentira: un mapa en memoria, a la vista de la prueba.
class AlmacenEnMemoria implements AlmacenSeguro {
  final datos = <String, String>{};

  /// Si es `true`, leer revienta, como un almacén que no se puede descifrar.
  bool fallaAlLeer = false;

  @override
  Future<String?> leer(String clave) async {
    if (fallaAlLeer) throw Exception('no se pudo descifrar');
    return datos[clave];
  }

  @override
  Future<void> escribir(String clave, String valor) async =>
      datos[clave] = valor;

  @override
  Future<void> borrar(String clave) async => datos.remove(clave);
}
