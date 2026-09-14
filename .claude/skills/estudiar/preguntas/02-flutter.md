# Bloque 2 · Flutter — fundamentos

Prefijo de ID: `FLU`. Niveles: 1 básico · 2 intermedio · 3 avanzado.

---

### FLU-01 · nivel 1 · Stateless vs Stateful
La tarjeta de resultado de búsqueda solo pinta los datos que recibe por constructor. ¿Qué widget corresponde?
- A) `StatelessWidget`: no guarda estado propio y se reconstruye cuando cambian sus datos de entrada.
- B) `StatefulWidget`, porque los datos vienen de Firestore y pueden cambiar.
- C) Da igual: `StatefulWidget` siempre es más seguro y no tiene coste.
- D) `InheritedWidget`, que es el punto intermedio entre los dos.

**Correcta:** A · **Por qué:** el criterio es si el widget guarda estado *propio* que cambia con el tiempo, no si los datos cambian. Si el dato llega de fuera, es stateless. · **Recurso:** https://docs.flutter.dev/ui/interactivity

### FLU-02 · nivel 1 · `setState`
¿Qué hace exactamente `setState(() { contador++; })`?
- A) Cambia el estado y marca ese elemento como sucio para que Flutter llame de nuevo a `build` en el próximo frame.
- B) Redibuja de inmediato toda la aplicación desde la raíz.
- C) Guarda el valor y notifica a los demás widgets que lo escuchan.
- D) Vuelve a crear el `State` desde cero, ejecutando `initState` otra vez.

**Correcta:** A · **Por qué:** `setState` no pinta nada: programa una reconstrucción de ese subárbol. El `State` sobrevive; `initState` corre una sola vez. · **Recurso:** https://api.flutter.dev/flutter/widgets/State/setState.html

### FLU-03 · nivel 2 · restricciones
"Constraints go down, sizes go up, parent sets position". ¿Qué significa?
- A) El padre pasa restricciones de tamaño al hijo, el hijo elige su tamaño dentro de ellas y el padre lo coloca.
- B) El hijo decide su tamaño libremente y el padre se adapta para no recortarlo.
- C) El tamaño se calcula de arriba abajo en una sola pasada, sin que el hijo opine.
- D) Las restricciones se propagan hacia arriba, desde las hojas hasta la raíz.

**Correcta:** A · **Por qué:** es el modelo de layout completo de Flutter, en una frase. Un widget nunca conoce ni decide su posición: eso lo hace el padre. · **Recurso:** https://docs.flutter.dev/ui/layout/constraints

### FLU-04 · nivel 2 · `Expanded` vs `Flexible`
Dentro de un `Row`, ¿en qué se diferencian?
- A) `Expanded` obliga al hijo a ocupar todo el espacio asignado; `Flexible` le permite ocupar menos si no lo necesita.
- B) `Expanded` funciona en `Row` y `Flexible` solo en `Column`.
- C) `Flexible` reparte a partes iguales y `Expanded` respeta el parámetro `flex`.
- D) `Expanded` recorta al hijo si se pasa, y `Flexible` provoca overflow.

**Correcta:** A · **Por qué:** `Expanded` es literalmente `Flexible` con `fit: FlexFit.tight`. Ambos aceptan `flex` y ambos funcionan en `Row` y `Column`. · **Recurso:** https://docs.flutter.dev/ui/layout

### FLU-05 · nivel 1 · `ListView.builder`
¿Por qué usar `ListView.builder` en vez de `ListView(children: [...])` para la nómina del día?
- A) Porque construye solo los elementos visibles y los recicla al hacer scroll, en vez de crear la lista entera de golpe.
- B) Porque `ListView` normal no admite más de 100 hijos.
- C) Porque `builder` hace la consulta a Firestore por cada fila.
- D) Porque solo `builder` permite separadores entre elementos.

**Correcta:** A · **Por qué:** con `children` construyes todos los widgets aunque no se vean. `builder` construye bajo demanda. (Los separadores los da `ListView.separated`.) · **Recurso:** https://docs.flutter.dev/cookbook/lists/long-lists

