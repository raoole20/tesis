import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_scope.dart';
import '../data/conductor_repository.dart';
import '../domain/licencia.dart';
import '../domain/vehiculo.dart';
import 'campos_vehiculo.dart';

/// Nombre de los pasos del perfil, para [CupoStepIndicator].
const List<String> pasosDelPerfilConductor = ['Tu licencia', 'Tu vehículo'];

enum _Paso { licencia, vehiculo }

/// «Completa tu perfil de conductor» (`DestinoAuth.perfilConductor`, HU-004).
///
/// Dos pasos con el mismo indicador del perfil del estudiante: primero la
/// licencia, después el vehículo. Al enviar:
/// 1. guarda número y vencimiento de la licencia en `conductores`;
/// 2. registra el vehículo en `vehiculos` (o lo actualiza si ya existía);
/// 3. llama a `enviar_a_revision()`, que exige las dos cosas;
/// 4. el `AuthGate` ve `estado = 'pendiente'` por Realtime y lleva a «Tu
///    registro está en revisión».
///
/// Sirve también para reenviar una cuenta rechazada: precarga lo guardado.
class PerfilConductorScreen extends StatefulWidget {
  const PerfilConductorScreen({
    super.key,
    this.repositorio,
    this.autenticacion,
    this.hoy,
  });

  /// Por omisión, el de Supabase. Las pruebas pasan uno falso.
  final ConductorRepository? repositorio;

  /// Por omisión, el del [AuthScope]. Las pruebas pasan uno falso.
  final AuthRepository? autenticacion;

  /// Por omisión, la fecha del teléfono. Decide si la licencia está vigente.
  final DateTime? hoy;

  @override
  State<PerfilConductorScreen> createState() => _PerfilConductorScreenState();
}

class _PerfilConductorScreenState extends State<PerfilConductorScreen> {
  late final ConductorRepository _repo =
      widget.repositorio ?? ConductorRepository();

  final _numero = TextEditingController();
  final _vence = TextEditingController();
  final _vehiculo = VehiculoControladores();

  _Paso _paso = _Paso.licencia;

  /// El vehículo ya guardado: si el envío falla después de registrarlo, el
  /// reintento lo actualiza en vez de chocar con la placa repetida.
  Vehiculo? _guardado;
  bool _enviando = false;
  String? _error;

