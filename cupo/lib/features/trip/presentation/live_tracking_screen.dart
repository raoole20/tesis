import 'package:flutter/material.dart';

import '../../../shared/models/transport_shift.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';

/// 11 — Ver dónde viene (Seguimiento en vivo del transporte).
///
/// Muestra los minutos restantes para que la van llegue a la parada del
/// estudiante, la parada actual dentro de la ruta y las opciones de confirmación.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, required this.shift});

  final TransportShift shift;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  bool _isAtStop = false;

  @override
  Widget build(BuildContext context) {
    return CupoScreen(
      leading: const CupoBackButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupoPrimaryButton(
            label: _isAtStop ? 'Ya estoy en la parada ✓' : 'Ya estoy en la parada',
            onPressed: () => setState(() => _isAtStop = true),
          ),
          const SizedBox(height: AppSpacing.sm),
          CupoSecondaryButton(
            label: 'Se me presentó algo, no alcanzo',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Se le avisó a ${widget.shift.driverName.split(" ").first} que no alcanzarás la unidad.',
                  ),
                ),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Seguimiento en vivo', style: AppTypography.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'En camino',
                    style: AppTypography.manrope(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Progreso de ruta esquemático
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
                  _buildStopPill('Va por Amparo', isPast: true),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.textSupport),
                  _buildStopPill('Tu parada', isTarget: true),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.textSupport),
                  _buildStopPill('Sede URBE'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Barra de progreso de ruta (Parada 3 de 6)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.5,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Inicio de ruta', style: AppTypography.legal),
                  Text(
                    'Parada 3 de ${widget.shift.stopsCount}',
                    style: AppTypography.manrope(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  Text('Destino', style: AppTypography.legal),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Tarjeta grande de tiempo estimado (ETA)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'LLEGA A TU PARADA',
                style: AppTypography.manrope(
                  size: 12,
                  weight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textSupport,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'en 6 min',
                style: AppTypography.manrope(
                  size: 38,
                  weight: FontWeight.w800,
                  color: AppColors.primaryDarkest,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aprox. 12:16 pm',
                style: AppTypography.manrope(
                  size: 15,
                  weight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      widget.shift.driverInitials,
                      style: AppTypography.manrope(
                        size: 10,
                        weight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${widget.shift.driverName} · ${widget.shift.vehicleModel} · ${widget.shift.plateNumber}',
                    style: AppTypography.manrope(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Aviso de notificación de proximidad
        CupoInfoBanner(
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Te avisamos otra vez cuando esté a 2 minutos de tu parada.',
                  style: AppTypography.manrope(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_isAtStop) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '¡Avisado al conductor! Luis ya sabe que estás esperando en la parada.',
                    style: AppTypography.manrope(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStopPill(String label, {bool isPast = false, bool isTarget = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTarget
            ? AppColors.primary
            : isPast
                ? AppColors.primarySoft
                : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTarget ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.manrope(
          size: 11,
          weight: isTarget ? FontWeight.w700 : FontWeight.w500,
          color: isTarget
              ? AppColors.onPrimary
              : isPast
                  ? AppColors.primaryDeep
                  : AppColors.textSecondary,
        ),
      ),
    );
  }
}
