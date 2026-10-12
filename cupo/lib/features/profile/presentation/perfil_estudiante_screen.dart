import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/geo/zonas_maracaibo.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../auth/presentation/auth_scope.dart';
import '../../onboarding/presentation/mapa_domicilio.dart';

/// Nombre de los pasos del perfil, para [CupoStepIndicator].
const List<String> pasosDelPerfilEstudiante = ['Tus estudios', 'Tu casa'];

/// Lo que el estudiante llena en su perfil, listo para enviarse a revisión.
class PerfilEstudianteBorrador {
  const PerfilEstudianteBorrador({
    required this.universidad,
    required this.carrera,
    required this.carnet,
    required this.domicilio,
    required this.referencia,
  });

  final String universidad;
  final String carrera;
  final String carnet;
  final LatLng domicilio;

  /// Punto de referencia o sector. Vacío si no lo escribió.
  final String referencia;

  ZonaCobertura? get zona => zonaDeCobertura(domicilio);
}

enum _Paso { estudios, casa, listo }

/// «Completa tu perfil de estudiante» (`DestinoAuth.perfilEstudiante`).
///
/// Dos pasos con el mismo indicador del registro: primero universidad,
/// carrera y carnet; después la casa, marcada en el mapa con un toque o con
/// el GPS. Al terminar muestra un resumen.
///
/// **Todavía no habla con la base.** El envío arma un
/// [PerfilEstudianteBorrador] y lo muestra; cuando se conecte, `_enviar` debe
/// guardar las columnas de `estudiantes` que permite el grant (universidad,
/// carrera, carnet, domicilio y sus textos) y llamar a `enviar_a_revision()`.
/// El `AuthGate` llevará entonces a «Tu registro está en revisión».
class PerfilEstudianteScreen extends StatefulWidget {
  const PerfilEstudianteScreen({super.key, this.pinInicial});

  /// Casa ya marcada al abrir el paso del mapa. Las pruebas lo usan para no
  /// depender de un toque sobre las teselas.
  final LatLng? pinInicial;

  @override
  State<PerfilEstudianteScreen> createState() => _PerfilEstudianteScreenState();
}

class _PerfilEstudianteScreenState extends State<PerfilEstudianteScreen> {
  // Cupo atiende hoy a la comunidad de la URBE: se precarga y se puede
  // cambiar.
  final _universidad = TextEditingController(text: 'URBE');
  final _carrera = TextEditingController();
  final _carnet = TextEditingController();
  final _referencia = TextEditingController();

  _Paso _paso = _Paso.estudios;
  late LatLng? _pin = widget.pinInicial;
  PerfilEstudianteBorrador? _enviado;
  String? _error;

  @override
  void dispose() {
    _universidad.dispose();
    _carrera.dispose();
    _carnet.dispose();
    _referencia.dispose();
    super.dispose();
  }

  String? _validarEstudios() {
    if (_universidad.text.trim().isEmpty) return 'Escribe tu universidad.';
    if (_carrera.text.trim().isEmpty) return 'Escribe tu carrera.';
    if (_carnet.text.trim().isEmpty) return 'Escribe tu número de carnet.';
    return null;
  }

  void _continuar() {
    final falta = _validarEstudios();
    setState(() {
      _error = falta;
      if (falta == null) _paso = _Paso.casa;
    });
    if (falta == null) FocusScope.of(context).unfocus();
  }

  void _atras() {
    FocusScope.of(context).unfocus();
    setState(() => _paso = _Paso.estudios);
  }

