/// Rol de una cuenta. Espejo del tipo `rol_usuario` de PostgreSQL.
///
/// El enum de Dart y el `create type` de la migración tienen que decir lo
/// mismo. Si se agrega un rol en la base, se agrega aquí, y al revés.
enum RolUsuario {
  estudiante('estudiante'),
  conductor('conductor'),
  administrador('administrador');

  const RolUsuario(this.valor);

  /// El texto exacto que viaja a la base de datos. No se deduce de [name]
  /// para que un renombre en Dart no rompa la consulta en silencio.
  final String valor;

  /// Convierte el texto que devuelve PostgreSQL en un [RolUsuario].
  ///
  /// Un rol desconocido es un error de programación —el enum de la base no
  /// permite otros valores—, así que revienta en vez de adivinar.
  static RolUsuario desde(String valor) {
    for (final rol in RolUsuario.values) {
      if (rol.valor == valor) return rol;
    }
    throw ArgumentError.value(valor, 'valor', 'Rol desconocido');
  }

  bool get esEstudiante => this == RolUsuario.estudiante;
  bool get esConductor => this == RolUsuario.conductor;
  bool get esAdministrador => this == RolUsuario.administrador;
}
