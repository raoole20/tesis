# Bloque 5 · Android — permisos y ciclo de vida

Prefijo de ID: `AND`. Niveles: 1 básico · 2 intermedio · 3 avanzado.

---

### AND-01 · nivel 1 · el permiso en dos pasos
¿Cómo se obtiene el permiso de ubicación en segundo plano en Android moderno?
- A) En dos pasos: primero se concede el permiso mientras se usa la app y, más tarde y con una justificación, se envía al usuario a los ajustes para elegir "Permitir siempre".
- B) En un solo diálogo que pide los dos permisos a la vez.
- C) Basta con declararlo en el manifest; no aparece ningún diálogo.
- D) Solo se puede conceder desde los ajustes del sistema, nunca a petición de la app.

**Correcta:** A · **Por qué:** desde Android 11 el sistema no ofrece "Permitir siempre" en el diálogo: hay que pedir el de primer plano y después abrir los ajustes. Es la parte del Spike 1 que más sorprende. · **Recurso:** https://developer.android.com/develop/sensors-and-location/location/permissions

### AND-02 · nivel 1 · foreground service
¿Por qué el rastreo del viaje necesita un foreground service?
- A) Porque con la app en segundo plano el sistema congela el proceso; el servicio en primer plano, con su notificación persistente, es lo que mantiene el trabajo vivo.
- B) Porque es la única forma de acceder al GPS con precisión alta.
- C) Porque los permisos de ubicación caducan si la app no está visible.
- D) Porque Firestore no puede escribir desde segundo plano.

**Correcta:** A · **Por qué:** la notificación no es decorativa: es el contrato con el usuario a cambio de seguir ejecutando. Sin ella, Android mata el proceso a los pocos minutos. · **Recurso:** https://developer.android.com/develop/background-work/services/foreground-services

### AND-03 · nivel 2 · el manifest
Además del permiso de ubicación, ¿qué hay que declarar para un servicio que rastrea posición en Android 10 o superior?
- A) `android:foregroundServiceType="location"` en el `<service>`, y desde Android 14 también el permiso `FOREGROUND_SERVICE_LOCATION`.
- B) Nada más: el permiso de ubicación ya cubre al servicio.
- C) Un `<receiver>` de arranque para relanzar el servicio.
- D) La bandera `android:persistent="true"` en la aplicación.

**Correcta:** A · **Por qué:** Android exige declarar *para qué* es el servicio. Si el tipo no cuadra con el permiso, el servicio no arranca y la excepción se ve solo en `logcat`. · **Recurso:** https://developer.android.com/develop/background-work/services/foreground-services

### AND-04 · nivel 2 · los fabricantes
Xiaomi, Huawei y Samsung matan servicios en segundo plano de forma agresiva. En esta tesis, ¿cómo se trata ese hecho?
- A) Como una limitación real y documentada: se mitiga guiando al usuario a desactivar la optimización de batería, y se reporta en el capítulo de resultados.
- B) Como un error de la app que hay que resolver antes de entregar.
- C) Como algo que se soluciona pidiendo permiso de administrador de dispositivo.
- D) Como un problema de Flutter que desaparece compilando en modo release.

**Correcta:** A · **Por qué:** no tiene solución técnica completa: son capas del fabricante por encima de Android. Documentarla con honestidad vale más que fingir que no existe. · **Recurso:** https://dontkillmyapp.com

### AND-05 · nivel 2 · fina vs aproximada
¿Qué diferencia hay entre `ACCESS_COARSE_LOCATION` y `ACCESS_FINE_LOCATION`?
- A) `COARSE` da una posición aproximada, del orden de un par de kilómetros, y `FINE` la precisa del GPS; desde Android 12 el usuario puede conceder solo la aproximada aunque la app pida la precisa.
- B) `COARSE` es para segundo plano y `FINE` para primer plano.
- C) `FINE` incluye la altitud y `COARSE` solo latitud y longitud.
- D) `COARSE` está obsoleto desde Android 12 y ya no se declara.

**Correcta:** A · **Por qué:** para el filtrado geográfico de Cupo, una posición aproximada de kilómetros es inservible: hay que detectar ese caso y explicárselo al usuario. · **Recurso:** https://developer.android.com/develop/sensors-and-location/location/permissions

### AND-06 · nivel 2 · la API de geolocator
Para el viaje en curso hace falta la posición de forma continua. ¿Qué corresponde usar?
- A) `Geolocator.getPositionStream(locationSettings: ...)`, que emite posiciones según la distancia o el intervalo configurados.
- B) `getCurrentPosition()` dentro de un `Timer.periodic` de un segundo.
- C) `getLastKnownPosition()`, que se actualiza sola en segundo plano.
- D) `Geolocator.checkPermission()`, que devuelve la posición junto con el permiso.

**Correcta:** A · **Por qué:** el stream deja que el sistema agrupe y optimice las lecturas del GPS. Un timer manual gasta más batería y no sobrevive en segundo plano. · **Recurso:** https://pub.dev/packages/geolocator

### AND-07 · nivel 3 · "Solo esta vez"
El usuario elige "Solo esta vez" en el diálogo de ubicación. ¿Qué implica?
- A) Que el permiso dura mientras la app esté en uso y se revoca al cerrarla: hay que comprobarlo en cada arranque y no darlo nunca por concedido.
- B) Que queda concedido hasta que el usuario lo revoque manualmente.
- C) Que se concede solo la ubicación aproximada.
- D) Que la app no podrá volver a pedirlo nunca más.

**Correcta:** A · **Por qué:** de ahí la regla general: comprobar el permiso justo antes de usarlo, no una sola vez en el onboarding. · **Recurso:** https://developer.android.com/develop/sensors-and-location/location/permissions

### AND-08 · nivel 3 · el proceso en segundo plano
Con la app en segundo plano y sin foreground service, ¿qué le pasa al código Dart?
- A) El sistema puede detener el proceso en cualquier momento: los timers y los listeners dejan de ejecutarse, y no hay aviso garantizado antes de que ocurra.
- B) Sigue ejecutándose igual, solo que sin dibujar la interfaz.
- C) Se pausa y se reanuda exactamente donde estaba al volver, sin pérdida.
- D) Flutter lo migra automáticamente a un isolate de segundo plano.

**Correcta:** A · **Por qué:** es justo lo que el Spike 1 tiene que medir. Si resulta que no se puede rastrear con la pantalla apagada, cambia la arquitectura del viaje en vivo. · **Recurso:** https://developer.android.com/guide/components/activities/process-lifecycle

### AND-09 · nivel 3 · permiso denegado para siempre
`Geolocator.checkPermission()` devuelve `LocationPermission.deniedForever`. ¿Qué hace la app?
- A) Deja de pedirlo —el sistema ya no mostrará el diálogo— y ofrece un botón que abre los ajustes de la app con `Geolocator.openAppSettings()`.
- B) Vuelve a llamar a `requestPermission()` hasta que el usuario ceda.
- C) Cierra la app con un mensaje de error.
- D) Continúa con la ubicación aproximada, que no requiere permiso.

**Correcta:** A · **Por qué:** tras dos rechazos Android bloquea el diálogo de forma permanente. La única vía es los ajustes, y hay que explicar por qué antes de mandar al usuario ahí. · **Recurso:** https://pub.dev/packages/geolocator
