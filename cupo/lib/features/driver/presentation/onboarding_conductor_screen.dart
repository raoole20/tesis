import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../data/conductor_repository.dart';
import '../data/zonas_repository.dart';
import 'vehiculo_screen.dart';
import 'zonas_trabajo_screen.dart';

/// Onboarding del conductor aprobado (`DestinoAuth.onboardingConductor`):
/// primero registra su vehículo (HU-004) y después elige sus zonas (HU-005).
///
/// Si ya tiene vehículo (por ejemplo, lo registró en el perfil antes de la
/// revisión), pasa directo a las zonas. Las zonas llaman a
/// `completar_onboarding()`, que en el servidor también exige el vehículo.
class OnboardingConductorScreen extends StatefulWidget {
  const OnboardingConductorScreen({super.key, this.conductor, this.zonas});

  /// Por omisión, los de Supabase. Las pruebas pasan unos falsos.
  final ConductorRepository? conductor;
  final ZonasRepository? zonas;

  @override
  State<OnboardingConductorScreen> createState() =>
      _OnboardingConductorScreenState();
}

class _OnboardingConductorScreenState extends State<OnboardingConductorScreen> {
  late final ConductorRepository _conductor =
      widget.conductor ?? ConductorRepository();

  /// `null` mientras se consulta.
  bool? _tieneVehiculo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  Future<void> _consultar() async {
    setState(() => _error = null);
    try {
      final vehiculo = await _conductor.miVehiculo();
      if (mounted) setState(() => _tieneVehiculo = vehiculo != null);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return CupoScreen(
        topGap: AppSpacing.xxl,
        children: [
          CupoErrorBanner(mensaje: error),
          const SizedBox(height: AppSpacing.md),
          CupoSecondaryButton(label: 'Reintentar', onPressed: _consultar),
        ],
      );
    }

    return switch (_tieneVehiculo) {
      null => const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      ),
      false => VehiculoScreen(
        repositorio: _conductor,
        onGuardado: (_) => setState(() => _tieneVehiculo = true),
      ),
      true => ZonasTrabajoScreen(repositorio: widget.zonas),
    };
  }
}