  void _enviar() {
    final pin = _pin;
    if (pin == null) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _enviado = PerfilEstudianteBorrador(
        universidad: _universidad.text.trim(),
        carrera: _carrera.text.trim(),
        carnet: _carnet.text.trim(),
        domicilio: pin,
        referencia: _referencia.text.trim(),
      );
      _paso = _Paso.listo;
    });
  }

  void _cerrarSesion() => AuthScope.de(context).repositorio.salir();

  @override
  Widget build(BuildContext context) {
    final enviado = _enviado;

    return PopScope(
      canPop: _paso != _Paso.casa,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _atras();
      },
      child: switch (_paso) {
        _Paso.estudios => _pasoEstudios(),
        _Paso.casa => _pasoCasa(),
        _Paso.listo when enviado != null => _Resumen(
          perfil: enviado,
          onEditar: _atras,
          onCerrarSesion: _cerrarSesion,
        ),
        _Paso.listo => _pasoEstudios(),
      },
    );
  }

  Widget _pasoEstudios() {
    final error = _error;

    return CupoScreen(
      topGap: AppSpacing.xl,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            CupoErrorBanner(mensaje: error),
            const SizedBox(height: AppSpacing.md),
          ],
          CupoPrimaryButton(label: 'Continuar', onPressed: _continuar),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: CupoLink(label: 'Cerrar sesión', onPressed: _cerrarSesion),
          ),
        ],
      ),
      children: [
        const CupoStepIndicator(pasos: pasosDelPerfilEstudiante, actual: 0),
        const SizedBox(height: AppSpacing.xl),
        Text('Completa tu perfil', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'El administrador revisa que estudies donde dices antes de '
          'habilitar tu cuenta.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.xl),
        CupoField(
          label: 'Universidad',
          child: CupoTextInput(
            controller: _universidad,
            hintText: 'URBE',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CupoField(
          label: 'Carrera',
          child: CupoTextInput(
            controller: _carrera,
            hintText: 'Ingeniería en Computación',
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CupoField(
          label: 'Número de carnet',
          helper: 'El que aparece en tu carnet estudiantil.',
          child: CupoTextInput(
            controller: _carnet,
            hintText: '20231234',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }

  Widget _pasoCasa() {
    final pin = _pin;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  CupoSheetHeader(title: 'Completa tu perfil', onBack: _atras),
                  const SizedBox(height: AppSpacing.md),
                  const CupoStepIndicator(
                    pasos: pasosDelPerfilEstudiante,
                    actual: 1,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('¿Dónde vives?', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Toca el mapa para marcar tu casa, o usa tu ubicación.',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            Expanded(
              child: MapaDomicilio(
                pin: pin,
                onPin: (punto) => setState(() => _pin = punto),
              ),
            ),
            _PanelCasa(
              pin: pin,
              referencia: _referencia,
              onEnviar: pin == null ? null : _enviar,
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel bajo el mapa: la zona detectada, el punto de referencia y el envío.
class _PanelCasa extends StatelessWidget {
  const _PanelCasa({
    required this.pin,
    required this.referencia,
    required this.onEnviar,
  });

  final LatLng? pin;
  final TextEditingController referencia;
  final VoidCallback? onEnviar;

  @override
  Widget build(BuildContext context) {
    final pin = this.pin;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.screenBottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pin == null)
            Text(
              'Todavía no marcas tu casa.',
              style: AppTypography.helper,
              textAlign: TextAlign.center,
            )
          else ...[
            _AvisoZona(zona: zonaDeCobertura(pin)),
            const SizedBox(height: AppSpacing.md),
            CupoField(
              label: 'Punto de referencia (opcional)',
              child: CupoTextInput(
                controller: referencia,
                hintText: 'Frente a la panadería, casa azul…',
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          CupoPrimaryButton(label: 'Enviar a revisión', onPressed: onEnviar),
        ],
      ),
    );
  }
}

/// La zona de la casa: en `success` si cae en una zona de cobertura, en
/// `warning` si no (regla 7 de CLAUDE.md).
class _AvisoZona extends StatelessWidget {
  const _AvisoZona({required this.zona});

  final ZonaCobertura? zona;

  @override
  Widget build(BuildContext context) {
    final zona = this.zona;
    final dentro = zona != null;
    final tinta = dentro ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: dentro ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Icon(
            dentro ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
            size: AppSizes.iconSmall,
            color: tinta,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              dentro
                  ? 'Zona: ${zona.nombre}'
                  : 'Fuera de las zonas de cobertura por ahora.',
              style: AppTypography.label.copyWith(color: tinta),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cierre del perfil: qué se enviaría a revisión.
class _Resumen extends StatelessWidget {
  const _Resumen({
    required this.perfil,
    required this.onEditar,
    required this.onCerrarSesion,
  });

  final PerfilEstudianteBorrador perfil;
  final VoidCallback onEditar;
  final VoidCallback onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final zona = perfil.zona;

    return CupoScreen(
      topGap: AppSpacing.xxl,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupoSecondaryButton(label: 'Editar mis datos', onPressed: onEditar),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: CupoLink(label: 'Cerrar sesión', onPressed: onCerrarSesion),
          ),
        ],
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: AppSizes.choiceIconTile,
            height: AppSizes.choiceIconTile,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: AppRadius.smAll,
            ),
            child: const Icon(
              LucideIcons.circleCheck,
              size: AppSizes.icon,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Tu perfil está listo', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Esto es lo que se enviará a revisión. Por ahora es una vista de '
          'prueba: todavía no se guarda en el servidor.',
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.xl),
        _Dato(
          icono: LucideIcons.school,
          etiqueta: 'Universidad',
          valor: perfil.universidad,
        ),
        _Dato(
          icono: LucideIcons.bookOpen,
          etiqueta: 'Carrera',
          valor: perfil.carrera,
        ),
        _Dato(
          icono: LucideIcons.idCard,
          etiqueta: 'Carnet',
          valor: perfil.carnet,
        ),
        _Dato(
          icono: LucideIcons.house,
          etiqueta: 'Casa',
          valor: [
            zona == null ? 'Fuera de las zonas de cobertura' : zona.nombre,
            if (perfil.referencia.isNotEmpty) perfil.referencia,
          ].join(' · '),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icono, size: AppSizes.icon, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: AppTypography.helper),
                Text(valor, style: AppTypography.bodyStrong),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