  DateTime get _hoy => widget.hoy ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _precargar();
  }

  @override
  void dispose() {
    _numero.dispose();
    _vence.dispose();
    _vehiculo.dispose();
    super.dispose();
  }

  /// Lo ya guardado, si hubo un envío anterior. Si falla, el formulario
  /// queda vacío: no hay que trancar a quien se registra por primera vez.
  Future<void> _precargar() async {
    try {
      final licencia = await _repo.miLicencia();
      final vehiculo = await _repo.miVehiculo();
      if (!mounted) return;
      setState(() {
        _numero.text = licencia.numero ?? '';
        final vence = licencia.venceEn;
        if (vence != null) _vence.text = ReglasLicencia.escribirFecha(vence);
        if (vehiculo != null) {
          _guardado = vehiculo;
          _vehiculo.placa.text = vehiculo.placa;
          _vehiculo.marca.text = vehiculo.marca;
          _vehiculo.modelo.text = vehiculo.modelo;
          _vehiculo.anio.text = vehiculo.anio?.toString() ?? '';
          _vehiculo.color.text = vehiculo.color;
          _vehiculo.capacidad.value = vehiculo.capacidad;
        }
      });
    } catch (_) {
      // Formulario vacío.
    }
  }

  String? _validarLicencia() =>
      ReglasLicencia.validarNumero(_numero.text) ??
      ReglasLicencia.validarVencimiento(_vence.text, hoy: _hoy);

  void _continuar() {
    final falta = _validarLicencia();
    setState(() {
      _error = falta;
      if (falta == null) _paso = _Paso.vehiculo;
    });
    if (falta == null) FocusScope.of(context).unfocus();
  }

  void _atras() {
    if (_enviando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _paso = _Paso.licencia;
    });
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    final falta = _vehiculo.validar(anioActual: _hoy.year);
    if (falta != null) {
      setState(() => _error = falta);
      return;
    }

    FocusScope.of(context).unfocus();
    final autenticacion =
        widget.autenticacion ?? AuthScope.de(context).repositorio;
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await _repo.guardarLicencia(
        numero: _numero.text,
        venceEn: ReglasLicencia.leerFecha(_vence.text)!,
      );
      _guardado = await _repo.guardarVehiculo(
        _vehiculo.borrador(),
        id: _guardado?.id,
      );
      await autenticacion.enviarARevision();
      // No se cambia de pantalla aquí: el AuthGate lo hace al ver el estado
      // nuevo. Mientras tanto el botón sigue cargando.
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _enviando = false;
        });
      }
    }
  }

  void _cerrarSesion() => AuthScope.de(context).repositorio.salir();

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final enLicencia = _paso == _Paso.licencia;

    return PopScope(
      canPop: enLicencia,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _atras();
      },
      child: CupoScreen(
        topGap: AppSpacing.md,
        leading: enLicencia
            ? null
            : CupoSheetHeader(title: 'Completa tu perfil', onBack: _atras),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null) ...[
              CupoErrorBanner(mensaje: error),
              const SizedBox(height: AppSpacing.md),
            ],
            if (enLicencia)
              CupoPrimaryButton(label: 'Continuar', onPressed: _continuar)
            else
              CupoPrimaryButton(
                label: 'Enviar a revisión',
                isLoading: _enviando,
                onPressed: _enviar,
              ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: CupoLink(label: 'Cerrar sesión', onPressed: _cerrarSesion),
            ),
          ],
        ),
        children: enLicencia ? _pasoLicencia() : _pasoVehiculo(),
      ),
    );
  }

  List<Widget> _pasoLicencia() {
    return [
      const SizedBox(height: AppSpacing.xs),
      const CupoStepIndicator(pasos: pasosDelPerfilConductor, actual: 0),
      const SizedBox(height: AppSpacing.xl),
      Text('Completa tu perfil', style: AppTypography.title),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'El administrador revisa tu licencia y tu vehículo antes de que '
        'puedas ofrecer cupos.',
        style: AppTypography.body,
      ),
      const SizedBox(height: AppSpacing.xl),
      CupoField(
        label: 'Número de licencia',
        child: CupoTextInput(
          controller: _numero,
          hintText: 'V-12345678',
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      CupoField(
        label: 'Vence el',
        helper: 'Tiene que estar vigente.',
        child: CupoTextInput(
          controller: _vence,
          hintText: 'DD/MM/AAAA',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: const [_FormatoFecha()],
        ),
      ),
    ];
  }

  List<Widget> _pasoVehiculo() {
    return [
      const CupoStepIndicator(pasos: pasosDelPerfilConductor, actual: 1),
      const SizedBox(height: AppSpacing.xl),
      Text('¿En qué llevas a los estudiantes?', style: AppTypography.title),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Los estudiantes ven la placa, el modelo y el color antes de '
        'pedirte un cupo.',
        style: AppTypography.body,
      ),
      const SizedBox(height: AppSpacing.xl),
      CamposVehiculo(controladores: _vehiculo, habilitado: !_enviando),
    ];
  }
}

/// Pone las barras de DD/MM/AAAA mientras se escribe: «15032027» se ve como
/// «15/03/2027».
class _FormatoFecha extends TextInputFormatter {
  const _FormatoFecha();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final digitos = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final recortados = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final texto = StringBuffer();
    for (var i = 0; i < recortados.length; i++) {
      if (i == 2 || i == 4) texto.write('/');
      texto.write(recortados[i]);
    }
    final resultado = texto.toString();
    return TextEditingValue(
      text: resultado,
      selection: TextSelection.collapsed(offset: resultado.length),
    );
  }
}
