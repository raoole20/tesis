import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../data/conductor_repository.dart';
import '../domain/vehiculo.dart';
import 'campos_vehiculo.dart';

/// Pasos del onboarding del conductor, para [CupoStepIndicator].
const List<String> pasosDelOnboardingConductor = ['Tu vehículo', 'Tus zonas'];

/// «Tu vehículo» (HU-004): registrar, editar o eliminar la unidad.
///
/// Se usa de dos maneras:
/// - **Desde la app** (inicio o «Tu cuenta»): con retroceso; al guardar o
///   eliminar, cierra la pantalla. Al guardar devuelve el [Vehiculo].
/// - **En el onboarding** ([onGuardado] no nulo): primer paso de dos, sin
///   retroceso ni «Eliminar»; al guardar llama a [onGuardado] en vez de
///   cerrar.
///
/// Cada cambio avisa por [ConductorRepository.cambios], para que el inicio se
/// actualice aunque la pantalla se haya abierto desde otro lado.
class VehiculoScreen extends StatefulWidget {
  const VehiculoScreen({
    super.key,
    this.repositorio,
    this.hoy,
    this.onGuardado,
  });

  /// Por omisión, el de Supabase. Las pruebas pasan uno falso.
  final ConductorRepository? repositorio;

  /// Por omisión, la fecha del teléfono. Fija el año máximo aceptado.
  final DateTime? hoy;

  /// Solo en el onboarding: qué hacer con el vehículo guardado.
  final ValueChanged<Vehiculo>? onGuardado;

  @override
  State<VehiculoScreen> createState() => _VehiculoScreenState();
}

class _VehiculoScreenState extends State<VehiculoScreen> {
  late final ConductorRepository _repo =
      widget.repositorio ?? ConductorRepository();

  VehiculoControladores? _campos;
  Vehiculo? _existente;
  bool _guardando = false;
  bool _eliminando = false;
  String? _errorCarga;
  String? _error;

  bool get _enOnboarding => widget.onGuardado != null;
  bool get _ocupado => _guardando || _eliminando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _campos?.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _errorCarga = null);
    try {
      final vehiculo = await _repo.miVehiculo();
      if (!mounted) return;
      setState(() {
        _existente = vehiculo;
        _campos?.dispose();
        _campos = VehiculoControladores(vehiculo);
      });
    } catch (e) {
      if (mounted) setState(() => _errorCarga = e.toString());
    }
  }

  Future<void> _guardar() async {
    final campos = _campos;
    if (campos == null || _ocupado) return;

    final hoy = widget.hoy ?? DateTime.now();
    final falta = campos.validar(anioActual: hoy.year);
    if (falta != null) {
      setState(() => _error = falta);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final guardado = await _repo.guardarVehiculo(
        campos.borrador(),
        id: _existente?.id,
      );
      if (!mounted) return;
      final onGuardado = widget.onGuardado;
      if (onGuardado != null) {
        onGuardado(guardado);
      } else {
        Navigator.of(context).pop(guardado);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    final vehiculo = _existente;
    if (vehiculo == null || _ocupado) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar tu vehículo?', style: AppTypography.titleMedium),
        content: Text(
          'Se borra ${vehiculo.nombre} (${vehiculo.placa}). Sin vehículo no '
          'podrás publicar turnos hasta que registres otro.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() {
      _eliminando = true;
      _error = null;
    });
    try {
      await _repo.eliminarVehiculo(vehiculo.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campos = _campos;
    final errorCarga = _errorCarga;
    final error = _error;
    final nuevo = _existente == null;

    final String rotulo;
    if (_enOnboarding) {
      rotulo = 'Continuar';
    } else {
      rotulo = nuevo ? 'Registrar vehículo' : 'Guardar cambios';
    }

    return PopScope(
      canPop: !_enOnboarding,
      child: CupoScreen(
        leading: _enOnboarding ? null : const CupoBackButton(),
        topGap: AppSpacing.md,
        footer: campos == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) ...[
                    CupoErrorBanner(mensaje: error),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  CupoPrimaryButton(
                    label: rotulo,
                    isLoading: _guardando,
                    onPressed: _eliminando ? null : _guardar,
                  ),
                  if (!_enOnboarding && !nuevo) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CupoSecondaryButton(
                      label: 'Eliminar vehículo',
                      leading: const Icon(
                        LucideIcons.trash2,
                        size: AppSizes.icon,
                      ),
                      isLoading: _eliminando,
                      onPressed: _guardando ? null : _eliminar,
                    ),
                  ],
                ],
              ),
        children: [
          if (_enOnboarding) ...[
            const SizedBox(height: AppSpacing.xs),
            const CupoStepIndicator(
              pasos: pasosDelOnboardingConductor,
              actual: 0,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          Text(
            _enOnboarding ? 'Primero, tu vehículo' : 'Tu vehículo',
            style: AppTypography.title,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Los estudiantes ven la placa, el modelo y el color antes de '
            'pedirte un cupo.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (errorCarga != null) ...[
            CupoErrorBanner(mensaje: errorCarga),
            const SizedBox(height: AppSpacing.md),
            CupoSecondaryButton(label: 'Reintentar', onPressed: _cargar),
          ] else if (campos == null)
            const Center(child: CircularProgressIndicator())
          else
            CamposVehiculo(controladores: campos, habilitado: !_ocupado),
        ],
      ),
    );
  }
}
