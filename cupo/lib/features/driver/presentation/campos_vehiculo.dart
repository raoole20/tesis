import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../domain/vehiculo.dart';

/// El estado del formulario del vehículo: los textos y la capacidad.
///
/// Vive fuera del widget para que la pantalla que lo usa decida cuándo
/// validar y guardar, y para poder precargarlo con un vehículo existente.
class VehiculoControladores {
  VehiculoControladores([Vehiculo? inicial])
    : placa = TextEditingController(text: inicial?.placa),
      marca = TextEditingController(text: inicial?.marca),
      modelo = TextEditingController(text: inicial?.modelo),
      anio = TextEditingController(text: inicial?.anio?.toString()),
      color = TextEditingController(text: inicial?.color),
      capacidad = ValueNotifier(
        inicial?.capacidad ?? ReglasVehiculo.capacidadInicial,
      );

  final TextEditingController placa;
  final TextEditingController marca;
  final TextEditingController modelo;
  final TextEditingController anio;
  final TextEditingController color;
  final ValueNotifier<int> capacidad;

  /// El primer problema del formulario, o `null` si se puede guardar.
  String? validar({required int anioActual}) {
    final placa = ReglasVehiculo.validarPlaca(this.placa.text);
    if (placa != null) return placa;
    if (marca.text.trim().isEmpty) return 'Escribe la marca del vehículo.';
    if (modelo.text.trim().isEmpty) return 'Escribe el modelo del vehículo.';
    final anio = ReglasVehiculo.validarAnio(
      this.anio.text,
      anioActual: anioActual,
    );
    if (anio != null) return anio;
    if (color.text.trim().isEmpty) return 'Escribe el color del vehículo.';
    return null;
  }

  /// Llamar solo después de [validar].
  VehiculoBorrador borrador() {
    return VehiculoBorrador(
      placa: ReglasVehiculo.normalizarPlaca(placa.text),
      marca: marca.text.trim(),
      modelo: modelo.text.trim(),
      anio: int.tryParse(anio.text.trim()),
      color: color.text.trim(),
      capacidad: capacidad.value,
    );
  }

  void dispose() {
    placa.dispose();
    marca.dispose();
    modelo.dispose();
    anio.dispose();
    color.dispose();
    capacidad.dispose();
  }
}

/// Los campos del vehículo: placa, marca, modelo, año, color y puestos.
class CamposVehiculo extends StatelessWidget {
  const CamposVehiculo({
    super.key,
    required this.controladores,
    this.habilitado = true,
  });

  final VehiculoControladores controladores;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final c = controladores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupoField(
          label: 'Placa',
          helper: 'Como aparece en el carnet de circulación.',
          child: CupoTextInput(
            controller: c.placa,
            hintText: 'AB123CD',
            enabled: habilitado,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9 -]')),
              LengthLimitingTextInputFormatter(9),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CupoField(
                label: 'Marca',
                child: CupoTextInput(
                  controller: c.marca,
                  hintText: 'Toyota',
                  enabled: habilitado,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CupoField(
                label: 'Modelo',
                child: CupoTextInput(
                  controller: c.modelo,
                  hintText: 'Hiace',
                  enabled: habilitado,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CupoField(
                label: 'Año (opcional)',
                child: CupoTextInput(
                  controller: c.anio,
                  hintText: '2015',
                  enabled: habilitado,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CupoField(
                label: 'Color',
                child: CupoTextInput(
                  controller: c.color,
                  hintText: 'Blanco',
                  enabled: habilitado,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        CupoField(
          label: 'Puestos para pasajeros',
          helper: 'Sin contar el tuyo. Ningún turno podrá ofrecer más.',
          child: ValueListenableBuilder<int>(
            valueListenable: c.capacidad,
            builder: (context, valor, _) => SelectorCapacidad(
              valor: valor,
              onCambiar: habilitado ? (v) => c.capacidad.value = v : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// «−  14  +»: la capacidad del vehículo, entre los límites de
/// [ReglasVehiculo].
class SelectorCapacidad extends StatelessWidget {
  const SelectorCapacidad({
    super.key,
    required this.valor,
    required this.onCambiar,
  });

  final int valor;

  /// `null` lo deshabilita.
  final ValueChanged<int>? onCambiar;

  @override
  Widget build(BuildContext context) {
    final onCambiar = this.onCambiar;
    final puedeBajar =
        onCambiar != null && valor > ReglasVehiculo.capacidadMinima;
    final puedeSubir =
        onCambiar != null && valor < ReglasVehiculo.capacidadMaxima;

    return Container(
      height: AppSizes.field,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Row(
        children: [
          _BotonPaso(
            icono: LucideIcons.minus,
            mensaje: 'Un puesto menos',
            onPressed: puedeBajar ? () => onCambiar(valor - 1) : null,
          ),
          Expanded(
            child: Text(
              '$valor ${valor == 1 ? 'puesto' : 'puestos'}',
              style: AppTypography.bodyStrong,
              textAlign: TextAlign.center,
            ),
          ),
          _BotonPaso(
            icono: LucideIcons.plus,
            mensaje: 'Un puesto más',
            onPressed: puedeSubir ? () => onCambiar(valor + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _BotonPaso extends StatelessWidget {
  const _BotonPaso({
    required this.icono,
    required this.mensaje,
    required this.onPressed,
  });

  final IconData icono;
  final String mensaje;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final activo = onPressed != null;

    return IconButton(
      tooltip: mensaje,
      onPressed: onPressed,
      icon: Icon(
        icono,
        size: AppSizes.icon,
        color: activo ? AppColors.primaryDeep : AppColors.textSupportSoft,
      ),
      style: IconButton.styleFrom(
        backgroundColor: activo
            ? AppColors.backgroundMuted
            : AppColors.backgroundAlt,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
    );
  }
}
