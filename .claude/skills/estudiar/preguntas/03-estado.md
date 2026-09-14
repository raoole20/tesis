# Bloque 3 · Manejo de estado

Prefijo de ID: `EST`. Niveles: 1 básico · 2 intermedio · 3 avanzado.

---

### EST-01 · nivel 1 · el límite de `setState`
"Buscar" y "Mi semana" necesitan saber si el estudiante ya se inscribió. ¿Por qué `setState` no basta?
- A) Porque `setState` solo reconstruye el widget que lo llama y su subárbol: no comunica nada a otra rama del árbol.
- B) Porque `setState` no funciona con datos que vienen de Firestore.
- C) Porque solo se puede llamar a `setState` una vez por pantalla.
- D) Porque `setState` es asíncrono y las dos pantallas se desincronizan.

**Correcta:** A · **Por qué:** `setState` es local por diseño. En cuanto dos ramas distintas del árbol necesitan el mismo dato, hace falta algo por encima de ambas. · **Recurso:** https://docs.flutter.dev/data-and-backend/state-mgmt/intro

### EST-02 · nivel 1 · elevar el estado
¿En qué consiste "elevar el estado" (lifting state up)?
- A) Mover el dato al ancestro común más cercano de los widgets que lo necesitan y pasarlo hacia abajo.
- B) Guardar el dato en el nivel más alto posible, siempre en `main.dart`.
- C) Convertir el `StatelessWidget` en `StatefulWidget`.
- D) Subirlo a Firestore para que ambas pantallas lo lean de ahí.

**Correcta:** A · **Por qué:** el ancestro *más cercano*, no la raíz: subirlo más de lo necesario reconstruye media app en cada cambio. · **Recurso:** https://docs.flutter.dev/data-and-backend/state-mgmt/intro

### EST-03 · nivel 2 · `InheritedWidget`
¿Qué problema resuelve un `InheritedWidget`?
- A) Deja un dato disponible para todo su subárbol sin pasarlo por el constructor de cada widget intermedio.
- B) Permite que un hijo modifique el estado del padre sin callbacks.
- C) Hace que el estado sobreviva al cierre de la aplicación.
- D) Comparte estado entre widgets de ramas distintas que no tienen ancestro común.

**Correcta:** A · **Por qué:** evita el *prop drilling*. Solo llega a su subárbol, por eso los providers se montan arriba. Es el mecanismo detrás de `Theme.of`, `MediaQuery.of` y de `provider`. · **Recurso:** https://docs.flutter.dev/data-and-backend/state-mgmt/simple

### EST-04 · nivel 2 · `ChangeNotifier`
En `provider`, ¿qué hace `notifyListeners()`?
- A) Avisa a los widgets suscritos a ese `ChangeNotifier` para que se reconstruyan.
- B) Guarda los cambios en el almacenamiento local.
- C) Reconstruye toda la aplicación desde `MaterialApp`.
- D) Envía el cambio al servidor y espera confirmación.

**Correcta:** A · **Por qué:** el `ChangeNotifier` guarda el estado y `notifyListeners` es la señal. Si cambias un campo y no lo llamas, la interfaz se queda con el valor viejo. · **Recurso:** https://docs.flutter.dev/data-and-backend/state-mgmt/simple

### EST-05 · nivel 2 · `read` vs `watch`
¿Cuándo se usa `context.read<X>()` y cuándo `context.watch<X>()`?
- A) `watch` dentro de `build`, para reconstruir cuando el dato cambie; `read` en callbacks como `onPressed`, donde solo se invoca una acción.
- B) Al revés: `read` en `build` porque es más barato, y `watch` en los callbacks.
- C) `read` para datos locales y `watch` para datos remotos.
- D) Son equivalentes: `watch` es solo el nombre nuevo de `read`.

**Correcta:** A · **Por qué:** `watch` suscribe, `read` no. Usar `watch` en un callback lanza un error, y usar `read` en `build` deja la interfaz congelada. · **Recurso:** https://pub.dev/packages/provider

