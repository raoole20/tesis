/// Estado de una cuenta. Espejo del tipo `estado_cuenta` de PostgreSQL.
///
/// Es el campo que gobierna el login entero: de él sale a qué pantalla va la
/// persona (apartado 6 del modelo de datos). Las transiciones válidas están
/// en el diagrama del apartado 4 y las hace cumplir la base, no la app.
enum EstadoCuenta {
  /// Recién registrado: la credencial existe, el perfil no está lleno.
  perfilIncompleto('perfil_incompleto'),

  /// Perfil enviado, esperando al administrador.
  pendiente('pendiente'),

  /// Aprobada por el administrador.
  aprobada('aprobada'),

  /// Rechazada, con motivo. Puede corregir y reenviar.
  rechazada('rechazada'),

  /// Deshabilitada después de haber sido aprobada.
  suspendida('suspendida');

  const EstadoCuenta(this.valor);

  /// El texto exacto que viaja a la base de datos. Ojo: en PostgreSQL es
  /// `perfil_incompleto` (guion bajo) y en Dart `perfilIncompleto`.
  final String valor;

  static EstadoCuenta desde(String valor) {
    for (final estado in EstadoCuenta.values) {
      if (estado.valor == valor) return estado;
    }
    throw ArgumentError.value(valor, 'valor', 'Estado de cuenta desconocido');
  }
}
