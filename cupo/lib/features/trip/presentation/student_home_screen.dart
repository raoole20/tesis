import 'package:flutter/material.dart';

import '../../../shared/models/transport_shift.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import 'live_tracking_screen.dart';

/// 10 — Inicio del estudiante ya inscrito (Home).
///
/// Pantalla principal diaria: viaje de hoy en curso, control de asistencia semanal
/// y estado de cuenta / liquidación con el conductor.
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key, this.shift});

  final TransportShift? shift;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentNavIndex = 0;

  // Estado semanal interactivo: Lunes a Viernes
  final Map<String, bool> _attendance = {
    'LUN': true,
    'MAR': true,
    'MIÉ': false,
    'JUE': false,
    'VIE': false,
  };

  bool _isAttendingToday = true;

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift ?? TransportShift.mockShifts.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior: Fecha + Saludo + Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lunes 4 de agosto',
                        style: AppTypography.manrope(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.textSupport,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Hola, Génesis', style: AppTypography.title),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      'GM',
                      style: AppTypography.manrope(
                        size: 15,
                        weight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Tarjeta TU VIAJE DE HOY
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(
                    color: _isAttendingToday
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TU VIAJE DE HOY',
                          style: AppTypography.manrope(
                            size: 11,
                            weight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppColors.textSupport,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _isAttendingToday
                                ? AppColors.successSoft
                                : AppColors.backgroundAlt,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isAttendingToday ? 'Confirmado' : 'No vas hoy',
                            style: AppTypography.manrope(
                              size: 11,
                              weight: FontWeight.w700,
                              color: _isAttendingToday
                                  ? AppColors.success
                                  : AppColors.textSupport,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          shift.departureTime,
                          style: AppTypography.manrope(
                            size: 28,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'en tu parada',
                          style: AppTypography.manrope(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            shift.driverInitials,
                            style: AppTypography.manrope(
                              size: 9,
                              weight: FontWeight.w800,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${shift.driverName} · ${shift.vehicleModel} · tu parada a ${shift.walkingDistanceMeters} m',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // Botones de acción del viaje
                    Row(
                      children: [
                        Expanded(
                          child: CupoPrimaryButton(
                            label: 'Ver dónde viene',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      LiveTrackingScreen(shift: shift),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupoLink(label: 'Ver ruta completa', onPressed: () {}),
                        CupoLink(
                          label: _isAttendingToday
                              ? 'No voy hoy'
                              : 'Cambiar a: Sí voy',
                          onPressed: () {
                            setState(() {
                              _isAttendingToday = !_isAttendingToday;
                              _attendance['LUN'] = _isAttendingToday;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Sección TU SEMANA (Control interactivo)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tu semana', style: AppTypography.titleMedium),
                  Text(
                    '4 al 8 de agosto',
                    style: AppTypography.manrope(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.textSupport,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Cuadrícula de asistencia semanal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _attendance.entries.map((entry) {
                  final day = entry.key;
                  final goes = entry.value;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _attendance[day] = !goes;
                            if (day == 'LUN') {
                              _isAttendingToday = !goes;
                            }
                          });
                        },
                        borderRadius: AppRadius.smAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: goes
                                ? AppColors.primarySoft
                                : AppColors.surface,
                            borderRadius: AppRadius.smAll,
                            border: Border.all(
                              color: goes
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: goes ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                day,
                                style: AppTypography.manrope(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: goes
                                      ? AppColors.primaryDarkest
                                      : AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                goes ? 'Voy' : 'No voy',
                                style: AppTypography.manrope(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: goes
                                      ? AppColors.primary
                                      : AppColors.textSupportSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ya está lista con tus días de siempre. Toca un día si esta semana cambia algo.',
                style: AppTypography.helper,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Bloque de deuda / liquidación
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundAlt,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Le debes a ${shift.driverName.split(" ").first}',
                            style: AppTypography.manrope(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '\$${shift.weeklyPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: AppTypography.manrope(
                                  size: 22,
                                  weight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '· Liquidas el viernes',
                                style: AppTypography.manrope(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: AppColors.textSupport,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CupoLink(label: 'Ver cuenta', onPressed: () {}),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSupport,
        backgroundColor: AppColors.surface,
        selectedLabelStyle: AppTypography.manrope(
          size: 12,
          weight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.manrope(
          size: 12,
          weight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alt_route_rounded),
            label: 'Mi ruta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}
