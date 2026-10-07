import 'package:flutter/material.dart';

import '../../../shared/models/transport_shift.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../enrollment/presentation/request_status_screen.dart';

/// 07 — Detalle del turno.
///
/// La ruta con paradas, horarios de ida y vuelta, desglose de precio semanal
/// y la explicación del pago diferido sin cobro adelantado.
class ShiftDetailScreen extends StatelessWidget {
  const ShiftDetailScreen({super.key, required this.shift});

  final TransportShift shift;

  @override
  Widget build(BuildContext context) {
    return CupoScreen(
      leading: const CupoBackButton(),
      footer: CupoPrimaryButton(
        label: 'Solicitar puesto',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RequestStatusScreen(shift: shift),
            ),
          );
        },
      ),
      children: [
        // Indicador de ruta y tiempo de caminata
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundAlt,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Tu parada · ${shift.walkingDistanceMeters} m',
                    style: AppTypography.manrope(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textSupport,
                    size: 16,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.school_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Sede URBE',
                    style: AppTypography.manrope(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${shift.stopsCount} paradas · ${shift.durationMinutes} min de recorrido',
                style: AppTypography.manrope(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Ficha del transportista
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                shift.driverInitials,
                style: AppTypography.manrope(
                  size: 18,
                  weight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shift.driverName, style: AppTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${shift.vehicleModel} ${shift.vehicleColor} · ${shift.totalSeats} puestos · ${shift.hasAirConditioning ? "Con aire" : "Sin aire"}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    shift.rating.toString().replaceAll('.', ','),
                    style: AppTypography.manrope(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // Horarios IDA y VUELTA
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IDA',
                      style: AppTypography.manrope(
                        size: 11,
                        weight: FontWeight.w800,
                        color: AppColors.textSupport,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shift.departureTime,
                      style: AppTypography.manrope(
                        size: 18,
                        weight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'llega ${shift.arrivalTime}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VUELTA',
                      style: AppTypography.manrope(
                        size: 11,
                        weight: FontWeight.w800,
                        color: AppColors.textSupport,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shift.returnTime,
                      style: AppTypography.manrope(
                        size: 18,
                        weight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'desde el portón URBE',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Desglose de precios
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundAlt,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tu puesto, Lun · Mar · Jue',
                    style: AppTypography.manrope(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '\$${shift.weeklyPrice.toStringAsFixed(2).replaceAll('.', ',')} semanal',
                    style: AppTypography.manrope(
                      size: 15,
                      weight: FontWeight.w800,
                      color: AppColors.primaryDarkest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Carrera suelta',
                    style: AppTypography.manrope(
                      size: 13,
                      weight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${shift.singleTripPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: AppTypography.manrope(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Bloque informativo «No pagas ahora»
        CupoInfoBanner(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No pagas ahora.',
                style: AppTypography.manrope(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.primaryDarkest,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Se te van sumando los viajes y liquidas cada semana con ${shift.driverName.split(" ").first}, el día que acuerden.',
                style: AppTypography.manrope(
                  size: 13,
                  weight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Elementos de confianza
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckItem(
              'Cédula, licencia y certificado médico verificados',
            ),
            const SizedBox(height: 6),
            _buildCheckItem(
              '${shift.yearsOnRoute} años haciendo esta ruta · ${shift.activePassengersCount} pasajeros activos',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTypography.manrope(
              size: 12,
              weight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
