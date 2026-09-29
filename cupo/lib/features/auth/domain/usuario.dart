import 'estado_cuenta.dart';
import 'rol_usuario.dart';

/// Una fila de `public.usuarios`.
///
/// Es el objeto que decide todo el enrutamiento después del login: Supabase
/// Auth responde *quién eres*, esta fila responde *qué puedes hacer*
/// (apartado 5 del modelo).
///
/// Inmutable: todos los campos son `final`. Para cambiar uno se crea un objeto
/// nuevo con [copyWith], porque un campo `final` no se puede reasignar.
class Usuario {
  const Usuario({
    required this.id,
    required this.email,
    required this.rol,
    required this.estado,
    required this.nombres,
    required this.apellidos,
    required this.onboardingCompleto,
    this.telefono,
    this.cedula,
    this.urlFoto,
    this.motivoRechazo,
    this.ultimoAcceso,
  });

  /// El mismo uuid de `auth.users.id`. Es lo que devuelve `auth.uid()` dentro
  /// de las políticas RLS.
  final String id;
  final String email;
  final RolUsuario rol;
  final EstadoCuenta estado;
  final String nombres;
  final String apellidos;
  final bool onboardingCompleto;

  /// Los nullables son los que la base declara sin `not null`. El `?` no es
  /// decorativo: obliga a decidir qué pasa cuando no hay dato.
  final String? telefono;
  final String? cedula;
  final String? urlFoto;

  /// Lo escribe el administrador al rechazar. Solo tiene sentido cuando
  /// [estado] es [EstadoCuenta.rechazada].
  final String? motivoRechazo;

  final DateTime? ultimoAcceso;

  /// Construye el objeto a partir del mapa que devuelve Supabase.
  ///
  /// Es un `factory` porque tiene cuerpo: lee cada clave y valida el tipo.
  /// Dart no tiene reflexión en producción, así que esta conversión se escribe
  /// a mano — no existe un cast mágico de `Map` a `Usuario`.
  ///
  /// Sobre `as String? ?? ''`: el cast declara que la clave puede faltar (y
  /// entonces vale `null`), y `??` pone el valor por defecto. Nótese que `??`
  /// **solo** se dispara ante `null`: si la columna trae cadena vacía, la
  /// cadena vacía es lo que queda.
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      email: map['email'] as String,
      rol: RolUsuario.desde(map['rol'] as String),
      estado: EstadoCuenta.desde(map['estado'] as String),
      nombres: map['nombres'] as String? ?? '',
      apellidos: map['apellidos'] as String? ?? '',
      onboardingCompleto: map['onboarding_completo'] as bool? ?? false,
      telefono: map['telefono'] as String?,
      cedula: map['cedula'] as String?,
      urlFoto: map['url_foto'] as String?,
      motivoRechazo: map['motivo_rechazo'] as String?,
      // `tryParse` devuelve null en vez de lanzar, y `?? ''` cubre el caso
      // de que la columna venga nula — que es todos los usuarios que
      // todavía no han entrado nunca.
      ultimoAcceso: DateTime.tryParse(map['ultimo_acceso'] as String? ?? ''),
    );
  }

  /// Nombre para saludar. Si el perfil aún no tiene nombre, cae al correo.
  String get nombreParaMostrar {
    final completo = '$nombres $apellidos'.trim();
    return completo.isEmpty ? email : completo;
  }

  Usuario copyWith({
    RolUsuario? rol,
    EstadoCuenta? estado,
    String? nombres,
    String? apellidos,
    bool? onboardingCompleto,
    String? telefono,
    String? cedula,
    String? urlFoto,
    String? motivoRechazo,
  }) {
    return Usuario(
      id: id,
      email: email,
      rol: rol ?? this.rol,
      estado: estado ?? this.estado,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      onboardingCompleto: onboardingCompleto ?? this.onboardingCompleto,
      telefono: telefono ?? this.telefono,
      cedula: cedula ?? this.cedula,
      urlFoto: urlFoto ?? this.urlFoto,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      ultimoAcceso: ultimoAcceso,
    );
  }

  @override
  String toString() =>
      'Usuario($id, ${rol.valor}, ${estado.valor}, '
      'onboarding: $onboardingCompleto)';
}
