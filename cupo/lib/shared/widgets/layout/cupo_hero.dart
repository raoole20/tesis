import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import '../branding/cupo_lockup.dart';

/// Foto de cabecera del primer ingreso, oscurecida con un degradado para que
/// el texto blanco de encima se lea.
///
/// Tiene dos extremos y todo lo que hay entre ellos, según [compactness]:
///
/// - **0, alta** (bienvenida): degradado oscuro arriba, por la barra de
///   estado, limpio en el medio y muy oscuro abajo, donde van el logotipo
///   grande y el [headline];
/// - **1, compacta** (formularios): un velo parejo y el logotipo pequeño
///   arriba a la izquierda.
///
/// Los valores intermedios son la transición mientras la hoja crece: el
/// degradado se interpola y un logotipo se desvanece mientras aparece el otro.
///
/// Se asume que la foto sigue [AppSizes.heroOverlap] por detrás de la hoja:
/// el bloque de abajo se coloca contando con eso.
///
/// Mientras la imagen carga, o si falta, se ve [AppColors.primaryDarkest].
class CupoHero extends StatelessWidget {
  const CupoHero({
    super.key,
    this.image = fotoPrimerIngreso,
    this.compactness = 0,
    this.headline,
  });

  /// Foto de la v2 del diseño: carretera de noche vista desde arriba.
  static const String fotoPrimerIngreso =
      'assets/images/hero_primer_ingreso.webp';

  /// Ruta del recurso de imagen.
  final String image;

  /// De 0 (alta) a 1 (compacta).
  final double compactness;

  /// Titular bajo el logotipo grande. Solo se ve en la versión alta.
  final String? headline;

  static final LinearGradient _veloAlto = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0, 0.22, 0.45, 1],
    colors: [
      AppColors.ink.withValues(alpha: 0.55),
      AppColors.ink.withValues(alpha: 0),
      AppColors.ink.withValues(alpha: 0),
      AppColors.ink.withValues(alpha: 0.85),
    ],
  );

  static final LinearGradient _veloCompacto = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0, 0.22, 0.45, 1],
    colors: [
      AppColors.ink.withValues(alpha: 0.55),
      AppColors.ink.withValues(alpha: 0.45),
      AppColors.ink.withValues(alpha: 0.35),
      AppColors.ink.withValues(alpha: 0.15),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final t = compactness.clamp(0.0, 1.0);
    // Cada logotipo ocupa media transición: el grande se va en la primera
    // mitad y el pequeño llega en la segunda, así nunca se ven los dos.
    final opacidadGrande = (1 - t * 2).clamp(0.0, 1.0);
    final opacidadPequeno = (t * 2 - 1).clamp(0.0, 1.0);
    final titular = headline;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: AppColors.primaryDarkest,
          child: Image.asset(
            image,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient.lerp(_veloAlto, _veloCompacto, t),
          ),
        ),
        if (opacidadGrande > 0)
          Positioned(
            left: AppSpacing.screenH,
            right: AppSpacing.screenH,
            bottom: AppSizes.heroOverlap + AppSpacing.xxxl,
            child: Opacity(
              opacity: opacidadGrande,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupoLockup.inline(),
                  if (titular != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.heroHeadlineMaxWidth,
                      ),
                      child: Text(
                        titular,
                        style: AppTypography.display.copyWith(
                          color: AppColors.onPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (opacidadPequeno > 0)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenH,
                top: AppSpacing.xl,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Opacity(
                  opacity: opacidadPequeno,
                  child: CupoLockup.inline(
                    markSize: AppSizes.heroGlyphCompact,
                    wordmarkStyle: AppTypography.wordmarkHeroCompact,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
