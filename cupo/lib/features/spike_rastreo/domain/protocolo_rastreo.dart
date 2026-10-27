/// Protocolo del spike de rastreo en segundo plano (HU-011).
///
/// La prueba son tres fases de igual duración y la fase se decide por el
/// tiempo transcurrido desde la primera ubicación, no por lo que la persona
/// toque: así nadie tiene que interactuar con la app minimizada para avanzar,
/// que es justo lo que se quiere medir. Ver `docs/producto/spike-rastreo.md`.
library;

/// Las tres fases, en el orden en que pasan.
///
/// [valor] es el texto exacto de `spike_posiciones.fase` (mismo patrón que los
/// enums espejo de `auth/domain/`: no se usa `.name`).
enum FaseRastreo {
  primerPlano('1_primer_plano', 1),
  minimizada('2_minimizada', 2),
  pantallaApagada('3_pantalla_apagada', 3);

  const FaseRastreo(this.valor, this.numero);

  final String valor;

  /// 1, 2 o 3: el orden dentro del protocolo.
  final int numero;

  static FaseRastreo desde(String valor) {
    for (final fase in values) {
      if (fase.valor == valor) return fase;
    }
    throw ArgumentError.value(valor, 'valor', 'Fase de rastreo desconocida');
  }
}

/// Cuánto dura cada fase.
///
/// [estandar] es la corrida que vale como evidencia. [corta] sirve para ver
/// que todo funciona antes de invertir media hora, y [larga] para darle
/// tiempo a Android de entrar en reposo profundo con la pantalla apagada.
enum DuracionPrueba {
  corta(Duration(minutes: 2)),
  estandar(Duration(minutes: 10)),
  larga(Duration(minutes: 20));

  const DuracionPrueba(this.porFase);

  final Duration porFase;
}

/// Las reglas de tiempo de una sesión: cuánto dura cada fase y cada cuánto
/// se pide una ubicación.
class ProtocoloRastreo {
  const ProtocoloRastreo({
    required this.duracionFase,
    this.intervalo = intervaloPorOmision,
  });

  /// Cada cuánto se pide una ubicación. Con `distanceFilter: 0`, un teléfono
  /// quieto también produce una muestra por intervalo.
  static const Duration intervaloPorOmision = Duration(seconds: 5);

  final Duration duracionFase;
  final Duration intervalo;

  /// Lo que dura la prueba completa.
  Duration get total => duracionFase * FaseRastreo.values.length;

  /// Cuántas muestras deberían llegar en una fase completa.
  int get esperadasPorFase =>
      duracionFase.inMicroseconds ~/ intervalo.inMicroseconds;

  /// La fase en la que cae [transcurrido], o `null` si la prueba ya terminó.
  ///
  /// El borde es de la fase que empieza: al minuto 10 exacto ya se está en la
  /// fase 2. Un tiempo negativo (el reloj del teléfono retrocedió) cuenta
  /// como el principio.
  FaseRastreo? faseEn(Duration transcurrido) {
    final t = _noNegativo(transcurrido);
    final i = t.inMicroseconds ~/ duracionFase.inMicroseconds;
    return i < FaseRastreo.values.length ? FaseRastreo.values[i] : null;
  }

  /// Cuándo empieza [fase], contado desde el inicio de la sesión.
  Duration inicioDe(FaseRastreo fase) => duracionFase * (fase.numero - 1);

  /// Cuándo termina [fase], contado desde el inicio de la sesión.
  Duration finDe(FaseRastreo fase) => duracionFase * fase.numero;

  /// Lo que falta para que termine la fase en curso; cero si ya terminó todo.
  Duration restanteEn(Duration transcurrido) {
    final t = _noNegativo(transcurrido);
    final fase = faseEn(t);
    return fase == null ? Duration.zero : finDe(fase) - t;
  }

  static Duration _noNegativo(Duration d) => d.isNegative ? Duration.zero : d;
}

/// «07:32», o «1:02:05» pasada la hora. Para el cronómetro de la pantalla.
String formatoCronometro(Duration d) {
  final t = d.isNegative ? Duration.zero : d;
  final horas = t.inHours;
  final minutos = t.inMinutes.remainder(60).toString().padLeft(2, '0');
  final segundos = t.inSeconds.remainder(60).toString().padLeft(2, '0');
  return horas > 0 ? '$horas:$minutos:$segundos' : '$minutos:$segundos';
}

/// «10:42 am», «3:05 pm»: la hora como se dice en Venezuela, igual que las
/// horas del turno del conductor.
String horaCorta(DateTime hora) {
  final h12 = hora.hour % 12 == 0 ? 12 : hora.hour % 12;
  final minutos = hora.minute.toString().padLeft(2, '0');
  return '$h12:$minutos ${hora.hour < 12 ? 'am' : 'pm'}';
}
