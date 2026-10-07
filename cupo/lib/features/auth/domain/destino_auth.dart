/// A dónde manda la app a una persona ya autenticada.
///
/// Es el conjunto cerrado de destinos de la tabla de enrutamiento (apartado 6
/// del modelo de datos). Al ser un enum, el `switch` que lo consume no puede
/// olvidarse de un caso: el analizador avisa.
enum DestinoAuth {
  /// Formulario de perfil del rol correspondiente.
  perfilEstudiante,
  perfilConductor,

  /// «Tu registro está en revisión».
  enRevision,

  /// Motivo del rechazo, corregir y reenviar.
  rechazada,

  /// «Cuenta deshabilitada» y contacto.
  suspendida,

  /// Onboarding: poner el pin de casa.
  onboardingEstudiante,

  /// Onboarding: elegir zonas de trabajo.
  onboardingConductor,

  /// Pantallas de inicio de cada rol.
  inicioEstudiante,
  inicioConductor,
  bandejaAdministrador,
}
