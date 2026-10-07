import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import 'search_results_screen.dart';

/// 05 — Mis días y turno.
///
/// Selección de días en cuadrícula multiselección y turno único de clases.
class SearchFiltersScreen extends StatefulWidget {
  const SearchFiltersScreen({super.key, this.zoneName = 'Amparo'});

  final String zoneName;

  @override
  State<SearchFiltersScreen> createState() => _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends State<SearchFiltersScreen> {
  // Días seleccionados por defecto: Lunes, Martes, Jueves (según el mockup)
  final Set<String> _selectedDays = {'Lun', 'Mar', 'Jue'};

  // Turno seleccionado: Diurno, Vespertino, Nocturno
  String _selectedShift = 'Vespertino';

  static const List<Map<String, String>> _days = [
    {'initial': 'L', 'name': 'Lun'},
    {'initial': 'M', 'name': 'Mar'},
    {'initial': 'M', 'name': 'Mié'},
    {'initial': 'J', 'name': 'Jue'},
    {'initial': 'V', 'name': 'Vie'},
  ];

  static const List<Map<String, String>> _shifts = [
    {'title': 'Diurno', 'hours': 'Entras 7:00 am · sales 12:00 m'},
    {'title': 'Vespertino', 'hours': 'Entras 1:00 pm · sales 5:00 pm'},
    {'title': 'Nocturno', 'hours': 'Entras 6:00 pm · sales 9:30 pm'},
  ];

  void _search() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchResultsScreen(
          zoneName: widget.zoneName,
          selectedDays: _selectedDays.toList(),
          shiftName: _selectedShift,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupoScreen(
      leading: const CupoBackButton(),
      footer: CupoPrimaryButton(
        label: 'Buscar transportes',
        onPressed: _search,
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text('¿Qué días vas a la U?', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text('Marca todos los que necesites.', style: AppTypography.body),
        const SizedBox(height: AppSpacing.lg),

        // Cuadrícula de 5 días
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _days.map((day) {
            final isSelected = _selectedDays.contains(day['name']);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_selectedDays.length > 1) {
                          _selectedDays.remove(day['name']);
                        }
                      } else {
                        _selectedDays.add(day['name']!);
                      }
                    });
                  },
                  borderRadius: AppRadius.smAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: AppRadius.smAll,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          day['initial']!,
                          style: AppTypography.manrope(
                            size: 19,
                            weight: FontWeight.w800,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day['name']!,
                          style: AppTypography.manrope(
                            size: 13,
                            weight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.textSecondary,
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

        const SizedBox(height: AppSpacing.xxl),

        Text('¿En cuál turno?', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('Elige uno solo.', style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.md),

        // Opciones de turno
        Column(
          children: _shifts.map((shift) {
            final isSelected = _selectedShift == shift['title'];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () => setState(() => _selectedShift = shift['title']!),
                borderRadius: AppRadius.smAll,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primarySoft
                        : AppColors.surface,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSupport,
                            width: 2,
                          ),
                          color: isSelected ? AppColors.primary : null,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shift['title']!,
                              style: AppTypography.manrope(
                                size: 16,
                                weight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.primaryDarkest
                                    : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shift['hours']!,
                              style: AppTypography.manrope(
                                size: 13,
                                weight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Destino fijo URBE
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundAlt,
            borderRadius: AppRadius.smAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destino',
                      style: AppTypography.manrope(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.textSupport,
                      ),
                    ),
                    Text(
                      'Sede URBE, Maracaibo',
                      style: AppTypography.manrope(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'fijo',
                  style: AppTypography.manrope(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
