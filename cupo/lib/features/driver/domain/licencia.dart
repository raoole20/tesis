/// Reglas de la licencia de conducir que pide `enviar_a_revision()`.
abstract final class ReglasLicencia {
  static String? validarNumero(String texto) {
    if (texto.trim().isEmpty) return 'Escribe el número de tu licencia.';
    return null;
  }

  /// «15/03/2027» → 15 de marzo de 2027. `null` si no es una fecha real
  /// (31/02, 00/05, texto incompleto).
  static DateTime? leerFecha(String texto) {
    final partes = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$')
        .firstMatch(texto.trim());
    if (partes == null) return null;
    final dia = int.parse(partes.group(1)!);
    final mes = int.parse(partes.group(2)!);
    final anio = int.parse(partes.group(3)!);
    final fecha = DateTime(anio, mes, dia);
    // DateTime corrige solo: 31/02 se vuelve 3 de marzo. Si cambió, no existía.
    if (fecha.year != anio || fecha.month != mes || fecha.day != dia) {
      return null;
    }
    return fecha;
  }

  /// La licencia tiene que estar vigente hoy.
  static String? validarVencimiento(String texto, {required DateTime hoy}) {
    if (texto.trim().isEmpty) return 'Escribe cuándo vence tu licencia.';
    final fecha = leerFecha(texto);
    if (fecha == null) return 'Escribe la fecha como DD/MM/AAAA.';
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    if (fecha.isBefore(soloHoy)) return 'Tu licencia está vencida.';
    return null;
  }

  /// 15 de marzo de 2027 → «15/03/2027».
  static String escribirFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';
}
