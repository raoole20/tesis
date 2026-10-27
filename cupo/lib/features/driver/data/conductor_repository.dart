import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/vehiculo.dart';

/// Error al leer o guardar datos del conductor, ya redactado para mostrarse.
class ConductorFallo implements Exception {
  const ConductorFallo(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Licencia del conductor (`public.conductores`) y sus vehículos
/// (`public.vehiculos`).
///
/// Igual que `ZonasRepository`, el cliente se resuelve al usarlo y no al
/// construir, para que las pruebas de widget puedan pasar una subclase falsa
/// sin levantar Supabase.
class ConductorRepository {
  ConductorRepository({SupabaseClient? cliente}) : _inyectado = cliente;

  final SupabaseClient? _inyectado;

  SupabaseClient get _db => _inyectado ?? Supabase.instance.client;

  /// El vehículo del conductor, o `null` si todavía no registra ninguno.
  ///
  /// La tabla admite varios por conductor; mientras la app maneje uno solo,
  /// se toma el primero que registró.
  Future<Vehiculo?> miVehiculo() async {
    final id = _idActual();
    try {
      final fila = await _db
          .from('vehiculos')
          .select('id, placa, marca, modelo, anio, color, capacidad')
          .eq('conductor_id', id)
          .order('creado_en')
          .limit(1)
          .maybeSingle();
      return fila == null ? null : Vehiculo.fromMap(fila);
    } on PostgrestException catch (e) {
      throw ConductorFallo(_traducir(e));
    }
  }

  /// Registra el vehículo, o lo actualiza si se pasa [id].
  Future<Vehiculo> guardarVehiculo(VehiculoBorrador borrador, {String? id}) {
    return _correr(() async {
      final consulta = id == null
          ? _db.from('vehiculos').insert(borrador.toMap())
          : _db.from('vehiculos').update(borrador.toMap()).eq('id', id);
      final fila = await consulta
          .select('id, placa, marca, modelo, anio, color, capacidad')
          .single();
      return Vehiculo.fromMap(fila);
    });
  }

  /// La licencia ya guardada, para precargar el formulario al reenviar.
  Future<({String? numero, DateTime? venceEn})> miLicencia() async {
    final id = _idActual();
    try {
      final fila = await _db
          .from('conductores')
          .select('licencia_numero, licencia_vence_en')
          .eq('id', id)
          .maybeSingle();
      return (
        numero: fila?['licencia_numero'] as String?,
        venceEn: DateTime.tryParse(fila?['licencia_vence_en'] as String? ?? ''),
      );
    } on PostgrestException catch (e) {
      throw ConductorFallo(_traducir(e));
    }
  }

  /// Número y vencimiento de la licencia, que exige `enviar_a_revision()`.
  Future<void> guardarLicencia({
    required String numero,
    required DateTime venceEn,
  }) {
    final id = _idActual();
    return _correr(() async {
      await _db
          .from('conductores')
          .update({
            'licencia_numero': numero.trim(),
            'licencia_vence_en': _fecha(venceEn),
          })
          .eq('id', id);
    });
  }

  Future<T> _correr<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on PostgrestException catch (e) {
      throw ConductorFallo(_traducir(e));
    }
  }

  String _idActual() {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const ConductorFallo('No hay sesión abierta.');
    return id;
  }

  /// `date` de PostgreSQL: «2027-03-15», sin hora ni zona.
  static String _fecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _traducir(PostgrestException e) {
    final texto = e.message.toLowerCase();
    if (texto.contains('vehiculos_placa_key')) {
      return 'Esa placa ya está registrada.';
    }
    if (texto.contains('vehiculos_placa_check')) {
      return 'La placa lleva 6 o 7 letras y números, como AB123CD.';
    }
    if (texto.contains('failed host lookup') ||
        texto.contains('socketexception')) {
      return 'No hay conexión. Revisa tus datos o el wifi.';
    }
    if (texto.contains('row-level security')) {
      return 'Tu cuenta no tiene permiso para guardar este vehículo.';
    }
    return e.message;
  }
}
