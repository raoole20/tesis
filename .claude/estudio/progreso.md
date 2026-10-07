# Progreso de estudio — Cupo

Lo mantiene la skill `estudiar`. No hace falta editarlo a mano, pero se puede.

## Marcador por bloque

| # | Bloque | Preguntas | Aciertos | % | Nivel actual |
|---|---|---:|---:|---:|---|
| 1 | Dart | 5 | 0 | 0 % | 1 |
| 2 | Flutter — fundamentos | 0 | 0 | — | 1 |
| 3 | Manejo de estado | 0 | 0 | — | 1 |
| 4 | Firebase | 0 | 0 | — | 1 |
| 5 | Android — permisos y ciclo de vida | 0 | 0 | — | 1 |
| 6 | Geo | 0 | 0 | — | 1 |
| 7 | Pruebas | 0 | 0 | — | 1 |

Nivel: <60 % → 1 · 60–85 % → 1 y 2 · >85 % → 2 y 3.

## Para reforzar

IDs fallados que deben volver a salir. Se quitan tras dos aciertos seguidos.

- `DART-01` — `final` vs `const`
- `DART-02` — `late`
- `DART-03` — `?.` y `??`
- `DART-05` — `Future` vs `Stream`
- `DART-06` — `async` envuelve el retorno en `Future`

## Historial

Entrada por quiz, la más reciente arriba.

### 2026-09-24 · Bloque 1 · Dart · 0/3 → refuerzo 0/2

Tarea siguiente: Fase 0 + Fase 1 del login (cliente Supabase, modelos con
enums, repositorio de auth, resolver de rutas puro, `AuthGate` con streams).

- Ronda 1: `DART-01` ❌ · `DART-03` ❌ · `DART-05` ❌
- Ronda 2: `DART-02` ❌ · `DART-06` ❌

Los cinco fallos son del mismo grupo: **null-safety y asincronía**. Es
exactamente lo que usa el código que viene después, así que el código de esta
tanda se escribió con comentarios explicativos en esos puntos.
