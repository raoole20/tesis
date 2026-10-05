import 'package:flutter/material.dart';

import '../../../shared/models/transport_shift.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import 'shift_detail_screen.dart';

/// 06 — Resultados de búsqueda de cupos.
///
/// Muestra las unidades y turnos que pasan a pie de la casa del estudiante.
class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({
    super.key,
    this.zoneName = 'Amparo',
    this.selectedDays = const ['Lun', 'Mar', 'Jue'],
    this.shiftName = 'Vespertino',
  });

  final String zoneName;
  final List<String> selectedDays;
  final String shiftName;

  @override
  Widget build(BuildContext context) {
    final shifts = TransportShift.mockShifts;

    return CupoScreen(
      leading: const CupoBackButton(),
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          '3 TURNOS CERCA DE',
          style: AppTypography.manrope(
            size: 13,
            weight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSupport,
          ),
        ),
        const SizedBox(height: 2),
        Text(zoneName, style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),

        // Fila de resumen de filtros
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildBadge('Destino Sede URBE'),
            _buildBadge(selectedDays.join(' · ')),
            _buildBadge(shiftName),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Pagas después',
                style: AppTypography.manrope(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Editar',
                  style: AppTypography.manrope(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Lista de tarjetas de transportistas
        ...shifts.map((shift) => _buildShiftCard(context, shift)),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTypography.manrope(
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, TransportShift shift) {
    final isLowSeats = shift.availableSeats <= 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ShiftDetailScreen(shift: shift),
            ),
          );
        },
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Conductor + Precio
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar de iniciales
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      shift.driverInitials,
                      style: AppTypography.manrope(
                        size: 14,
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
                          shift.driverName,
                          style: AppTypography.manrope(
                            size: 16,
                            weight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sale ${shift.departureTime} · ${shift.vehicleModel} · ⭐ ${shift.rating.toString().replaceAll('.', ',')} (${shift.ratingCount})',
                          style: AppTypography.manrope(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${shift.weeklyPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: AppTypography.manrope(
                          size: 18,
                          weight: FontWeight.w800,
                          color: AppColors.primaryDarkest,
                        ),
                      ),
                      Text(
                        'por semana',
                        style: AppTypography.manrope(
                          size: 11,
                          weight: FontWeight.w500,
                          color: AppColors.textSupport,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Cupos disponibles + Distancia caminable
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLowSeats ? AppColors.warningSoft : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLowSeats ? 'Queda 1 asiento' : '${shift.availableSeats} asientos libres',
                      style: AppTypography.manrope(
                        size: 12,
                        weight: FontWeight.w700,
                        color: isLowSeats ? AppColors.warning : AppColors.primaryDeep,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_walk_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tu parada a ${shift.walkingDistanceMeters} m',
                        style: AppTypography.manrope(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Etiquetas de confianza
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildTag(shift.hasAirConditioning ? 'Con aire' : 'Sin aire'),
                  if (shift.isVerified) _buildTag('Verificado'),
                  _buildTag('${shift.yearsOnRoute} años en la ruta · ${shift.activePassengersCount} pasajeros'),
                  _buildTag(shift.paymentCycleDescription),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.manrope(
          size: 11,
          weight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
