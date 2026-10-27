import 'muestra_rastreo.dart';

/// Una muestra en camino, con el número del intento que la lleva.
class EnvioDeMuestra {
  const EnvioDeMuestra(this.muestra, this.intento);

  final MuestraRastreo muestra;

  /// 1 en el primer envío; sube con cada reintento.
  final int intento;
}

/// Manda un lote a Supabase. Si falla, lanza; si vuelve, el lote llegó.
typedef EnviarLote = Future<void> Function(List<EnvioDeMuestra> lote);

/// Cola en memoria de las muestras que todavía no llegan a Supabase.
///
/// Sin red, la muestra no se pierde: se queda aquí con su `seq` y su hora de
/// captura, y sale en el siguiente intento. Así la base distingue una muestra
/// que llegó tarde (hora de captura vieja, `intentos` > 1) de una que nunca
/// se capturó.
///
/// Es memoria y nada más: si Android mata el proceso, lo pendiente se pierde
/// y aparece como hueco en `seq`. Para el spike eso es una virtud, porque es
/// justo uno de los fallos que se quiere ver.
class ColaDeEnvio {
  ColaDeEnvio({required this.enviar, this.tamanoLote = 100})
    : assert(tamanoLote > 0);

  final EnviarLote enviar;

  /// Máximo de muestras por petición, para que una cola larga tras un corte
  /// de red no salga en un solo cuerpo enorme.
  final int tamanoLote;

  final List<_Pendiente> _pendientes = [];
  int _capturadas = 0;
  int _enviadas = 0;
  int _fallos = 0;
  Object? _ultimoError;
  bool _enviando = false;

  /// Todas las que entraron a la cola.
  int get capturadas => _capturadas;

  /// Las que Supabase ya confirmó.
  int get enviadas => _enviadas;

  /// Las que esperan un envío.
  int get pendientes => _pendientes.length;

  /// Cuántos envíos fallaron.
  int get fallos => _fallos;

  /// El error del último envío que falló, aunque después se haya recuperado.
  Object? get ultimoError => _ultimoError;

  /// Si hay un envío en vuelo.
  bool get enviando => _enviando;

  void encolar(MuestraRastreo muestra) {
    _pendientes.add(_Pendiente(muestra));
    _capturadas++;
  }

  /// Manda lo pendiente por lotes, en orden de llegada.
  ///
  /// Devuelve `true` si la cola quedó vacía y `false` si un lote falló (lo
  /// que quedaba sigue en la cola para el próximo intento). Si ya hay un
  /// envío en vuelo no lanza otro: ese recoge lo que se encole mientras tanto.
  Future<bool> vaciar() async {
    if (_enviando) return false;
    _enviando = true;
    try {
      while (_pendientes.isNotEmpty) {
        final tanda = _pendientes.take(tamanoLote).toList();
        for (final p in tanda) {
          p.intentos++;
        }
        try {
          await enviar([
            for (final p in tanda) EnvioDeMuestra(p.muestra, p.intentos),
          ]);
        } catch (e) {
          // Cualquier falla del envío deja el lote en la cola: la cola no
          // sabe de red ni de Supabase, y el error se guarda para mostrarlo.
          _fallos++;
          _ultimoError = e;
          return false;
        }
        // Lo nuevo se agrega al final, así que la tanda sigue al frente.
        _pendientes.removeRange(0, tanda.length);
        _enviadas += tanda.length;
      }
      return true;
    } finally {
      _enviando = false;
    }
  }
}

class _Pendiente {
  _Pendiente(this.muestra);

  final MuestraRastreo muestra;
  int intentos = 0;
}
