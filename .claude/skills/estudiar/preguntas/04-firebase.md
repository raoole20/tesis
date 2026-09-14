# Bloque 4 · Firebase

Prefijo de ID: `FIRE`. Niveles: 1 básico · 2 intermedio · 3 avanzado.

---

### FIRE-01 · nivel 1 · el modelo de datos
¿Cómo se organiza Firestore?
- A) Colecciones que contienen documentos, y cada documento puede tener subcolecciones; los datos siempre viven dentro de documentos.
- B) Tablas con filas y columnas de esquema fijo, como en SQL.
- C) Un único árbol JSON gigante donde cualquier nodo puede ser un valor.
- D) Documentos que contienen otros documentos anidados, sin límite de profundidad.

**Correcta:** A · **Por qué:** colección → documento → subcolección, alternando siempre. La C describe Realtime Database, que sí es un árbol JSON único. · **Recurso:** https://firebase.google.com/docs/firestore/data-model

### FIRE-02 · nivel 1 · sin `JOIN`
La tarjeta de resultados muestra el nombre del transportista junto al turno, y en Firestore no hay `JOIN`. ¿Qué se hace?
- A) Desnormalizar: guardar una copia del nombre dentro del documento del turno, asumiendo el coste de actualizarla si cambia.
- B) Hacer una lectura extra por cada turno de la lista para traer al transportista.
- C) Crear una vista materializada con `collectionGroup`.
- D) Normalizar más, separando el nombre en su propia colección para no duplicarlo.

**Correcta:** A · **Por qué:** en NoSQL se modela según cómo se lee, no según la forma canónica del dato. La B es el problema N+1: 20 turnos son 21 lecturas facturadas. · **Recurso:** https://firebase.google.com/docs/firestore/data-model

### FIRE-03 · nivel 2 · índices compuestos
Una consulta con `where('turnoId', ...)` más `orderBy('hora')` falla con un error que trae un enlace. ¿Qué pasa?
- A) Falta un índice compuesto: Firestore no ejecuta consultas que combinan filtro y orden sobre campos distintos sin él, y ese enlace lo crea.
- B) Los campos no existen en todos los documentos y hay que rellenarlos.
- C) Se superó la cuota de lecturas del día.
- D) `orderBy` no se puede combinar con `where` bajo ninguna circunstancia.

**Correcta:** A · **Por qué:** Firestore indexa cada campo por separado de forma automática; las combinaciones hay que declararlas. El error trae la URL que lo crea con un clic. · **Recurso:** https://firebase.google.com/docs/firestore/query-data/indexing

### FIRE-04 · nivel 2 · dónde corren las reglas
¿Dónde se evalúan las reglas de seguridad de Firestore?
- A) En el servidor, en cada petición: aunque alguien modifique la app, no puede saltárselas.
- B) En el cliente, dentro del SDK, antes de enviar la petición.
- C) Solo en el emulador local; en producción se usan los roles de IAM.
- D) En Cloud Functions, que hacen de intermediarias obligatorias.

**Correcta:** A · **Por qué:** el cliente de Firebase habla directo con la base de datos, así que las reglas *son* el backend de seguridad. No hay otra capa donde validar. · **Recurso:** https://firebase.google.com/docs/firestore/security/get-started

### FIRE-05 · nivel 3 · reglas y consultas
Una regla permite leer solo los documentos donde `uid == request.auth.uid`. El cliente hace `collection('inscripciones').get()` sin filtro. ¿Qué ocurre?
- A) La consulta entera falla: las reglas no filtran resultados, solo aprueban o rechazan la consulta completa.
- B) Devuelve solo los documentos del usuario: las reglas actúan como filtro automático.
- C) Devuelve todos los documentos y el SDK descarta los no permitidos al leerlos.
- D) Devuelve una lista vacía, sin error.

**Correcta:** A · **Por qué:** es el malentendido más común de Firestore. La regla evalúa si la *consulta* puede garantizar que solo pedirá lo permitido; el cliente debe incluir el `where('uid', isEqualTo: ...)` explícito. · **Recurso:** https://firebase.google.com/docs/firestore/security/rules-query

### FIRE-06 · nivel 1 · `get()` vs `snapshots()`
¿Cuándo se usa cada uno?
- A) `.snapshots()` cuando la interfaz debe reaccionar a cambios en vivo; `.get()` para una lectura puntual.
- B) `.snapshots()` para un documento y `.get()` para una colección.
- C) `.get()` lee de la caché local y `.snapshots()` siempre del servidor.
- D) Son equivalentes; `.snapshots()` es la versión con `async/await`.

**Correcta:** A · **Por qué:** `.get()` devuelve un `Future` y `.snapshots()` un `Stream` que emite en cada cambio. Elegir mal es pagar lecturas de más o mostrar datos rancios. · **Recurso:** https://firebase.google.com/docs/firestore/query-data/listen

### FIRE-07 · nivel 2 · Firestore vs Realtime Database
En Cupo, ¿por qué la posición en vivo del vehículo va en Realtime Database y no en Firestore?
- A) Porque son escrituras muy frecuentes de un dato efímero: RTDB está pensada para eso y sale más barata; Firestore cobra por operación y tiene un límite de escritura sostenida por documento.
- B) Porque Firestore no admite números decimales como la latitud.
- C) Porque RTDB es la única que funciona sin conexión.
- D) Porque Firestore no tiene listeners en tiempo real.

