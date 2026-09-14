# Bloque 1 · Dart

Prefijo de ID: `DART`. Niveles: 1 básico · 2 intermedio · 3 avanzado.

---

### DART-01 · nivel 1 · `final` vs `const`
¿Qué distingue a `const` de `final` en Dart?
- A) `const` se resuelve en tiempo de compilación; `final` se asigna una sola vez, pero su valor puede calcularse en tiempo de ejecución.
- B) `const` solo sirve para números y cadenas; `final` sirve para cualquier tipo.
- C) Son sinónimos: `const` es la forma antigua y `final` la moderna.
- D) `final` impide modificar el objeto por dentro; `const` solo impide reasignar la variable.

**Correcta:** A · **Por qué:** `const` exige que el valor se conozca al compilar y congela el objeto entero; `final` solo prohíbe reasignar la referencia. La D describe lo contrario. · **Recurso:** https://dart.dev/language/variables

### DART-02 · nivel 1 · `late`
En `late final Database db;`, ¿qué aporta `late`?
- A) Promete que la variable se inicializará antes del primer uso; si se lee antes, salta un error en tiempo de ejecución.
- B) La vuelve nullable de forma implícita, equivalente a `Database?`.
- C) Retrasa la lectura hasta que termine el `Future` que la produce.
- D) La marca como perezosa y la recalcula cada vez que se lee.

**Correcta:** A · **Por qué:** `late` mueve la comprobación de inicialización del compilador al tiempo de ejecución. Si lleva inicializador, este se ejecuta una sola vez, en la primera lectura. · **Recurso:** https://dart.dev/null-safety/understanding-null-safety

### DART-03 · nivel 1 · `?.` y `??`
En `final nombre = usuario?.nombre ?? 'Invitado';`, ¿qué hace cada operador?
- A) `?.` evita llamar a `.nombre` si `usuario` es null y devuelve null; `??` sustituye ese null por `'Invitado'`.
- B) `?.` convierte `usuario` en no-nulo y `??` comprueba que `nombre` no esté vacío.
- C) `?.` lanza una excepción si `usuario` es null y `??` la captura.
- D) Hacen lo mismo: `??` es la forma corta de `?.`.

**Correcta:** A · **Por qué:** `?.` es acceso seguro (corta y devuelve null); `??` es valor por defecto ante null. Ojo: `??` no se dispara con cadena vacía ni con `0`, solo con null. · **Recurso:** https://dart.dev/language/operators

### DART-04 · nivel 2 · el operador `!`
¿Qué implica escribir `posicion!.latitude` sobre una variable de tipo `Position?`?
- A) Le afirmas al compilador que no es null; si en ejecución lo es, la app lanza un error.
- B) Convierte el valor a no-nulo asignándole un valor por defecto cuando es null.
- C) Es una negación lógica aplicada al objeto.
- D) Le indica al analizador que ignore el tipo y lo trate como `dynamic`.

**Correcta:** A · **Por qué:** `!` no comprueba nada: apaga el análisis y traslada el fallo a tiempo de ejecución. Cada `!` es una promesa que tú respaldas. · **Recurso:** https://dart.dev/null-safety/understanding-null-safety

### DART-05 · nivel 1 · `Future` vs `Stream`
La posición del chofer llega continuamente; el perfil del usuario se lee una vez. ¿Qué tipo corresponde a cada uno?
- A) La posición es un `Stream` (muchos valores en el tiempo) y el perfil un `Future` (un único valor futuro).
- B) Al revés: el perfil es un `Stream` porque puede cambiar, y la posición un `Future`.
- C) Ambos son `Future`; `Stream` solo se usa para archivos y sockets.
- D) Ambos son `Stream`; un `Future` es un `Stream` de un elemento y por eso no se usa.

**Correcta:** A · **Por qué:** un `Future` se completa una vez; un `Stream` emite cero, uno o muchos eventos. En Cupo casi todo lo de Firebase en vivo es `Stream`. · **Recurso:** https://dart.dev/codelabs/async-await

### DART-06 · nivel 2 · `async`
¿Qué devuelve una función marcada `async` cuyo cuerpo hace `return 5;`?
- A) Un `Future<int>` que se completa con 5.
- B) Un `int` con valor 5, porque `async` solo afecta al interior de la función.
- C) Un `Stream<int>` con un único evento.
- D) Un `FutureOr<int>` que se resuelve solo si alguien hace `await`.

**Correcta:** A · **Por qué:** marcar `async` envuelve siempre el retorno en un `Future`. Por eso el tipo declarado tiene que ser `Future<int>`. · **Recurso:** https://dart.dev/codelabs/async-await

