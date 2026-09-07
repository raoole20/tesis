# Cupo — sistema de gestión de cupos de transporte estudiantil

Repositorio de la tesis y de la aplicación que la acompaña: una app móvil que
conecta a estudiantes con transportistas para la reserva y el seguimiento de
cupos en rutas y turnos de transporte universitario.

Aquí conviven dos cosas que se tocan pero no se mezclan: **el documento de
tesis** (y su documentación derivada) y **el software** que constituye su
artefacto. La regla de convivencia es simple: la tesis define el alcance, el
software lo cumple, y cada pieza construida debe poder rastrearse hasta un
objetivo específico.

---

## Qué hace la aplicación

Tres actores, cada uno con su recorrido:

- **Estudiante** — marca dónde vive, busca turnos con cupo disponible según sus
  días y horario, se inscribe, confirma su semana y sigue el viaje en curso.
- **Transportista** — administra sus rutas, turnos y zonas de cobertura, ve la
  nómina del día, cobra y lleva la cuenta de cada pasajero.
- **Administrador** — aprueba registros y mantiene el catálogo del sistema.

La pieza técnicamente interesante — y la que sostiene la investigación — es el
**filtrado geográfico en cadena**: dado un domicilio, un turno y unos días,
determinar qué unidades pasan lo bastante cerca como para que caminar tenga
sentido. Eso implica punto en polígono para las zonas de cobertura, distancia
punto-polilínea para las rutas y consultas por radio con geohash en Firestore.

## Estructura del repositorio

```
.
├── cupo/          la aplicación Flutter (Android)
├── docs/
│   ├── tesis/     copias de lectura de los capítulos — NO se editan a mano
│   └── producto/  documentación viva del producto — aquí sí se escribe
├── originales/    los .docx/.pdf entregados a la universidad (fuente de verdad)
└── TODO.md        plan de trabajo por fases, de la 0 a la 6
```

La distinción entre `docs/tesis/` y `docs/producto/` es deliberada y está
explicada en el README de cada carpeta. En resumen: lo primero es material
derivado de `originales/` y se regenera; lo segundo se escribe a mano y se
versiona como cualquier fuente.

## Por dónde empezar

Depende de qué vengas a hacer.

**Si vienes a programar** → [`cupo/README.md`](cupo/README.md). Ahí está todo:
requisitos, creación del proyecto, configuración de Android y Firebase,
extensiones de VS Code, herramientas, qué estudiar antes de escribir código y
recursos para aprenderlo.

**Si vienes a escribir la tesis** → [`docs/tesis/PENDIENTES.md`](docs/tesis/PENDIENTES.md).
Hay 31 pendientes abiertos, 7 de ellos bloqueantes.

**Si no sabes qué sigue** → [`TODO.md`](TODO.md). Las fases están ordenadas por
dependencia, no por gusto.

## Estado actual

El proyecto está en la **Fase 0**: decisiones abiertas. Nada del software
existe todavía más allá de la documentación de arranque.

Tres cosas bloquean el avance ahora mismo:

1. **Faltan los originales de la tesis.** No hay carpeta `originales/`, y sin
   ella no se puede generar ninguna copia de lectura ni citar el Capítulo I,
   que es donde viven los objetivos específicos que definen el alcance.
2. **Hay decisiones de producto sin cerrar** que cambian el modelo de datos:
   Google Maps SDK contra OSM, si se admiten carros por puesto, cómo se comparte
   un puesto entre días alternos, y el plazo de vencimiento del estado
   "reservado". Están listadas en [`TODO.md`](TODO.md).
3. **El trabajo de campo no se ha aplicado.** Las entrevistas a transportistas y
   el cuestionario a estudiantes van **antes** del modelo de datos. Si la base de
   datos se diseña primero, los requerimientos quedan justificados al revés y
   eso se nota en la defensa.

## Lo esencial, en cuatro puntos

Si solo te llevas cuatro cosas de este README, que sean estas.

1. **El orden de las fases no es negociable.** Campo → requerimientos → diseño →
   construcción. Saltárselo produce un software que quizá funciona, pero cuya
   justificación metodológica no se sostiene.

2. **El Spike 1 va primero, y va esta semana.** Rastrear la ubicación con la app
   minimizada y la pantalla apagada es el riesgo que puede tumbar la
   arquitectura completa. Se prueba en un teléfono físico, no en el emulador.
   Si no funciona como se espera, es mejor saberlo ahora que en la Iteración 5.

3. **Lo que se puede probar sin interfaz, se prueba sin interfaz.** Los cálculos
   geométricos son Dart puro y viven en `cupo/lib/core/geo/`. Sus pruebas
   unitarias son evidencia directa para el Objetivo 4, y cuestan mucho menos que
   evaluar lo mismo a través de la app.

4. **Dos proyectos de Firebase, siempre: desarrollo y demostración.** Y ningún
   secreto en el repositorio: `google-services.json`, `firebase_options.dart`,
   los keystores y los `.env` ya están en el [`.gitignore`](.gitignore). Los
   entornos de Bruno todavía **no**; hay que agregarlos antes de crear la
   primera colección de API.

## Stack

| Capa | Elección |
|---|---|
| App | Flutter · Android · `minSdk 26` (RNF-01) · package `com.cupo.app` |
| Autenticación | Firebase Auth |
| Datos | Cloud Firestore |
| Posiciones en vivo | Firebase Realtime Database |
| Notificaciones | Firebase Cloud Messaging |
| Mapas | por decidir — Google Maps SDK u OSM con `flutter_map` (Fase 0) |
| Metodología | XP — iteraciones que cierran con algo funcionando y probado |

## Convenciones

- La documentación se escribe en español, en markdown, con líneas a 80
  columnas.
- Los documentos de `docs/producto/` citan los objetivos específicos por su
  numeración original del Capítulo I.
- Cada iteración de la Fase 5 cierra con algo que funciona y está probado. Una
  iteración que no corre en un teléfono no está cerrada.
