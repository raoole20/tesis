---
name: revisar-codigo
description: Revisión de código (code review) del repositorio Cupo. Valida que el cambio respete las reglas de CLAUDE.md —colores solo desde AppColors, tipografía solo desde AppTypography (Manrope, Caveat solo en el logotipo), espaciado en múltiplos de 4, radios y elevación del tema, estados semánticos, light-only, UI en español es-VE— y las buenas prácticas de Flutter/Dart y Supabase (ciclo de vida y dispose, async con mounted, capas data/domain/presentation, RLS, pruebas, accesibilidad). Úsala siempre que pidan revisar, auditar o validar código, un diff, una rama, un PR o un commit de este repo; cuando pregunten "¿está bien esto?", "¿cumple las reglas?", "¿puedo commitear/mergear?"; antes de abrir un PR; o cuando digan "code review", "revisión", "revisa mis cambios" o "/revisar-codigo", aunque no mencionen CLAUDE.md. Acepta argumentos opcionales: rutas, una rama o ref base, un número de PR, --todo y --corregir.
---

# Revisión de código — Cupo

Esta revisión existe para que nada entre al repositorio rompiendo la identidad
visual o las convenciones del proyecto, y para atrapar los errores típicos de
Flutter antes de que lleguen al teléfono. Es una tesis: el código también es
evidencia ante el jurado, así que la consistencia y las pruebas pesan.

Hay dos mitades y las dos hacen falta:

- **Automática**: un script revisa las reglas mecánicas de `CLAUDE.md` (literales
  de color, fuentes, espaciado, radios, secretos, RLS…) y además se corren
  `flutter analyze` y `flutter test`. Es rápida y no se cansa.
- **Manual**: lo que un patrón no ve —si un `setState` puede correr tras un
  `dispose`, si un estado se comunica solo con color, si la lógica está en la
  capa correcta, si el texto suena venezolano—. Para eso están las guías de
  `references/`.

## 1. Determinar el alcance

Interpreta los argumentos así (todo es opcional):

| Argumento | Qué se revisa | Opción del script |
| --- | --- | --- |
| *(nada)* | Cambios sin commitear (staged, unstaged y archivos nuevos) | *(ninguna)* |
| `master`, `origin/master`, un hash… | Lo que cambió desde que la rama se separó de esa ref, más lo no commiteado | `--base <ref>` |
| `#12` o `12` | El diff del PR: `gh pr diff 12` y `gh pr checkout 12` si hace falta correr pruebas | `--base <base del PR>` |
| una o más rutas | Esos archivos o carpetas completos | las rutas |
| `--todo` | Todo `cupo/lib`, `cupo/test`, `supabase/migrations` y `docs` | `--todo` |
| `--corregir` | Además de revisar, aplicar las correcciones (paso 6) | — |

Si no hay argumentos y el árbol está limpio: en una rama distinta de `master`
revisa contra `master`; en `master`, revisa el último commit (`--base HEAD~1`)
y dilo en el informe.

Saca la lista de archivos y el diff (`git diff <ref>`, `git status --short`)
antes de seguir. Si no hay ningún cambio, dilo y termina.

## 2. Verificaciones automáticas

Lánzalas en paralelo desde la raíz del repositorio:

```bash
# Reglas de CLAUDE.md sobre las líneas cambiadas
dart .claude/skills/revisar-codigo/scripts/verificar_reglas.dart [opciones]

# Análisis estático (incluye flutter_lints y strict-casts/strict-raw-types)
cd cupo && flutter analyze

# Pruebas — solo si cambió algo en cupo/lib o cupo/test
cd cupo && flutter test

# Formato de los .dart cambiados (no reescribe nada)
cd cupo && dart format --output=none --set-exit-if-changed <archivos .dart>
```

Sobre el script:

- Sale con código **1 cuando encuentra bloqueantes**; no es que haya fallado.
  Código 2 es un error de uso.
- Por defecto solo informa lo que cae en **líneas cambiadas**: la revisión es
  del cambio, no de la deuda vieja.
- Sus hallazgos son pistas fuertes, no veredictos. Abre cada uno y confírmalo
  con el código a la vista antes de ponerlo en el informe; si es un falso
  positivo, descártalo (y si se repite, vale la pena mejorar el script).
- Un hallazgo justificado se silencia en el código con
  `// cupo-ignore: <REGLA> <motivo>` en la misma línea o la anterior. Si ves uno
  nuevo, juzga si el motivo se sostiene.

Si `flutter analyze` o `flutter test` fallan por algo del cambio, eso es
**bloqueante**. Si fallan por algo previo, repórtalo aparte y no lo cargues al
cambio.

## 3. Revisión manual

Lee el diff completo y, para cada archivo `.dart` cambiado, el archivo entero:
los errores de ciclo de vida y de capas solo se ven con el contexto completo
(dónde se crea un controller, dónde se libera, quién llama a quién).