### EST-06 · nivel 3 · notificar en `build`
¿Por qué no se llama a `notifyListeners()` —ni se crea un provider— dentro de `build`?
- A) Porque provocaría una reconstrucción que dispararía otra notificación: un bucle infinito de frames.
- B) Porque `build` no tiene acceso al `BuildContext` necesario.
- C) Porque provider prohíbe más de una notificación por segundo.
- D) Porque el estado se perdería al rotar la pantalla.

**Correcta:** A · **Por qué:** `build` debe ser puro: sin efectos secundarios. Los cambios de estado van en callbacks, en `initState` o en respuesta a un evento, nunca durante la construcción. · **Recurso:** https://docs.flutter.dev/data-and-backend/state-mgmt/simple

### EST-07 · nivel 2 · elegir una y quedarse
El README pide elegir la solución de estado antes de la Iteración 1 y no cambiarla. ¿Cuál es la razón de fondo?
- A) Cambiar de solución a mitad implica reescribir cómo cada pantalla obtiene y observa sus datos, y eso atraviesa toda la app.
- B) Flutter no permite tener dos librerías de estado instaladas a la vez.
- C) Firebase solo es compatible con una de las dos.
- D) Porque el jurado exige justificar la librería en el capítulo de metodología.

**Correcta:** A · **Por qué:** el manejo de estado no es una capa aislada: define la forma de cada widget que consume datos. Migrarlo cuesta días que en esta tesis no sobran. · **Recurso:** https://docs.flutter.dev/data-and-backend/state-mgmt/options

### EST-08 · nivel 3 · el estado de sesión
El router, el perfil y cada pantalla que muestra el nombre necesitan el usuario autenticado. ¿Dónde vive ese estado?
- A) En un único proveedor cerca de la raíz que expone el stream de `authStateChanges()`, y cada pantalla lo observa desde ahí.
- B) En el `State` de cada pantalla, suscribiéndose por separado al mismo stream.
- C) En una variable global `static User? usuarioActual` que se actualiza al iniciar sesión.
- D) En `SharedPreferences`, leyéndolo en cada `build`.

**Correcta:** A · **Por qué:** una sola fuente de verdad y una sola suscripción. La B multiplica listeners sobre un stream de suscripción única y la C no notifica a nadie cuando cambia. · **Recurso:** https://firebase.flutter.dev/docs/auth/usage

### EST-09 · nivel 3 · granularidad
Una pantalla observa un provider con toda la búsqueda (filtros, resultados, estado de carga). Al escribir en el campo de texto se reconstruye la lista entera. ¿Qué falla?
- A) La pantalla observa demasiado: conviene partir el estado o usar `Selector`/`context.select` para escuchar solo el trozo que ese widget pinta.
- B) Falta llamar a `setState` además de `notifyListeners`.
- C) El provider debería estar en la raíz de la app en vez de en la pantalla.
- D) Es inevitable: cualquier cambio en un provider reconstruye a todos sus consumidores.

**Correcta:** A · **Por qué:** D es lo que ocurre *si no haces nada*, pero es evitable. La granularidad de la suscripción es lo que separa una app fluida de una que parpadea al teclear. · **Recurso:** https://pub.dev/packages/provider

### EST-10 · nivel 3 · Riverpod vs Provider
¿Cuál es la diferencia práctica más citada entre Riverpod y Provider?
- A) En Riverpod los providers se declaran fuera del árbol de widgets y no dependen del `BuildContext`, así que los errores de "provider no encontrado" se detectan al compilar y no en ejecución.
- B) Riverpod es la única de las dos que soporta estado asíncrono.
- C) Provider es de Google y Riverpod es de terceros sin mantenimiento.
- D) Riverpod sustituye a `setState` incluso para el estado local de un widget.

**Correcta:** A · **Por qué:** Riverpod nació precisamente para quitar la dependencia del `BuildContext`. Para Cupo cualquiera de las dos sirve: lo que importa es decidir una. · **Recurso:** https://riverpod.dev