**Correcta:** A · **Por qué:** las dos son en tiempo real; lo que cambia es el perfil de coste y de escritura. Posición del viaje → RTDB; datos que persisten y se consultan → Firestore. · **Recurso:** https://firebase.google.com/docs/database/rtdb-vs-firestore

### FIRE-08 · nivel 3 · el coste
¿Cómo se factura una consulta que devuelve 50 turnos en Firestore?
- A) Como 50 lecturas de documento: el coste crece con los documentos devueltos, no con el número de consultas.
- B) Como una lectura, porque es una sola consulta.
- C) Por bytes transferidos, sin contar documentos.
- D) No se factura si la consulta usa un índice.

**Correcta:** A · **Por qué:** es la razón económica de la desnormalización y de paginar los resultados. Una pantalla que reconstruye su consulta en cada `build` puede costar dinero de verdad. · **Recurso:** https://firebase.google.com/docs/firestore/pricing

### FIRE-09 · nivel 2 · `authStateChanges()`
`FirebaseAuth.instance.authStateChanges()` devuelve un `Stream<User?>`. ¿Qué implica para el arranque de la app?
- A) Que la pantalla inicial se decide observando ese stream, y que el primer valor puede tardar un instante mientras se restaura la sesión guardada.
- B) Que hay que llamarlo dentro de cada `build` para saber si hay sesión.
- C) Que la sesión se pierde al cerrar la app y siempre se arranca en null.
- D) Que emite un valor solo cuando el usuario pulsa iniciar o cerrar sesión.

**Correcta:** A · **Por qué:** si decides la pantalla antes del primer evento, mandas a login a un usuario que sí tenía sesión. Por eso el arranque muestra un splash mientras llega el primer valor. · **Recurso:** https://firebase.flutter.dev/docs/auth/usage

### FIRE-10 · nivel 3 · FCM en segundo plano
Para manejar una notificación con la app cerrada en Android, el handler de Firebase Messaging debe…
- A) …ser una función de nivel superior (o `static`), anotada con `@pragma('vm:entry-point')` y registrada con `onBackgroundMessage`: corre en un isolate aparte, sin acceso al estado de la interfaz.
- B) …estar dentro del `State` de la pantalla principal, que Flutter mantiene viva.
- C) …ser un método de instancia registrado en `initState`.
- D) …no existir: con la app cerrada la notificación la muestra Android y no se puede ejecutar código.

**Correcta:** A · **Por qué:** el isolate de segundo plano arranca desde cero, sin el árbol de widgets ni los providers. Todo lo que necesite hay que inicializarlo dentro del propio handler. · **Recurso:** https://firebase.flutter.dev/docs/messaging/usage

### FIRE-11 · nivel 2 · el emulador
¿Para qué sirve el Local Emulator Suite en este proyecto?
- A) Para probar reglas de seguridad y consultas contra una instancia local, sin gastar cuota ni ensuciar los datos reales.
- B) Para emular un teléfono Android sin instalar Android Studio.
- C) Para generar datos de prueba a partir del esquema, automáticamente.
- D) Para desplegar la app en un servidor de pruebas accesible desde internet.

**Correcta:** A · **Por qué:** las reglas se prueban escribiendo casos que *deben* fallar. Hacerlo contra producción es lento, caro y deja basura. · **Recurso:** https://firebase.google.com/docs/emulator-suite

### FIRE-12 · nivel 3 · consultas por radio
Firestore no soporta consultas por radio de forma nativa. ¿Cómo se resuelve?
- A) Guardando un geohash en cada documento y consultando rangos de prefijos ordenados, con un filtro exacto de distancia después, en el cliente.
- B) Con `where('distancia', isLessThan: 2000)`, calculando la distancia dentro de la propia consulta.
- C) Usando el tipo `GeoPoint`, que Firestore indexa por proximidad.
- D) Descargando la colección entera y filtrando en el cliente, que es la práctica recomendada.

**Correcta:** A · **Por qué:** es exactamente el Spike 2. `GeoPoint` se guarda pero no se indexa espacialmente, y la distancia no es un campo almacenado: depende de dónde esté el usuario. · **Recurso:** https://firebase.google.com/docs/firestore/solutions/geoqueries

### FIRE-13 · nivel 3 · transacciones
Dos estudiantes pulsan "inscribirme" en el último cupo a la vez. ¿Cómo se evita que entren los dos?
- A) Con una transacción o una escritura por lotes: leer el contador de cupos y escribir la inscripción de forma atómica, reintentando si el documento cambió mientras tanto.
- B) Leyendo el cupo antes y comprobando en el cliente que sea mayor que cero.
- C) Con una regla de seguridad que compare la hora de las dos peticiones.
- D) No hace falta: Firestore serializa las escrituras y la segunda falla sola.

**Correcta:** A · **Por qué:** una comprobación en el cliente tiene una ventana entre la lectura y la escritura. `runTransaction` cierra esa ventana. · **Recurso:** https://firebase.google.com/docs/firestore/manage-data/transactions