### FLU-06 · nivel 2 · `BuildContext`
¿Qué es un `BuildContext`?
- A) La referencia a la posición de ese widget en el árbol, que permite buscar hacia arriba cosas como `Theme` o `Navigator`.
- B) Un objeto con los datos de la pantalla: tamaño, orientación y tema.
- C) El estado mutable del widget, equivalente a `State`.
- D) El contexto de ejecución asíncrono en el que corre `build`.

**Correcta:** A · **Por qué:** de ahí que `Theme.of(context)` funcione: sube por el árbol desde ese punto. Y de ahí que usar un `context` desmontado tras un `await` sea un error. · **Recurso:** https://api.flutter.dev/flutter/widgets/BuildContext-class.html

### FLU-07 · nivel 2 · constructores `const`
¿Qué gana un widget al declararse `const`?
- A) Flutter reutiliza la misma instancia y puede saltarse su reconstrucción cuando el padre se reconstruye.
- B) Se dibuja antes que los widgets no `const`.
- C) Sus campos pasan a ser inmutables, cosa que de otro modo no ocurriría.
- D) Deja de necesitar `key`, porque `const` ya le da identidad única.

**Correcta:** A · **Por qué:** dos widgets `const` idénticos son el mismo objeto, así que la comparación del árbol los descarta sin trabajo. Es la optimización más barata que hay en Flutter. · **Recurso:** https://docs.flutter.dev/perf/best-practices

### FLU-08 · nivel 3 · `Key`
¿Para qué sirve pasar `key` a los elementos de una lista que se reordena o filtra?
- A) Para que Flutter reconozca qué elemento es cuál al comparar el árbol viejo con el nuevo y no mezcle el estado entre filas.
- B) Para identificar el widget en las pruebas, que es su único uso real.
- C) Para acelerar el renderizado saltándose la comparación del árbol.
- D) Para que el `ListView` sepa cuántos elementos hay antes de construirlos.

**Correcta:** A · **Por qué:** sin `key`, Flutter empareja por posición y tipo: al reordenar, el estado (scroll, checkbox, animación) se queda en la posición, no en el dato. · **Recurso:** https://docs.flutter.dev/development/ui/widgets-intro

### FLU-09 · nivel 2 · `StreamBuilder`
Al pintar los turnos con `StreamBuilder`, ¿qué hay que contemplar antes de usar `snapshot.data`?
- A) `connectionState` y `hasError`, y que `data` puede ser null en el primer frame, antes de que llegue el primer evento.
- B) Nada: `StreamBuilder` solo llama al `builder` cuando ya hay datos.
- C) Solo `hasData`; de los errores se encarga Flutter mostrando una pantalla roja.
- D) Que el stream esté cerrado, porque si no los datos son parciales.

**Correcta:** A · **Por qué:** el `builder` se llama de inmediato, antes del primer evento. Los tres estados —cargando, error, datos— hay que pintarlos siempre. · **Recurso:** https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html

### FLU-10 · nivel 2 · `dispose`
¿Qué va en `dispose()` de un `StatefulWidget`?
- A) Cancelar suscripciones a streams y liberar controladores (`TextEditingController`, `AnimationController`) para no filtrar memoria.
- B) Guardar el estado en disco antes de que el widget desaparezca.
- C) Llamar a `setState` una última vez para limpiar la interfaz.
- D) Nada: Flutter libera todo automáticamente al desmontar el widget.

**Correcta:** A · **Por qué:** Flutter desmonta el widget pero no cancela lo que tú suscribiste. Un listener de ubicación vivo tras salir de la pantalla es una fuga clásica. · **Recurso:** https://api.flutter.dev/flutter/widgets/State/dispose.html

### FLU-11 · nivel 2 · formularios
¿Cómo se dispara la validación de un `Form` con varios `TextFormField`?
- A) Con un `GlobalKey<FormState>` en el `Form` y llamando a `_formKey.currentState!.validate()`, que ejecuta el `validator` de cada campo.
- B) Llamando a `validate()` sobre cada `TextFormField`, uno por uno.
- C) Flutter valida solo al perder el foco; no hay que llamar a nada.
- D) Con `setState`, que reevalúa los `validator` al reconstruir.

