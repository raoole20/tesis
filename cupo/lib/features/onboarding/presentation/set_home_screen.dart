import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../search/presentation/search_filters_screen.dart';

/// 03 y 04 — Marcar mi casa y Zona detectada.
///
/// Permite al estudiante fijar su domicilio y confirma la zona detectada
/// (ej. Amparo) antes de configurar sus días y turnos de clase.
class SetHomeScreen extends StatefulWidget {
  const SetHomeScreen({super.key});

  @override
  State<SetHomeScreen> createState() => _SetHomeScreenState();
}

class _SetHomeScreenState extends State<SetHomeScreen> {
  final _refController = TextEditingController(
    text: 'Av. 15 con calle 100, casa azul',
  );
  final String _detectedZone = 'Amparo';

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  void _confirmLocation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchFiltersScreen(zoneName: _detectedZone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupoScreen(
      leading: const CupoBackButton(),
      footer: CupoPrimaryButton(
        label: 'Confirmar ubicación',
        onPressed: _confirmLocation,
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text('¿Dónde vives?', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Marca tu casa. Con eso buscamos transportes que pasen cerca '
          'y te decimos hasta qué parada te toca caminar. Solo lo haces una vez.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Contenedor visual del mapa con el pin
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2F2),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cuadrícula sutil que simula calles
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapGridPainter(),
                ),
              ),

              // Píldora de instrucción
              Positioned(
                top: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Arrastra el pin hasta tu casa',
                    style: AppTypography.manrope(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),

              // Pin de ubicación central
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDarkest.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: AppColors.surface,
                      size: 20,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkest.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Campo de referencia opcional
        CupoField(
          label: 'Referencia (opcional)',
          helper: 'Le sirve al conductor para ubicarte más rápido.',
          child: CupoTextInput(
            controller: _refController,
            hintText: 'Ej. Frente a la panadería, portón negro',
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Bloque de Zona Detectada (Diapositiva 04)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Estás en $_detectedZone',
                        style: AppTypography.manrope(
                          size: 15,
                          weight: FontWeight.w700,
                          color: AppColors.primaryDarkest,
                        ),
                      ),
                    ],
                  ),
                  CupoLink(
                    label: 'Corregir',
                    onPressed: () {
                      // Permite cambiar zona si el GPS no fue exacto
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Los transportistas publican sus rutas por zona, así te '
                'mostramos primero los que trabajan la tuya.',
                style: AppTypography.manrope(
                  size: 13,
                  weight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dibuja líneas suaves para ilustrar un mapa urbano de fondo
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;

    // Calles horizontales
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), paint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), paint);

    // Calles verticales
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.65, 0), Offset(size.width * 0.65, size.height), paint);

    // Avenida diagonal
    final mainRoadPaint = Paint()
      ..color = const Color(0xFFD3E4E4)
      ..strokeWidth = 6.0;
    canvas.drawLine(Offset(0, size.height * 0.85), Offset(size.width, size.height * 0.2), mainRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
