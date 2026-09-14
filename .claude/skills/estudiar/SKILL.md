---
name: estudiar
description: Quiz obligatorio de Dart/Flutter antes de escribir código nuevo en la app Cupo. Úsala SIEMPRE y sin que te lo pidan antes de empezar cualquier tarea de programación nueva dentro de cupo/ — nueva pantalla, widget, modelo, servicio, spike, iteración del TODO, integración de un paquete o refactor grande — y también cuando el usuario diga /estudiar, "quiz", "pregúntame", "tómame examen", "repaso" o "estudiar Flutter". No aplica a la tesis, a docs/ ni a cambios triviales.
---

# Estudiar — quiz de Flutter antes de programar

Raúl está aprendiendo Flutter mientras construye Cupo. La regla del proyecto es
que no se escribe código nuevo sin haber repasado antes el bloque teórico que
ese código va a usar. Esta skill hace de portero.

El currículo son los 7 bloques de `cupo/README.md` § "Qué estudiar antes de
tirar código". El banco de preguntas vive en `preguntas/`, un archivo por
bloque. El historial vive en `.claude/estudio/progreso.md`.

## Cuándo se dispara

**Sí:**
- Antes de crear o modificar de forma sustancial cualquier `.dart` en `cupo/`.
- Antes de arrancar un spike o una iteración del `TODO.md`.
- Antes de integrar un paquete nuevo (`geolocator`, `flutter_map`, `provider`…).
- Cuando el usuario lo pide explícitamente.

**No:**
- Escritura de tesis, `docs/`, README, commits, git, despliegues.
- Correcciones de una línea, typos, formato, renombrar una variable.
- Si ya hubo quiz en esta misma sesión **y** el bloque relevante es el mismo.
  En ese caso dilo en una línea (`Quiz de Dart ya hecho hoy — sigo`) y continúa.
- Si el usuario dice explícitamente que se salte el quiz. Se respeta, pero lo
  anotas en el historial como `saltado`.

## Protocolo

### 1. Elegir el bloque

Mira qué va a tocar la tarea y elige **un** bloque:

| Si la tarea toca… | Bloque | Archivo |
|---|---|---|
| lógica pura, modelos, `fromJson`, async, streams | 1 · Dart | `preguntas/01-dart.md` |
| pantallas, widgets, layout, navegación, formularios | 2 · Flutter | `preguntas/02-flutter.md` |
| compartir datos entre pantallas, provider/riverpod | 3 · Estado | `preguntas/03-estado.md` |
| Firestore, Auth, RTDB, FCM, reglas | 4 · Firebase | `preguntas/04-firebase.md` |
| permisos, ubicación en segundo plano, manifest | 5 · Android | `preguntas/05-android.md` |
| geohash, punto en polígono, distancias, mapas | 6 · Geo | `preguntas/06-geo.md` |
| escribir o arreglar tests | 7 · Pruebas | `preguntas/07-pruebas.md` |

Si la tarea toca dos bloques, elige el que sea **más nuevo** para el usuario
según el marcador de `.claude/estudio/progreso.md`.

### 2. Preparar el quiz

1. Lee `.claude/estudio/progreso.md` para ver el marcador y la lista de
   refuerzo.
2. Lee **solo** el archivo del bloque elegido.
3. Escoge **3 preguntas**:
   - Si hay IDs de ese bloque en "Para reforzar", la primera sale de ahí.
   - Las demás, sin usar en los últimos 3 quizzes de ese bloque (mira el
     historial).
   - Nivel según el acierto acumulado del bloque: <60 % → nivel 1;
     60–85 % → niveles 1 y 2; >85 % → niveles 2 y 3.

### 3. Preguntar

Una sola llamada a `AskUserQuestion` con las 3 preguntas juntas.

Por cada pregunta:
- `header`: el bloque, corto (`Dart`, `Widgets`, `Firestore`, `Geo`…).
- `question`: el enunciado tal cual del banco.
- `options`: las 4 del banco, **en orden aleatorio** — la correcta no siempre
  primero. `label` = resumen de 2–5 palabras; `description` = el texto completo
  de la opción.
- `multiSelect: false`.

**Prohibido filtrar la respuesta.** Nada de "(Recomendado)", ni descripciones
que suenen más seguras o más completas en la opción correcta, ni distractores
absurdos. Las cuatro opciones deben leerse como plausibles.

### 4. Calificar

Responde con un bloque corto, una línea por pregunta:

```
Quiz · Bloque 4 · Firebase — 2/3

✅ FIRE-01 — correcto.
❌ FIRE-05 — respondiste «…». La correcta era «…».
   Por qué: <la explicación del banco, en tus palabras si aclara más>
   Recurso: <enlace del banco>
✅ FIRE-11 — correcto.
```

Reglas del portero:

- **3/3 o 2/3** → aprobado. Explicas el fallo si lo hubo y sigues con la tarea
  de inmediato.
- **1/3 o 0/3** → no aprobado. Das una mini-lección de 5–10 líneas sobre el
  concepto que falló, con un ejemplo en código de Cupo, y **una segunda ronda
  de 2 preguntas** del mismo bloque. Después de esa segunda ronda continúas con
  la tarea pase lo que pase: el requisito es responder, no acertar.
- Nunca bloquees el trabajo más de una ronda de refuerzo. El quiz es un peaje,
  no un muro.

### 5. Registrar

Actualiza `.claude/estudio/progreso.md`:
- Suma preguntas y aciertos en la fila del bloque, recalcula el %.
- Añade los IDs fallados a "Para reforzar"; quita los que ya se acertaron dos
  veces seguidas.
- Añade una entrada al historial con la fecha de hoy, la tarea que venía
  después, el bloque, el resultado y los IDs usados.

Escribe el archivo **antes** de ponerte con la tarea, no al final.

### 6. Seguir

Retomas la tarea original sin ceremonia. Una línea del tipo
`Sigo con el modelo de Turno` basta.

## Modo repaso

Si el usuario invoca `/estudiar` sin tarea pendiente detrás, no hay portero:
pregunta qué bloque quiere (o propón el de peor marcador), tira 5 preguntas en
vez de 3 y al final resume el marcador actualizado y qué conviene repasar.

Con `/estudiar <bloque>` (`/estudiar geo`, `/estudiar firebase`) vas directo a
ese bloque.

## Ampliar el banco

Si una pregunta se repite demasiado o el usuario pide más, agrega preguntas al
archivo del bloque siguiendo el mismo formato y numeración correlativa. Cada
pregunta nueva necesita: ID, nivel, enunciado, 4 opciones plausibles, la
correcta, el porqué y un enlace de `cupo/README.md` § Recursos.
