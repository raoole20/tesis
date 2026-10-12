import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/theme.dart';

/// Indicador explícito de los pasos de un flujo:
///
/// ```text
/// ①━━━━━━━━━━━━━━━━━②
/// Tipo de cuenta      Tus datos
/// ```
///
/// Arriba, un círculo por paso unidos por una línea; debajo, el nombre de
/// cada uno. El paso hecho lleva un visto, el actual su número en verde lago,
/// y los que faltan su número sobre el relleno apagado. Cada tramo de línea
/// se pinta en verde lago cuando el paso al que llega ya empezó.
///
/// Los nombres van en su propia fila, y no al lado de los círculos, para que
/// una letra grande del sistema los parta en líneas en vez de desbordar.
///
/// Para el lector de pantalla es una sola frase: «Paso 1 de 2: Tipo de
/// cuenta».
class CupoStepIndicator extends StatelessWidget {
  const CupoStepIndicator({
    super.key,
    required this.pasos,
    required this.actual,
  });

  /// Nombre corto de cada paso, en orden.
  final List<String> pasos;

  /// Índice del paso en curso, desde 0.
  final int actual;

  @override
  Widget build(BuildContext context) {
    assert(actual >= 0 && actual < pasos.length, 'Paso fuera de rango.');
    final ultimo = pasos.length - 1;

    final circulos = <Widget>[];
    final nombres = <Widget>[];

    for (var i = 0; i <= ultimo; i++) {
      final estado = _estado(i);

      if (i > 0) {
        circulos.add(
          Expanded(
            child: Container(
              height: AppSizes.stepConnector,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              color: i <= actual ? AppColors.primary : AppColors.border,
            ),
          ),
        );
      }
      circulos.add(_Circulo(numero: i + 1, estado: estado));

      nombres.add(
        Expanded(
          child: Text(
            pasos[i],
            textAlign: switch (i) {
              0 => TextAlign.start,
              _ when i == ultimo => TextAlign.end,
              _ => TextAlign.center,
            },
            style: switch (estado) {
              _EstadoPaso.actual => AppTypography.metaStrong,
              _EstadoPaso.hecho => AppTypography.meta.copyWith(
                color: AppColors.primaryDeep,
              ),
              _EstadoPaso.pendiente => AppTypography.meta.copyWith(
                color: AppColors.textSupport,
              ),
            },
          ),
        ),
      );
    }

    return Semantics(
      label: 'Paso ${actual + 1} de ${pasos.length}: ${pasos[actual]}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: circulos),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: nombres,
            ),
          ],
        ),
      ),
    );
  }

  _EstadoPaso _estado(int i) {
    if (i < actual) return _EstadoPaso.hecho;
    if (i == actual) return _EstadoPaso.actual;
    return _EstadoPaso.pendiente;
  }
}

enum _EstadoPaso { hecho, actual, pendiente }

class _Circulo extends StatelessWidget {
  const _Circulo({required this.numero, required this.estado});

  final int numero;
  final _EstadoPaso estado;

  @override
  Widget build(BuildContext context) {
    final pendiente = estado == _EstadoPaso.pendiente;
    final tinta = pendiente ? AppColors.textSupport : AppColors.onPrimary;

    return Container(
      width: AppSizes.stepDot,
      height: AppSizes.stepDot,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pendiente ? AppColors.backgroundMuted : AppColors.primary,
      ),
      child: estado == _EstadoPaso.hecho
          ? Icon(LucideIcons.check, size: AppSizes.iconSmall, color: tinta)
          : Text(
              '$numero',
              style: AppTypography.stepNumber.copyWith(color: tinta),
            ),
    );
  }
}
