import 'package:flutter/material.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../../../theme/theme.dart';

/// Lo que se ve mientras la app resuelve si hay sesión y lee la fila de
/// `usuarios`.
///
/// Dura poco, pero existe: sin ella, al abrir la app se vería un parpadeo de
/// la bienvenida antes de saltar al inicio de quien ya tenía sesión.
class CargandoScreen extends StatelessWidget {
  const CargandoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupoLockup(),
            SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