Luego recorre las guías, según lo que toque el cambio:

- **Siempre**: [references/reglas-cupo.md](references/reglas-cupo.md) — las
  reglas del repositorio, con ejemplos y excepciones aceptadas.
- **Si cambió Dart**: [references/flutter-buenas-practicas.md](references/flutter-buenas-practicas.md)
  — ciclo de vida, async, estado, layout, accesibilidad, rendimiento y pruebas.
- **Si cambió `supabase/migrations/`**: la sección *Supabase y migraciones* de
  `reglas-cupo.md`.
- **Si cambió material visual** (`docs/**/*.html`, `.svg`, diagramas, capturas):
  la sección *Material visual* de `reglas-cupo.md`.

Antes de inventar una solución, busca si ya existe una pieza que lo resuelva:
`AppSpacing`, `AppRadius`, `AppSizes`, los estilos con nombre de
`AppTypography` y los widgets `Cupo*` de `cupo/lib/shared/widgets/`. Lo más
común en este repo es reimplementar algo que ya está.

Reporta solo lo que puedas señalar con archivo y línea y explicar con un
escenario concreto ("si la persona cierra la pantalla mientras carga, el
`setState` de la línea 88 corre sobre un State desmontado"). Nada de "podría
mejorarse" sin decir qué y por qué.

Si el cambio supera ~20 archivos, puedes repartir la revisión manual por
feature entre subagentes, pasándoles esta guía y las referencias.

## 4. Severidad

- **Bloqueante** — No debe entrar así. Viola una regla explícita de
  `CLAUDE.md` (literal de color, fuente fuera de `AppTypography`, `fromSeed`,
  tema oscuro improvisado), expone secretos o deja una tabla sin RLS, rompe
  `flutter analyze`/`flutter test`, o es un bug con escenario claro.
- **Importante** — Debería corregirse en este cambio: fugas (controller sin
  `dispose`, suscripción sin `cancel`), `setState`/`context` tras `await` sin
  `mounted`, lógica en la capa equivocada, consulta creada dentro de `build`,
  lógica de dominio sin prueba, espaciado fuera de la escala de 4.
- **Sugerencia** — Mejora de consistencia, legibilidad o accesibilidad que no
  bloquea: usar el token en vez del número equivalente, `MediaQuery.sizeOf`,
  tooltip en un `IconButton`, prueba de widget para una pantalla nueva.

## 5. Informe

Escríbelo en español, con este formato. Los enlaces van como
`[archivo.dart:42](cupo/lib/ruta/archivo.dart#L42)`, relativos a la raíz.

```markdown
## Revisión de código — <alcance en una línea>

**Veredicto:** ✅ Listo para integrar | ⚠️ Integrable con cambios menores | ⛔ Requiere cambios

| Verificación | Resultado |
| --- | --- |
| Reglas de CLAUDE.md (script) | N bloqueantes · N importantes · N sugerencias |
| flutter analyze | ✓ sin problemas / ✗ N problemas |
| flutter test | ✓ N pruebas / ✗ N fallan / — no aplica |
| Formato | ✓ / ✗ archivos sin formatear |

### ⛔ Bloqueantes
1. **[R1 · Color literal]** [archivo.dart:42](cupo/lib/...#L42) — Qué pasa y por
   qué importa, en una o dos frases.
   ```dart
   // Corrección propuesta, corta
   ```

### ⚠️ Importantes
…

### 💡 Sugerencias
…

### Fuera del cambio
Problemas previos que aparecieron al revisar (solo si son relevantes). No
cuentan para el veredicto.

### Lo que está bien
Una o dos líneas sobre lo que el cambio hace bien, si hay algo que valga la
pena reforzar (p. ej. "la función nueva es pura y tiene sus pruebas").
```

Omite las secciones vacías. Ordena cada sección por gravedad real, no por
archivo. Si no hay hallazgos, dilo en una línea con el veredicto y la tabla.

El veredicto se sigue de los hallazgos: algún bloqueante → ⛔; solo importantes
→ ⚠️; solo sugerencias o nada → ✅.

## 6. Corregir (solo con `--corregir` o si lo piden)

Por defecto la revisión **no edita archivos**: el autor decide. Si piden
corregir:

1. Aplica primero los bloqueantes y luego los importantes; las sugerencias
   solo si son triviales o las piden.
2. Corrige con las piezas existentes (tokens, widgets `Cupo*`, repositorio)
   antes que con código nuevo. Si hace falta un token nuevo, agrégalo en
   `cupo/lib/theme/` **y** en la tabla de `CLAUDE.md` (regla 4).
3. Vuelve a correr el script, `flutter analyze` y `flutter test`, y presenta el
   informe actualizado marcando qué se corrigió y qué quedó pendiente.
4. No hagas commit salvo que lo pidan.