**Correcta:** A · **Por qué:** el `FormState` coordina a todos sus campos: `validate()` los recorre y `save()` dispara los `onSaved`. · **Recurso:** https://docs.flutter.dev/cookbook/forms/validation

### FLU-12 · nivel 2 · `Theme`
¿Qué ventaja tiene definir la paleta en `ThemeData`/`ColorScheme` y leerla con `Theme.of(context)` en vez de escribir el color en cada widget?
- A) El color queda definido en un solo sitio: cambiarlo, o añadir modo oscuro, no obliga a tocar cada pantalla.
- B) Los colores del tema se dibujan con más precisión que los literales.
- C) Es la única forma de usar colores con opacidad.
- D) `Theme.of(context)` cachea el color y evita reconstruir el widget.

**Correcta:** A · **Por qué:** es la base de la Fase 4 y la razón por la que `lib/theme/app_colors.dart` centraliza los tokens en vez de repartir literales por el código. · **Recurso:** https://docs.flutter.dev/ui/design/material

### FLU-13 · nivel 2 · navegación
¿Cómo se le pasa el `Turno` seleccionado a la pantalla de detalle?
- A) Por el constructor del widget destino dentro del `MaterialPageRoute`, o como `arguments` si la ruta es nombrada.
- B) Con una variable global, porque `Navigator` no transporta objetos.
- C) Serializándolo a JSON dentro del nombre de la ruta.
- D) Guardándolo en `SharedPreferences` justo antes de navegar.

**Correcta:** A · **Por qué:** `Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleTurno(turno: t)))`. Con rutas nombradas, `arguments` y `ModalRoute.of(context)!.settings.arguments`. · **Recurso:** https://docs.flutter.dev/cookbook/navigation/navigate-with-arguments

### FLU-14 · nivel 3 · `build` barato
¿Por qué no se lanza una consulta a Firestore dentro de `build`?
- A) Porque `build` puede ejecutarse muchas veces por segundo y dispararía una consulta en cada reconstrucción.
- B) Porque `build` es síncrono y el código no compilaría.
- C) Porque Firestore bloquea las llamadas hechas desde el hilo de la interfaz.
- D) Porque el `BuildContext` todavía no existe cuando corre `build`.

**Correcta:** A · **Por qué:** `build` debe ser puro y barato: se llama en cada frame que lo necesite. La consulta va en `initState`, en un provider, o se expone como stream a un `StreamBuilder`. · **Recurso:** https://docs.flutter.dev/perf/best-practices

### FLU-15 · nivel 1 · `Stack`
Para poner un badge de "3 cupos" sobre la esquina de una tarjeta, ¿qué se usa?
- A) Un `Stack` con el badge dentro de un `Positioned`.
- B) Un `Column` con `crossAxisAlignment: end`.
- C) Un `Row` con `Spacer` y padding negativo.
- D) Un `Overlay` global, que es la única forma de superponer widgets.

**Correcta:** A · **Por qué:** `Stack` apila hijos en profundidad y `Positioned` los ancla a los bordes. Flutter no tiene padding negativo. · **Recurso:** https://docs.flutter.dev/ui/layout

### FLU-16 · nivel 3 · overflow
Aparece la franja amarilla y negra: "RenderFlex overflowed by 42 pixels". ¿Cuál es la causa típica?
- A) Un hijo pide más espacio del que el `Row`/`Column` tiene disponible y no está envuelto en `Expanded`, `Flexible` ni en un scroll.
- B) Que el widget no tiene `key` y Flutter no puede medirlo.
- C) Que falta llamar a `setState` después de cambiar el tamaño.
- D) Que la imagen supera la resolución de la pantalla.

**Correcta:** A · **Por qué:** un `Text` largo dentro de un `Row` es el caso número uno: se arregla envolviéndolo en `Expanded` (y, si toca, con `overflow: TextOverflow.ellipsis`). · **Recurso:** https://docs.flutter.dev/ui/layout/constraints
