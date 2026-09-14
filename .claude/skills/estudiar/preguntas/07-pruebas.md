# Bloque 7 · Pruebas

Prefijo de ID: `TEST`. Niveles: 1 básico · 2 intermedio · 3 avanzado.

---

### TEST-01 · nivel 1 · `test` vs `flutter_test`
¿Qué diferencia hay entre los dos paquetes?
- A) `test` sirve para lógica pura de Dart y corre sin el motor de Flutter; `flutter_test` añade `testWidgets` y las utilidades para probar la interfaz.
- B) `test` es para pruebas unitarias y `flutter_test` para pruebas de integración en un dispositivo real.
- C) `flutter_test` sustituye a `test`; tenerlo también en `dev_dependencies` es redundante.
- D) `test` es la versión antigua, obsoleta desde Dart 3.

**Correcta:** A · **Por qué:** las pruebas de `core/geo/` no necesitan Flutter para nada: son funciones puras y corren más rápido con `test` a secas. (Las de integración en dispositivo son `integration_test`.) · **Recurso:** https://docs.flutter.dev/testing/overview

### TEST-02 · nivel 2 · `pumpWidget`
En un `testWidgets`, ¿qué hace `await tester.pumpWidget(const MainApp());`?
- A) Construye el árbol de widgets y dibuja el primer frame dentro del entorno de prueba.
- B) Lanza la app en el emulador que esté conectado.
- C) Espera a que terminen todas las animaciones y peticiones pendientes.
- D) Crea un widget vacío sobre el que se montarán los siguientes.

**Correcta:** A · **Por qué:** todo ocurre en memoria, sin dispositivo. Por eso las pruebas de widget tardan milisegundos y se pueden correr en cada guardado. · **Recurso:** https://docs.flutter.dev/cookbook/testing/widget/introduction

### TEST-03 · nivel 3 · `pump` vs `pumpAndSettle`
¿Cuándo se usa `pumpAndSettle` en vez de `pump`?
- A) Cuando hay animaciones o transiciones pendientes y hay que esperar a que el árbol se estabilice; `pump` avanza un solo frame.
- B) Siempre: `pump` está pensado solo para pruebas de rendimiento.
- C) Cuando la prueba usa datos de red, que `pump` no espera.
- D) Cuando el widget es `StatelessWidget` y no se reconstruye solo.

**Correcta:** A · **Por qué:** `pumpAndSettle` repite frames hasta que no queda ninguno programado. No espera a la red: con una animación infinita —un spinner— se queda colgado hasta agotar el tiempo. · **Recurso:** https://docs.flutter.dev/cookbook/testing/widget/introduction

### TEST-04 · nivel 2 · aserciones
¿Cómo se comprueba que la pantalla muestra el texto "Cupo"?
- A) `expect(find.text('Cupo'), findsOneWidget);`
- B) `expect(tester.widget<Text>('Cupo'), isNotNull);`
- C) `assert(screen.contains('Cupo'));`
- D) `expect(find.byType(Text), equals('Cupo'));`

**Correcta:** A · **Por qué:** el patrón es siempre finder + matcher: `find.text`, `find.byType`, `find.byKey` contra `findsOneWidget`, `findsNothing`, `findsNWidgets(n)`. · **Recurso:** https://docs.flutter.dev/cookbook/testing/widget/finders

### TEST-05 · nivel 1 · por qué empezar por la geometría
El README dice escribir primero las pruebas de geometría. ¿Por qué son el mejor candidato a TDD?
- A) Porque son funciones puras, sin interfaz ni red: entrada conocida, salida verificable, y sirven además de evidencia para el Objetivo 4.
- B) Porque son el código más simple del proyecto.
- C) Porque Flutter obliga a tener cobertura en `core/`.
- D) Porque no hay forma de probarlas a mano dentro de la app.

**Correcta:** A · **Por qué:** un punto dentro y otro fuera de un polígono conocido son un caso de prueba que se escribe antes que el algoritmo. Y es material citable en el capítulo de verificación. · **Recurso:** https://docs.flutter.dev/cookbook/testing/unit/introduction

### TEST-06 · nivel 3 · probar lo que toca Firestore
¿Cómo se prueba un repositorio que habla con Firestore, sin depender de la red?
- A) Dependiendo de una abstracción propia e inyectando un doble —fake o mock— en la prueba; o corriendo contra el emulador cuando lo que se quiere probar es la integración.
- B) Llamando a Firestore en producción contra una colección `test_` aparte.
- C) Con `pumpAndSettle`, que intercepta las llamadas de red automáticamente.
- D) No se prueba: el código que toca Firestore queda fuera del alcance de las pruebas.

**Correcta:** A · **Por qué:** la testabilidad es la razón práctica de separar `core/services/` de las pantallas. Si el widget llama a `FirebaseFirestore.instance` directamente, no hay dónde meter el doble. · **Recurso:** https://docs.flutter.dev/cookbook/testing/unit/mocking

### TEST-07 · nivel 2 · estructura del archivo
¿Para qué sirven `group`, `setUp` y `tearDown`?
- A) `group` agrupa pruebas relacionadas; `setUp` prepara el estado antes de **cada** prueba del grupo y `tearDown` lo limpia después de cada una.
- B) `setUp` corre una sola vez antes de todo el archivo y `tearDown` una vez al final.
- C) `group` hace que las pruebas del grupo se ejecuten en paralelo.
- D) Son de `flutter_test` y no existen en pruebas de Dart puro.

**Correcta:** A · **Por qué:** lo que corre una sola vez por archivo es `setUpAll`/`tearDownAll`. Confundirlos produce pruebas que pasan sueltas y fallan en conjunto, por estado compartido. · **Recurso:** https://docs.flutter.dev/cookbook/testing/unit/introduction

### TEST-08 · nivel 3 · qué se prueba
De estas cuatro, ¿cuál es la prueba que más aporta en Cupo?
- A) Que `distanciaAPolilinea` devuelva el valor esperado para un punto perpendicular a la mitad de un segmento, y para otro más allá de su extremo.
- B) Que `AppColors.primary` sea igual a `Color(0xFF007C8A)`.
- C) Que el constructor de `Turno` asigne cada parámetro a su campo.
- D) Que `MaterialApp` se construya sin lanzar excepciones.

**Correcta:** A · **Por qué:** prueba una regla de negocio que puede estar mal —el caso del extremo es justo donde falla la implementación ingenua—. Las otras tres verifican que Dart hace lo que Dart hace. · **Recurso:** https://docs.flutter.dev/testing/overview
