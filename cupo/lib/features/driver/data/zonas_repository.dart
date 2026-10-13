import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/zona.dart';

/// Error al leer o guardar zonas, ya redactado para mostrarse.
class ZonasFallo implements Exception {
  const ZonasFallo(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// El catálogo de zonas y las zonas de trabajo del conductor
/// (`public.zonas` y `public.conductor_zonas`).
///
/// Igual que `AuthRepository`, el cliente se resuelve al usarlo y no al
/// construir, para que las pruebas de widget puedan pasar una subclase falsa
/// sin levantar Supabase.
class ZonasRepository {
  ZonasRepository({SupabaseClient? cliente}) : _inyectado = cliente;

  final SupabaseClient? _inyectado;

  SupabaseClient get _db => _inyectado ?? Supabase.instance.client;

  /// Las zonas activas, por municipio y nombre.
  ///
  /// El RLS deja leer el catálogo a cualquier usuario con sesión; el filtro
  /// por `activa` es de la app: una zona dada de baja no se ofrece.
  Future<List<Zona>> catalogo() async {
    try {
      final filas = await _db
          .from('zonas')
          .select('id, nombre, municipio')
          .eq('activa', true)
          .order('municipio')
          .order('nombre');
      return filas.map(Zona.fromMap).toList();
    } on PostgrestException catch (e) {
      throw ZonasFallo(_traducir(e));
    }
  }

  /// Los `id` de las zonas que el conductor ya tiene, para preseleccionarlas.
  Future<Set<String>> misZonas() async {
    final id = _idActual();
    try {
      final filas = await _db
          .from('conductor_zonas')
          .select('zona_id')
          .eq('conductor_id', id);
      return {for (final fila in filas) fila['zona_id'] as String};
    } on PostgrestException catch (e) {
      throw ZonasFallo(_traducir(e));
    }
  }

  /// Deja en `conductor_zonas` exactamente las zonas de [ids].
  ///
  /// Primero agrega las nuevas y después quita las que sobran, en ese orden:
  /// si la segunda llamada falla, el conductor queda con zonas de más, nunca
  /// sin ninguna. Con cero zonas desaparecería de todas las búsquedas.
  Future<void> guardarMisZonas(Set<String> ids) async {
    if (ids.isEmpty) {
      throw const ZonasFallo('Elige al menos una zona.');
    }
    final id = _idActual();

    try {
      // La clave primaria (conductor_id, zona_id) ya impide duplicados;
      // `ignoreDuplicates` evita el error por las que ya estaban.
      await _db
          .from('conductor_zonas')
          .upsert(
            [
              for (final zonaId in ids) {'conductor_id': id, 'zona_id': zonaId},
            ],
            onConflict: 'conductor_id,zona_id',
            ignoreDuplicates: true,
          );

      await _db
          .from('conductor_zonas')
          .delete()
          .eq('conductor_id', id)
          .not('zona_id', 'in', '(${ids.join(',')})');
    } on PostgrestException catch (e) {
      throw ZonasFallo(_traducir(e));
    }
  }

  String _idActual() {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const ZonasFallo('No hay sesión abierta.');
    return id;
  }

  String _traducir(PostgrestException e) {
    final texto = e.message.toLowerCase();
    if (texto.contains('failed host lookup') ||
        texto.contains('socketexception')) {
      return 'No hay conexión. Revisa tus datos o el wifi.';
    }
    if (texto.contains('row-level security')) {
      return 'Tu cuenta no tiene permiso para cambiar estas zonas.';
    }
    return e.message;
  }
}
