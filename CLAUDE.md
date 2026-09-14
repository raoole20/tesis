# CLAUDE.md — Cupo

Guía obligatoria para cualquier código, pantalla, documento o material visual que
se genere en este repositorio. Todo lo nuevo debe respetar esta identidad.

## Estructura

- `cupo/` — app Flutter (Dart, Material 3, Firebase).
- `cupo/lib/theme/` — sistema de diseño. **Única** fuente de color y tipografía.
- `docs/producto/` — documentación de producto y modelo de datos.
- `docs/tesis/` — documentación académica.

## Identidad visual

### Tipografía

| Familia | Pesos | Uso |
| --- | --- | --- |
| **Manrope** | 400–800 | Toda la UI: títulos, cuerpo, botones, etiquetas |
| **Caveat** | 700 | **Solo** el logotipo "Cupo" |

- En Flutter se cargan con `google_fonts` desde `AppTypography`.
- Caveat solo se usa vía `AppTypography.logo()`. Cualquier otro uso es un error.
- Nunca introduzcas una tercera familia tipográfica.

### Color

La fuente de verdad es OkLCH; el hex es la expresión en sRGB usada en Dart.

**Verde lago (primario)**

| Token | OkLCH | Hex | Uso |
| --- | --- | --- | --- |
| `primary` | `oklch(0.460 0.09 195)` | `#007C8A` | Botones, símbolo, acentos |
| `primaryHover` | `oklch(0.400 0.09 195)` | `#006B78` | Hover / pressed |
| `primaryDeep` | `oklch(0.360 0.09 195)` | `#005F6C` | Texto de marca sobre fondo claro |
| `primaryDarkest` | `oklch(0.240 0.09 195)` | `#003D4B` | Texto de marca de máximo contraste |
| `primarySoft` | `oklch(0.965 0.018 195)` | `#E7F4F5` | Fondo suave de bloques informativos |

**Neutros**

| Token | OkLCH | Hex | Uso |
| --- | --- | --- | --- |
| `ink` | `oklch(0.2 0.01 200)` | `#1C2224` | Tinta, texto principal |
| `textSecondary` | `oklch(0.46 0.01 200)` | `#5F6A6C` | Texto secundario |
| `textSupport` | `oklch(0.55 0.01 200)` | `#798487` | Apoyo |
| `textSupportSoft` | `oklch(0.60 0.01 200)` | `#889396` | Apoyo de menor jerarquía, hints |
| `border` | `oklch(0.89 0.006 200)` | `#DDE0E0` | Bordes y divisores |
| `background` | `oklch(0.975 0.004 200)` | `#F9FCFC` | Fondo base |
| `backgroundAlt` | `oklch(0.965 0.004 200)` | `#F6F9F9` | Fondo alterno |
| `surface` | — | `#FFFFFF` | Tarjetas y hojas |

**Semánticos**

| Token | OkLCH | Hex | Uso |
| --- | --- | --- | --- |
| `success` | `oklch(0.55 0.13 150)` | `#18A06A` | Confirmado |
| `successSoft` | `oklch(0.95 0.05 150)` | `#D3F9E3` | Fondo de confirmado |
| `warning` | `oklch(0.62 0.14 88)` | `#C98A00` | Pendiente / próximo a vencer |
| `warningSoft` | `oklch(0.95 0.06 88)` | `#FFEAC2` | Fondo de pendiente |
| `danger` | `oklch(0.55 0.16 25)` | `#BD413F` | Error / cancelado *(derivado, la marca no lo define)* |
| `dangerSoft` | `oklch(0.95 0.05 25)` | `#FFE2DE` | Fondo de error |

> Los hex de `primary`, `primaryHover`, `primarySoft`, `ink`, `textSecondary`,
> `border`, `success` y `warning` son los aprobados por marca. Los demás se
> derivaron de los mismos valores OkLCH manteniendo la familia de tono.

## Reglas al escribir código

1. **Nunca** escribas un literal de color (`Color(0xFF...)`, `Colors.blue`) fuera
   de `cupo/lib/theme/app_colors.dart`. Usa `AppColors.*` o
   `Theme.of(context).colorScheme.*`.
2. **Nunca** declares `fontFamily`, `GoogleFonts.*` ni `TextStyle` con fuente
   fuera de `cupo/lib/theme/app_typography.dart`. Usa
   `Theme.of(context).textTheme.*` o `AppTypography.manrope(...)`.
3. `ColorScheme.fromSeed` está prohibido: el esquema es explícito en
   `AppTheme.colorScheme`.
4. Un tono nuevo se agrega primero como token en `AppColors` (con su OkLCH en el
   comentario) y se documenta en esta tabla; recién entonces se usa.
5. Radio de esquina estándar: `AppTheme.radius` (12). Elevación por defecto: 0;
   la jerarquía se expresa con `border` y `backgroundAlt`, no con sombras.
6. Espaciado en múltiplos de 4; el padding de pantalla es 16–24.
7. Estados en listas y tarjetas: confirmado → `success` sobre `successSoft`;
   pendiente/vencimiento → `warning` sobre `warningSoft`; error → `danger` sobre
   `dangerSoft`.
8. La app es *light-only* por ahora. Si se agrega tema oscuro, se define como
   `AppTheme.dark` con tokens propios, nunca invirtiendo colores al vuelo.
9. Texto de UI en español (es-VE).

## Reglas al generar material visual y documentos

Mockups, diagramas, presentaciones, capturas y documentos del proyecto usan la
misma paleta y tipografías: Manrope para todo el texto, Caveat 700 únicamente
para el logotipo "Cupo", verde lago como color de acento y los neutros de arriba
para fondos y texto.

## Comandos

```bash
cd cupo
flutter pub get
flutter analyze
flutter test
flutter run
```
