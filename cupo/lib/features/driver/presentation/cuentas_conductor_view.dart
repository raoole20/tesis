import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../auth/presentation/cuenta/boton_de_cuenta.dart';
import '../domain/semana_del_conductor.dart';
import '../domain/turno_del_conductor.dart';

/// «Cuentas» — quién le debe al conductor esta semana y quién ya pagó.
///
/// **Prototipo** con [CuentasDelConductor.ejemplo]. «Marcar pagado» cambia
/// solo el estado de esta pantalla: no se guarda en ninguna parte hasta que
/// existan los cobros en la base.
class CuentasConductorView extends StatefulWidget {
  const CuentasConductorView({
    super.key,
    required this.turno,
    this.cuentas = CuentasDelConductor.ejemplo,
  });

  final TurnoDelConductor turno;
  final CuentasDelConductor cuentas;

  @override
  State<CuentasConductorView> createState() => _CuentasConductorViewState();
}

class _CuentasConductorViewState extends State<CuentasConductorView> {
  /// Ids de los pasajeros que ya pagaron, empezando por los del ejemplo.
  late final Set<String> _pagados = {
    for (final s in widget.cuentas.saldos)
      if (s.pagado) s.idPasajero,
  };

  static String _dolares(double monto) =>
      '\$${monto.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final filas = CuentasDelConductor.conPasajeros(
      widget.turno,
      widget.cuentas.saldos,
    );
    final pendientes = [
      for (final f in filas)
        if (!_pagados.contains(f.$1.id)) f,
    ];
    final pagados = [
      for (final f in filas)
        if (_pagados.contains(f.$1.id)) f,
    ];
    double suma(List<(PasajeroDelDia, SaldoDePasajero)> l) =>
        l.fold(0, (total, f) => total + f.$2.monto);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          CupoTabHeader(
            titulo: 'Tus cuentas',
            detalle: 'Cierras el ${widget.cuentas.cierre}',
            accion: const BotonDeCuenta(),
          ),
          const SizedBox(height: AppSpacing.md),
          _Totales(
            porCobrar: _dolares(suma(pendientes)),
            cobrado: _dolares(suma(pagados)),
            conSaldo: pendientes.length,
            precio: _dolares(widget.cuentas.precioSemanal),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Por cobrar', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (pendientes.isEmpty)
            Text('Nadie te debe esta semana.', style: AppTypography.meta),
          for (final (pasajero, saldo) in pendientes) ...[
            _FilaSaldo(
              pasajero: pasajero,
              detalle: saldo.detalle,
              monto: _dolares(saldo.monto),
              pagado: false,
              onMarcar: () => setState(() => _pagados.add(pasajero.id)),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Pagaron', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final (pasajero, saldo) in pagados) ...[
            _FilaSaldo(
              pasajero: pasajero,
              detalle: saldo.pagado ? saldo.detalle : 'Marcado por ti',
              monto: _dolares(saldo.monto),
              pagado: true,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vista de ejemplo: los saldos son de prueba y lo que marques no '
            'se guarda hasta que se construyan los cobros.',
            style: AppTypography.helper,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Totales extends StatelessWidget {
  const _Totales({
    required this.porCobrar,
    required this.cobrado,
    required this.conSaldo,
    required this.precio,
  });

  final String porCobrar;
  final String cobrado;
  final int conSaldo;
  final String precio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Por cobrar', style: AppTypography.meta),
                    Text(porCobrar, style: textos.headlineSmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cobrado', style: AppTypography.meta),
                    Text(
                      cobrado,
                      style: textos.headlineSmall?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$conSaldo ${conSaldo == 1 ? 'pasajero' : 'pasajeros'} con saldo '
            '· $precio por semana cada uno',
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}

class _FilaSaldo extends StatelessWidget {
  const _FilaSaldo({
    required this.pasajero,
    required this.detalle,
    required this.monto,
    required this.pagado,
    this.onMarcar,
  });

  final PasajeroDelDia pasajero;
  final String detalle;
  final String monto;
  final bool pagado;
  final VoidCallback? onMarcar;

  @override
  Widget build(BuildContext context) {
    final onMarcar = this.onMarcar;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.border),
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.choiceIconTile,
            height: AppSizes.choiceIconTile,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              pasajero.iniciales,
              style: AppTypography.label.copyWith(color: AppColors.primaryDeep),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pasajero.nombre,
                  style: AppTypography.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(detalle, style: AppTypography.meta),
                if (onMarcar != null)
                  CupoLink(label: 'Marcar pagado', onPressed: onMarcar),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(monto, style: AppTypography.bodyStrong),
              const SizedBox(height: AppSpacing.xxs),
              pagado
                  ? const CupoStatusChip.exito(
                      texto: 'Pagado',
                      icono: LucideIcons.circleCheck,
                    )
                  : const CupoStatusChip.pendiente(texto: 'Pendiente'),
            ],
          ),
        ],
      ),
    );
  }
}
