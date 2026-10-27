import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../data/conductor_repository.dart';
import '../domain/vehiculo.dart';
import 'campos_vehiculo.dart';

/// «Tu vehículo» (HU-004): registrar o editar la unidad del conductor ya
/// aprobado. Se abre desde el inicio del conductor.
///
/// Al guardar, cierra la pantalla y devuelve el [Vehiculo] guardado, para
/// que el inicio lo muestre sin volver a consultar.
class VehiculoScreen extends StatefulWidget {
  const VehiculoScreen({super.key, this.repositorio, this.hoy});

  /// Por omisión, el de Supabase. Las pruebas pasan uno falso.
  final ConductorRepository? repositorio;

  /// Por omisión, la fecha del teléfono. Fija el año máximo aceptado.
  final DateTime? hoy;

  @override
  State<VehiculoScreen> createState() => _VehiculoScreenState();
}

class _VehiculoScreenState extends State<VehiculoScreen> {
  late final ConductorRepository _repo =
      widget.repositorio ?? ConductorRepository();

  VehiculoControladores? _campos;
  Vehiculo? _existente;
  bool _guardando = false;
  String? _errorCarga;
  String? _error;

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
    if (campos == null || _guardando) return;

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
      if (mounted) Navigator.of(context).pop(guardado);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campos = _campos;
    final errorCarga = _errorCarga;
    final error = _error;
    final nuevo = _existente == null;

    return CupoScreen(
      leading: const CupoBackButton(),
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
                  label: nuevo ? 'Registrar vehículo' : 'Guardar cambios',
                  isLoading: _guardando,
                  onPressed: _guardar,
                ),
              ],
            ),
      children: [
        Text('Tu vehículo', style: AppTypography.title),
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
          CamposVehiculo(controladores: campos, habilitado: !_guardando),
      ],
    );
  }
}
