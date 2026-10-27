import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lo único que [ServicioHuella] necesita del almacenamiento cifrado.
///
/// Interfaz por la misma razón que el autenticador: en las pruebas es un
/// mapa en memoria.
abstract interface class AlmacenSeguro {
  Future<String?> leer(String clave);
  Future<void> escribir(String clave, String valor);
  Future<void> borrar(String clave);
}

/// La implementación real, sobre `flutter_secure_storage`.
///
/// En Android cifra con AES-GCM y guarda la llave envuelta por el Keystore
/// del sistema (las opciones por defecto de la versión 11, que reemplazan a
/// las `encryptedSharedPreferences` de antes). La llave no sale del
/// teléfono: por eso el manifiesto apaga el respaldo automático, que de otro
/// modo copiaría a Google Drive datos que en otro teléfono no se pueden
/// descifrar.
class AlmacenSeguroDelSistema implements AlmacenSeguro {
  AlmacenSeguroDelSistema({FlutterSecureStorage? almacen})
    : _almacen =
          almacen ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(storageNamespace: 'cupo_huella'),
          );

  final FlutterSecureStorage _almacen;

  @override
  Future<String?> leer(String clave) => _almacen.read(key: clave);

  @override
  Future<void> escribir(String clave, String valor) =>
      _almacen.write(key: clave, value: valor);

  @override
  Future<void> borrar(String clave) => _almacen.delete(key: clave);
}
