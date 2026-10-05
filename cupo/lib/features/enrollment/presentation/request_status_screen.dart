import 'package:flutter/material.dart';

import '../../../shared/models/transport_shift.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../trip/presentation/student_home_screen.dart';

/// 08 y 09 — Solicitud enviada y Puesto apartado.
///
/// Ilustra los dos estados posteriores a la solicitud:
/// 1. En espera de respuesta del transportista (Línea de tiempo).
/// 2. Puesto apartado con cuenta regresiva de vencimiento para el pago inicial.
class RequestStatusScreen extends StatefulWidget {
  const RequestStatusScreen({super.key, required this.shift});

  final TransportShift shift;

  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> {
  // Permite simular que el conductor ya aceptó la solicitud
  bool _isAccepted = false;

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => StudentHomeScreen(shift: widget.shift),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupoScreen(
      leading: const CupoBackButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isAccepted) ...[
            CupoPrimaryButton(
              label: 'Simular: Luis me aceptó',
              onPressed: () => setState(() => _isAccepted = true),
            ),
            const SizedBox(height: AppSpacing.sm),
            CupoSecondaryButton(
              label: 'Seguir viendo, por si acaso',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] else ...[
            CupoPrimaryButton(
              label: 'Ya le pagué a ${widget.shift.driverName.split(" ").first}',
              onPressed: _goToHome,
            ),
            const SizedBox(height: AppSpacing.sm),
            CupoSecondaryButton(
              label: 'Ir a mi pantalla de Inicio',
              onPressed: _goToHome,
            ),
          ],
        ],
      ),
      children: [
        if (!_isAccepted) ..._buildWaitingState() else ..._buildAcceptedState(),
      ],
    );
  }

  List<Widget> _buildWaitingState() {
    return [
      const SizedBox(height: AppSpacing.sm),
      Text('Esperando respuesta', style: AppTypography.title),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Le llegó tu solicitud a ${widget.shift.driverName}. '
        'Él revisa que le cuadre tu parada y te responde. '
        'Casi siempre contesta el mismo día. Todavía no tienes el puesto y no pagas nada.',
        style: AppTypography.body,
      ),
      const SizedBox(height: AppSpacing.xl),

      // Línea de tiempo de 3 pasos
      _buildTimelineStep(
        isDone: true,
        isCurrent: false,
        title: 'Solicitud enviada',
        subtitle: 'Hoy, 9:41 am',
      ),
      _buildTimelineStep(
        isDone: false,
        isCurrent: true,
        title: '${widget.shift.driverName.split(" ").first} responde',
        subtitle: 'Te llega una notificación a la app',
      ),
      _buildTimelineStep(
        isDone: false,
        isCurrent: false,
        title: 'Apartas tu puesto y haces el primer pago',
        subtitle: 'Ahí queda fijo para el semestre',
        isLast: true,
      ),

      const SizedBox(height: AppSpacing.xl),

      // Resumen de lo pedido
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundAlt,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lo que pediste',
              style: AppTypography.manrope(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.textSupport,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${widget.shift.weeklyPrice.toStringAsFixed(2).replaceAll('.', ',')} por semana',
              style: AppTypography.manrope(
                size: 16,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Vespertino · Lun · Mar · Jue · sale ${widget.shift.departureTime} · tu parada a ${widget.shift.walkingDistanceMeters} m',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildAcceptedState() {
    return [
      const SizedBox(height: AppSpacing.sm),
      Text('Apartado, todavía no es fijo', style: AppTypography.title),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '${widget.shift.driverName.split(" ").first} te aceptó y te guardó el puesto. '
        'Para que quede fijo tienes que hacerle el primer pago y que él lo confirme. '
        'Si no, el asiento vuelve a estar libre para otro estudiante.',
        style: AppTypography.body,
      ),
      const SizedBox(height: AppSpacing.lg),

      // Plazo de vencimiento con advertencia
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TIENES PARA PAGAR HASTA',
                  style: AppTypography.manrope(
                    size: 11,
                    weight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.warning,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'faltan 2 días',
                    style: AppTypography.manrope(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Jueves 7, 12:00 m',
              style: AppTypography.manrope(
                size: 18,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: AppSpacing.md),

      // Desglose del primer pago
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Primer pago',
              style: AppTypography.manrope(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.textSupport,
              ),
            ),
            Text(
              '\$${widget.shift.weeklyPrice.toStringAsFixed(2).replaceAll('.', ',')}',
              style: AppTypography.manrope(
                size: 24,
                weight: FontWeight.w800,
                color: AppColors.primaryDarkest,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cubre tu primera semana. Después ya pagas al final de cada semana, como es normal aquí.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),

      const SizedBox(height: AppSpacing.md),

      // Datos del chofer para el pago
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundAlt,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                widget.shift.driverInitials,
                style: AppTypography.manrope(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.primaryDeep,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.shift.driverName,
                    style: AppTypography.manrope(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Pago móvil o efectivo el primer día',
                    style: AppTypography.manrope(
                      size: 12,
                      weight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            CupoLink(label: 'Ver datos', onPressed: () {}),
          ],
        ),
      ),
    ];
  }

  Widget _buildTimelineStep({
    required bool isDone,
    required bool isCurrent,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.success
                    : isCurrent
                        ? AppColors.primary
                        : AppColors.border,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: AppColors.surface)
                    : isCurrent
                        ? const Icon(Icons.circle, size: 8, color: AppColors.surface)
                        : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? AppColors.success : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.manrope(
                  size: 14,
                  weight: isCurrent || isDone ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: AppTypography.manrope(
                  size: 12,
                  weight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
