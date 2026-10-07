import 'package:flutter/widgets.dart';

import '../data/auth_repository.dart';
import '../domain/usuario.dart';

/// Deja el repositorio y el usuario actual al alcance de cualquier pantalla,
/// sin pasarlos de constructor en constructor.
///
/// Es un [InheritedWidget], el mecanismo que trae Flutter de fábrica para esto.
/// Cuando haga falta algo más —varios objetos compartidos, lógica de negocio
/// con notificaciones finas— entra un paquete de manejo de estado; para dos
/// valores, esto sobra y no agrega dependencias.
///
/// ```dart
/// final repo = AuthScope.de(context).repositorio;
/// ```
class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.repositorio,
    required this.usuario,
    required super.child,
  });

  final AuthRepository repositorio;

  /// La fila de `usuarios` de quien está adentro. Es `null` mientras nadie ha
  /// entrado: las pantallas del primer ingreso viven en ese caso.
  final Usuario? usuario;

  static AuthScope de(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No hay un AuthScope por encima de este widget');
    return scope!;
  }

  /// El usuario, dando por sentado que hay sesión. Solo se usa dentro de las
  /// pantallas posteriores al login, donde no puede ser `null`.
  static Usuario usuarioDe(BuildContext context) {
    final u = de(context).usuario;
    assert(u != null, 'Esta pantalla exige sesión y no hay usuario cargado');
    return u!;
  }

  @override
  bool updateShouldNotify(AuthScope anterior) =>
      anterior.usuario != usuario || anterior.repositorio != repositorio;
}
