/// No se pudo llegar al servidor (sin conexión, DNS, CORS, conexión
/// cortada). El texto es técnico: quien lo atrapa lo redacta.
class SinRed implements Exception {
  const SinRed(this.detalle);

  final String detalle;

  @override
  String toString() => 'SinRed: $detalle';
}