### DART-07 · nivel 2 · constructor `factory`
¿Qué permite un constructor `factory` que uno normal no?
- A) Decidir qué instancia devolver: una cacheada, una de una subclase o una construida a partir de un `Map`.
- B) Crear objetos sin declarar los campos de la clase.
- C) Ejecutarse de forma asíncrona y devolver un `Future` de la instancia.
- D) Saltarse la llamada al constructor de la superclase.

**Correcta:** A · **Por qué:** un `factory` tiene cuerpo y devuelve una instancia con `return`, no necesariamente nueva. Es lo que hace idiomático `factory Turno.fromMap(...)`. No puede ser `async`. · **Recurso:** https://dart.dev/language/constructors

### DART-08 · nivel 2 · `copyWith`
¿Por qué los modelos inmutables llevan `copyWith`?
- A) Porque con campos `final` no se puede mutar el objeto: se crea uno nuevo cambiando solo lo que hace falta.
- B) Porque Dart lo exige en toda clase con constructor `const`.
- C) Porque es la única forma de hacer una copia profunda de las listas internas.
- D) Porque Firestore lo necesita para serializar el objeto.

**Correcta:** A · **Por qué:** `copyWith` es el sustituto del setter en un modelo inmutable. Ojo: copia superficial — las listas internas se comparten salvo que las clones a mano. · **Recurso:** https://dart.dev/language/classes

### DART-09 · nivel 2 · deserializar
`doc.data()` de Firestore devuelve `Map<String, dynamic>`. ¿Cuál es la forma idiomática de convertirlo en un `Turno`?
- A) Un `factory Turno.fromMap(Map<String, dynamic> map)` que lee cada clave y valida los tipos.
- B) Un cast directo `doc.data() as Turno`, porque Dart infiere la forma del objeto.
- C) `jsonDecode(doc.data())`, que convierte el mapa en la clase destino.
- D) Anotar la clase con `@firestore` para que el SDK la construya sola.

**Correcta:** A · **Por qué:** Dart no tiene reflexión en producción: la conversión se escribe a mano (o la genera un paquete). El cast de B falla en ejecución y `jsonDecode` recibe cadenas, no mapas. · **Recurso:** https://dart.dev/language/constructors

### DART-10 · nivel 3 · streams de suscripción única
¿Qué ocurre si dos widgets llaman a `listen` sobre el mismo `Stream` de suscripción única?
- A) El segundo lanza una excepción: hace falta un stream de difusión (`asBroadcastStream()` o un `StreamController.broadcast`).
- B) Ambos reciben todos los eventos; Dart duplica el stream automáticamente.
- C) El segundo recibe solo los eventos posteriores a su suscripción y el primero deja de recibir.
- D) Los eventos se reparten alternados entre los dos oyentes.

**Correcta:** A · **Por qué:** un stream normal admite un solo oyente. Es un error típico al compartir un stream de Firestore entre pantallas en vez de exponerlo desde un único sitio. · **Recurso:** https://dart.dev/libraries/async/using-streams

### DART-11 · nivel 3 · cascada `..`
¿Qué hace el operador `..`?
- A) Encadena operaciones sobre el mismo objeto y devuelve el objeto, no el resultado de la última operación.
- B) Concatena dos listas conservando el orden.
- C) Define un rango de valores, como `1..10`.
- D) Accede a un miembro solo si el objeto no es null, igual que `?.` en cadena.

**Correcta:** A · **Por qué:** la cascada evita la variable temporal: `Paint()..color = x..strokeWidth = 2` sigue devolviendo el `Paint`. La versión que tolera null es `?..`. · **Recurso:** https://dart.dev/language/operators

### DART-12 · nivel 3 · promoción de tipo
¿Por qué este código no compila?

```dart
class Sesion {
  String? token;
  void usar() { if (token != null) print(token.length); }
}
```

- A) Porque `token` es un campo mutable: Dart no promueve a no-nulo algo que podría cambiar entre la comprobación y el uso; hay que copiarlo a una variable local.
- B) Porque `String?` no tiene la propiedad `length` bajo ninguna circunstancia.
- C) Porque falta marcar el método como `async`.
- D) Porque la comparación correcta es `if (token is String)`: `!= null` no promueve nunca.

**Correcta:** A · **Por qué:** la promoción funciona con variables locales y con campos privados `final`, no con un campo público mutable. La solución: `final t = token; if (t != null) print(t.length);` · **Recurso:** https://dart.dev/null-safety/understanding-null-safety
