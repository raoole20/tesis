# Correcciones al Capítulo IV — texto listo para pegar

Hoja de trabajo para corregir `Capítulo 4.pdf` en el `.docx` original. Este
archivo **no** es una copia de lectura: es texto propuesto. Cada bloque indica
dónde va y qué reemplaza. Lo que está entre corchetes `[...]` debe completarlo
o confirmarlo el equipo antes de pegarlo.

Base de cada cifra: las Tablas 1–21 y los Cuadros 4–15 del propio Cap. IV.

---

## 0. Nueva estructura y renumeración

Al insertar el levantamiento de requerimientos (actividad 1.2) antes del
catálogo de historias, y las actividades 1.4 y 1.5 después, el apartado
1.1.1 queda así:

| Apartado | Contenido | Actividad (Cuadro 2, Cap. III) |
| --- | --- | --- |
| 1.1.1.1 | Entrevista a choferes (sin cambios) | 1.1 |
| 1.1.1.2 | Encuesta a estudiantes (sin cambios, salvo §5) | 1.1 |
| **1.1.1.3** | **Levantamiento de requerimientos funcionales y no funcionales (nuevo)** | 1.2 |
| 1.1.1.4 | Redacción y priorización del catálogo de historias de usuario (antes 1.1.1.3) | 1.3 |
| **1.1.1.5** | **Estimación de tiempos y recursos por módulo (nuevo)** | 1.4 |
| **1.1.1.6** | **Organización de las pautas de trabajo y programación en pares (nuevo)** | 1.5 |

Renumeración de cuadros (las Tablas 1–21 no cambian):

| Antes | Después | Contenido |
| --- | --- | --- |
| — | **16** | Requerimientos funcionales (nuevo) |
| — | **17** | Requerimientos no funcionales (nuevo) |
| — | **18** | Necesidades fuera del alcance (nuevo) |
| 16 a 24 | 19 a 27 | HU-001 a HU-009 |
| 25 | 28 | HU-010 (**eliminar la copia duplicada**) |
| 26 | 29 | HU-011 |
| 27 | 30 | HU-012 |
| — | **31 a 34** | HU-013 a HU-016 (nuevas) |
| — | **35** | Estimación y plan de iteraciones por módulo (nuevo) |
| — | **36** | Rotación de pares por iteración (nuevo) |

Recuerda actualizar también las referencias en el texto: cada párrafo que
sigue a una historia dice «Cuadro 16 (HU-001)», «Cuadro 17 (HU-002)», etc.
Las referencias a los Cuadros 4 a 15 (entrevistas) no cambian.

---

## 1. Cifras sin respaldo en los párrafos de HU-004 y HU-011

### 1.1 Párrafo después de HU-004

**Reemplaza** el párrafo que empieza «Mediante la historia de usuario HU-004…»:

> Mediante la historia de usuario HU-004 (Cuadro 22), se atiende la exigencia
> de seguridad y confianza expresada por los estudiantes encuestados: el 64,7 %
> considera la seguridad, la confianza y la recomendación del conductor un
> factor determinante al elegir transportista (Tabla 7), el mismo porcentaje
> considera indispensable ver la identidad verificada del chofer en su perfil,
> y el 58,8 % exige conocer los datos del vehículo (Tabla 8). Ningún conductor
> puede ofrecer cupos ni visualizar ubicaciones estudiantiles hasta haber
> completado el registro de su unidad y superado el filtro de verificación.

### 1.2 Párrafo después de HU-011

**Reemplaza** el párrafo que empieza «La historia de usuario HU-011…»:

> La historia de usuario HU-011 (Cuadro 29) constituye el núcleo tecnológico
> del Sistema de Información Geográfico móvil en tiempo real. Responde a la
> condición indispensable señalada por T-01 y T-05 (Cuadro 15), quienes piden
> que tanto el transportista como el estudiante conozcan la ubicación de la
> unidad durante la ruta, y a la incertidumbre de los estudiantes: el 47,1 %
> espera más de cinco minutos a que pase el transporte (Tabla 17) y el 41,2 %
> considera indispensable ver la ubicación en vivo sobre un mapa (Tabla 19).
> Su implementación busca reducir las esperas en la vía pública y evita que el
> conductor tenga que manipular el teléfono para enviar mensajes o realizar
> llamadas mientras maneja.

> Nota: además de la cifra, se cambió «erradica» por «busca reducir». El efecto
> aún no se ha medido; afirmarlo antes de la Fase IV es una conclusión
> adelantada que el jurado puede observar.

---

## 2. Apartado nuevo 1.1.1.3 — Requerimientos funcionales y no funcionales

**Inserta** este apartado completo después del análisis de la Tabla 21 y antes
del catálogo de historias de usuario.

---

**1.1.1.3. LEVANTAMIENTO DE REQUERIMIENTOS FUNCIONALES Y NO FUNCIONALES**

En cumplimiento del segundo objetivo específico de la investigación, que
consiste en determinar los requerimientos funcionales y no funcionales para el
desarrollo de la aplicación, y de la actividad 1.2 de la Fase I, los hallazgos
obtenidos con la entrevista a los transportistas y la encuesta a los
estudiantes se tradujeron en un conjunto de requerimientos del sistema. Cada
requerimiento se vincula con el cuadro o la tabla que le da origen, de modo que
toda funcionalidad de la aplicación responde a una necesidad expresada por los
informantes clave y no a un supuesto de los investigadores.

Los requerimientos funcionales describen lo que la aplicación debe hacer para
cada uno de sus actores (estudiante, conductor y administrador), y se presentan
en el Cuadro 16.

**Cuadro 16**
**Requerimientos funcionales de la aplicación**

| Código | Requerimiento | Origen | Historia |
| --- | --- | --- | --- |
| RF-01 | Registrar usuarios con el rol de estudiante o de conductor, con sus datos de identificación. | Base del sistema | HU-001 |
| RF-02 | Autenticar al usuario y dirigirlo a la pantalla que corresponde a su rol y al estado de su cuenta. | Base del sistema | HU-002 |
| RF-03 | Permitir al estudiante fijar la ubicación exacta de su domicilio en un mapa interactivo como punto de recogida. | Tabla 10 (88,2 % puerta a puerta); Tabla 11 (58,8 % no camina) | HU-003 |
| RF-04 | Identificar automáticamente la zona geográfica a la que pertenece el domicilio del estudiante. | Cuadro 4; Tabla 2 | HU-003 |
| RF-05 | Registrar los datos del conductor, su licencia y su vehículo, y enviarlos a verificación. | Cuadro 15 (T-02); Tablas 7 y 8 | HU-004 |
| RF-06 | Permitir al administrador aprobar, rechazar con motivo o suspender las cuentas de los conductores. | Tablas 7 y 8 | HU-012 |
| RF-07 | Permitir al administrador mantener el catálogo de zonas geográficas activas. | Cuadro 4 | HU-012 |
| RF-08 | Permitir al conductor seleccionar en el mapa las zonas de cobertura de su servicio. | Cuadro 4 | HU-005 |
| RF-09 | Permitir al conductor publicar turnos con horario, días de operación, sentido del servicio (ida, regreso o ambos), cupos y tarifa. | Cuadro 5; Tablas 4, 5 y 13 | HU-006 |
| RF-10 | Permitir al estudiante buscar transportistas por zona y turno, y ver su perfil verificado, vehículo, tarifa y cupos libres. | Cuadro 10; Tablas 6, 8 y 9 | HU-007 |
| RF-11 | Permitir al estudiante solicitar un cupo indicando los días de la semana en que asiste a clases. | Cuadro 6; Tabla 3 | HU-008 |
| RF-12 | Permitir al conductor evaluar cada solicitud viendo en el mapa el domicilio del solicitante y su perfil, y aceptarla o rechazarla. | Cuadros 8, 9 y 15 | HU-009 |
| RF-13 | Controlar la ocupación de cada turno sin exceder la capacidad del vehículo. | Cuadro 13 | HU-006, HU-009 |
| RF-14 | Permitir al estudiante renovar su cupo para el siguiente período académico dentro de un plazo, y liberar el cupo no renovado. | Cuadro 7; Tabla 15 | HU-016 |
| RF-15 | Permitir al estudiante notificar su inasistencia y mostrar al conductor la nómina diaria de pasajeros de cada turno. | Cuadros 11 y 15 (T-04); Tabla 20 | HU-010 |
| RF-16 | Transmitir la posición del vehículo durante el recorrido y mostrarla en tiempo real a los estudiantes del turno. | Cuadro 15 (T-01, T-05); Tabla 19 | HU-011 |
| RF-17 | Notificar al estudiante cuando la unidad se encuentre cerca de su punto de recogida. | Cuadro 12; Tablas 17 y 19 | HU-014 |
| RF-18 | Permitir al conductor enviar un aviso de contingencia a todos los estudiantes de un turno. | Cuadro 14; Tablas 16 y 18 | HU-015 |
| RF-19 | Permitir al conductor registrar los pagos recibidos y al estudiante consultar su estado de cuenta. | Cuadro 13; Tablas 7, 12 y 14 | HU-013 |

Fuente: Andrade, Espina y Ramírez (2026)

Como se observa en el Cuadro 16, los requerimientos funcionales se agrupan en
torno a tres necesidades que aparecen de manera consistente en ambos
instrumentos: la localización y el emparejamiento geográfico entre estudiantes
y transportistas (RF-03 a RF-12), la gestión formal de los cupos, que hoy
depende de acuerdos verbales y libretas (RF-13, RF-14 y RF-19), y la
comunicación oportuna durante la operación diaria (RF-15 a RF-18).

Por su parte, los requerimientos no funcionales establecen las condiciones de
calidad bajo las cuales la aplicación debe prestar esas funciones. Se presentan
en el Cuadro 17.

**Cuadro 17**
**Requerimientos no funcionales de la aplicación**

| Código | Atributo | Requerimiento | Origen |
| --- | --- | --- | --- |
| RNF-01 | Usabilidad | La interfaz debe ser sencilla e intuitiva y permitir al conductor operar con el mínimo de interacciones entre recorridos. | Cuadro 15 (T-03) |
| RNF-02 | Eficiencia | La aplicación debe limitar el consumo de datos móviles y de batería, en especial durante la transmisión de la ubicación. | Cuadro 15 (T-03) |
| RNF-03 | Precisión | El domicilio y la posición del vehículo deben registrarse con precisión suficiente para la recogida puerta a puerta. | Cuadro 15 (T-01); Tablas 10 y 11 |
| RNF-04 | Tiempo real | La posición de la unidad, el estado de las solicitudes y los cupos libres deben actualizarse sin que el usuario recargue la pantalla. | Cuadro 15 (T-01, T-05) |
| RNF-05 | Seguridad | Solo los usuarios autenticados acceden al sistema, cada uno ve únicamente la información que le corresponde y el domicilio del estudiante solo lo ve el conductor que evalúa o atiende su cupo. | Cuadro 8 (T-04); Tablas 7 y 8 |
| RNF-06 | Integridad | Ante solicitudes simultáneas, el sistema no debe asignar más cupos que la capacidad del turno. | Cuadro 13 |
| RNF-07 | Disponibilidad | El servicio debe estar disponible en todos los turnos de operación, incluido el nocturno. | Tabla 4 (47,1 % turno noche) |
| RNF-08 | Tolerancia a fallos | La aplicación debe reintentar el envío de la ubicación y de los avisos ante cortes breves de conexión. | Cuadro 14 |
| RNF-09 | Portabilidad | La aplicación debe funcionar en teléfonos inteligentes Android de gama media y baja. | [completar: versión mínima de Android] |
| RNF-10 | Localización | La interfaz debe estar en español de Venezuela y usar los formatos locales de cédula, teléfono y métodos de pago. | Tabla 14 |

Fuente: Andrade, Espina y Ramírez (2026)

Los requerimientos no funcionales del Cuadro 17 se desprenden, en buena
medida, de la última pregunta de la entrevista (Cuadro 15), en la que los
transportistas expresaron las condiciones indispensables para adoptar la
aplicación: precisión de la ubicación, facilidad de uso y bajo consumo de
datos. A ello se suma la preocupación por la seguridad que manifestaron tanto
los choferes como los estudiantes.

Finalmente, no todas las necesidades identificadas pueden atenderse en el
alcance de la presente investigación. El Cuadro 18 resume las que se
excluyen y la razón de cada decisión.

**Cuadro 18**
**Necesidades identificadas fuera del alcance de la aplicación**

| Necesidad | Origen | Decisión |
| --- | --- | --- |
| Calificaciones y comentarios de otros estudiantes sobre el transportista | Tabla 8 (58,8 %) | Se excluye. La confianza se atiende con la verificación de identidad y vehículo por el administrador (HU-004 y HU-012). Se propone como trabajo futuro. |
| Tiempo estimado de llegada calculado sobre la red vial | Cuadro 15 (T-01); Tabla 19 (35,3 %) | Se excluye, porque exige un motor de ruteo. La necesidad se cubre con la ubicación en vivo (HU-011) y el aviso de proximidad (HU-014), que fue la opción más demandada (76,5 %). |
| Procesamiento de pagos dentro de la aplicación | Tablas 7 y 14 | Se excluye. La aplicación registra los pagos realizados por los medios que ya usan las partes (HU-013), sin integrarse con entidades bancarias. |
| Mensajería instantánea entre conductor y estudiantes | Cuadro 10 | Se excluye. La comunicación operativa se canaliza por avisos estructurados (HU-010 y HU-015) y el teléfono visible en el perfil. |
| Propuesta automática de puntos de encuentro | Cuadro 9; Tabla 11 | Se excluye. El 88,2 % de los estudiantes es recogido puerta a puerta (Tabla 10), por lo que la recogida se hace en el domicilio registrado (HU-003). |

Fuente: Andrade, Espina y Ramírez (2026)

> **Decisión del equipo:** el Cuadro 18 es una propuesta. Si deciden incluir
> las calificaciones, hay que redactar una HU-017 y quitar esa fila. Si dejan
> el cuadro como está, apliquen también el ajuste del §5.1.

---

## 3. Catálogo de historias de usuario (apartado 1.1.1.4)

### 3.1 Párrafo de apertura

**Reemplaza** el párrafo que empieza «Siguiendo las directrices de la Fase I…»:

> **1.1.1.4. REDACCIÓN Y PRIORIZACIÓN DEL CATÁLOGO DE HISTORIAS DE USUARIO**
>
> Siguiendo las directrices de la Fase I de la metodología Programación
> Extrema (Beck, 2004) y en cumplimiento de la tercera actividad planificada,
> los requerimientos funcionales y no funcionales presentados en los Cuadros 16
> y 17 fueron traducidos en un catálogo estructurado de dieciséis (16) Historias
> de Usuario (HU). En XP, las historias de usuario constituyen artefactos ágiles
> centrados en el valor entregado a cada actor, especificando de manera concisa
> las precondiciones, los criterios de aceptación ante escenarios de éxito o
> fallo, y las reglas de validación del negocio. A continuación, se presentan
> los cuadros correspondientes al catálogo de historias de usuario de la
> aplicación desarrollada.

### 3.2 Historias nuevas

**Inserta** estos cuatro cuadros después del párrafo que cierra HU-012
(Cuadro 30), con el mismo formato de tabla que las anteriores.

---

**Cuadro 31**
**Historia de usuario 13**

| Campo | Contenido |
| --- | --- |
| Nombre de la Historia | Registro de pagos y estado de cuenta |
| Id Historia | HU-013 |
| Actores | Conductor aprobado y Estudiante inscrito |
| Prioridad | Media |
| Descripción | Como conductor, deseo registrar los pagos que recibo de cada estudiante inscrito, indicando el monto, el método y el período que cubre, para llevar el control de la cobranza sin depender de una libreta; y como estudiante, deseo consultar mi estado de cuenta para saber qué períodos tengo pagados y cuáles pendientes. |
| Pre-Condiciones | El estudiante debe poseer una inscripción aceptada en un turno del conductor, y el turno debe tener definidas su tarifa y su modalidad de cobro (semanal, quincenal o mensual). |
| **Criterios de aceptación** | |
| 1. Registro exitoso | Ocurre cuando el conductor selecciona al estudiante, indica el monto, el método de pago (dólares en efectivo, Pago Móvil, Zelle o bolívares en efectivo) y el período que cubre, y confirma. El sistema guarda el pago, marca el período como pagado y actualiza el estado de cuenta que consulta el estudiante. |
| 2. Registro fallido | Si el monto no es un valor positivo, falta el método de pago o el período ya figura como pagado, el sistema impide el registro e indica el dato que debe corregirse. |
| Validaciones | - La aplicación registra el pago, no lo procesa: el dinero se entrega por los medios que ya utilizan las partes. <br> - Solo el conductor del turno puede registrar o anular los pagos de sus estudiantes; el estudiante únicamente consulta los propios. <br> - Los períodos vencidos sin pago registrado se muestran como pendientes. |

Fuente: Andrade, Espina y Ramírez (2026)

La historia de usuario HU-013 (Cuadro 31) sustituye la libreta y los acuerdos
verbales descritos por los transportistas en el Cuadro 13 por un historial de
pagos que ambas partes pueden consultar. Contempla las tres modalidades de
cobro reportadas por los estudiantes (Tabla 12) y los métodos de pago más
utilizados, el dólar en efectivo (70,6 %) y el Pago Móvil (58,8 %) (Tabla 14).
La aplicación no procesa transacciones, sino que deja constancia de ellas, lo
que aporta transparencia y trazabilidad sin exigir integraciones bancarias.

---

**Cuadro 32**
**Historia de usuario 14**

| Campo | Contenido |
| --- | --- |
| Nombre de la Historia | Aviso de proximidad de la unidad |
| Id Historia | HU-014 |
| Actores | Estudiante inscrito |
| Prioridad | Alta |
| Descripción | Como estudiante inscrito, deseo recibir una notificación en mi teléfono cuando la unidad se encuentre cerca de mi punto de recogida, para salir de mi casa en el momento oportuno sin tener que vigilar el mapa. |
| Pre-Condiciones | El conductor debe haber iniciado el recorrido (HU-011), el estudiante debe figurar en la nómina del día (HU-010) y debe haber concedido a la aplicación el permiso de notificaciones. |
| **Criterios de aceptación** | |
| 1. Aviso enviado | Cuando la posición transmitida por la unidad entra en el radio de proximidad del domicilio del estudiante, el sistema le envía una única notificación indicando que su transporte está cerca, aunque la aplicación se encuentre cerrada. |
| 2. Aviso no entregado / Fallo | Si el estudiante negó el permiso de notificaciones, la aplicación le informa que no recibirá avisos y le ofrece activarlo desde los ajustes del teléfono. Si el recorrido finaliza antes de que la unidad entre en el radio, no se envía el aviso. |
| Validaciones | - El radio de proximidad es una distancia configurable, que se calibrará en las pruebas para ofrecer entre cinco (5) y diez (10) minutos de anticipación. <br> - Se envía un solo aviso por estudiante y por recorrido. <br> - No se notifica a los estudiantes que marcaron inasistencia para ese día. |

Fuente: Andrade, Espina y Ramírez (2026)

La historia de usuario HU-014 (Cuadro 32) atiende la funcionalidad más
solicitada por los estudiantes encuestados: el 76,5 % considera indispensable
recibir una notificación automática cuando el transporte se encuentre a cinco
o diez minutos (Tabla 19). Al mismo tiempo, responde a la preocupación de los
transportistas T-02 y T-04 por que la impuntualidad de un estudiante no
perjudique a los demás pasajeros (Cuadro 12), y reduce el tiempo que el
estudiante permanece en la calle, aspecto relevante si se considera que el
47,1 % estudia en el turno de la noche (Tabla 4).

---

**Cuadro 33**
**Historia de usuario 15**

| Campo | Contenido |
| --- | --- |
| Nombre de la Historia | Aviso de contingencia a los pasajeros del turno |
| Id Historia | HU-015 |
| Actores | Conductor aprobado |
| Prioridad | Media |
| Descripción | Como conductor, deseo enviar en un solo paso un aviso a todos los estudiantes de un turno cuando ocurra una avería, falta de combustible, cierre de vías u otra contingencia, indicando el motivo y la demora estimada, para que puedan tomar previsiones sin que tenga que contactarlos uno por uno. |
| Pre-Condiciones | El conductor debe tener un turno activo con al menos un (1) estudiante en la nómina del día. |
| **Criterios de aceptación** | |
| 1. Aviso enviado | Ocurre cuando el conductor elige el turno, selecciona el motivo (avería, combustible, vía cerrada u otro), indica la demora estimada o la cancelación del recorrido y confirma. Todos los estudiantes de la nómina reciben la notificación y ven el aviso en el detalle del turno. |
| 2. Envío fallido | Si el conductor elige «otro» sin describir el motivo, la aplicación impide el envío. Si no hay conexión, la aplicación conserva el aviso, lo reintenta automáticamente y le indica al conductor que aún no ha sido entregado. |
| Validaciones | - Solo el conductor del turno puede enviar avisos a sus estudiantes. <br> - Cada aviso queda registrado con su fecha y hora en el historial del turno. <br> - Si el aviso cancela el recorrido, el viaje del día queda marcado como cancelado. |

Fuente: Andrade, Espina y Ramírez (2026)

La historia de usuario HU-015 (Cuadro 33) formaliza la práctica descrita por
los transportistas en el Cuadro 14, quienes hoy enfrentan las contingencias
llamando o escribiendo a cada estudiante. La falta de aviso oportuno ante
retrasos o averías es el problema más reportado por los estudiantes que
declararon alguna dificultad (17,6 %, Tabla 16), y sus consecuencias incluyen
llegar tarde o perder evaluaciones (29,4 %) y pagar un taxi de emergencia
(17,6 %) (Tabla 18).

---

**Cuadro 34**
**Historia de usuario 16**

| Campo | Contenido |
| --- | --- |
| Nombre de la Historia | Renovación del cupo para el siguiente período |
| Id Historia | HU-016 |
| Actores | Estudiante inscrito y Conductor aprobado |
| Prioridad | Media |
| Descripción | Como estudiante inscrito, deseo confirmar en la aplicación que continuaré en el servicio el próximo período académico, para conservar mi cupo sin depender de un acuerdo verbal; y como conductor, deseo ver quiénes renovaron para conocer los cupos que quedarán libres antes de iniciar el período. |
| Pre-Condiciones | El conductor debe haber abierto la renovación de su turno, indicando la fecha de inicio del nuevo período y la fecha límite para confirmar. El estudiante debe poseer una inscripción aceptada en ese turno. |
| **Criterios de aceptación** | |
| 1. Renovación exitosa | Ocurre cuando, dentro del plazo, el estudiante selecciona «Renovar mi cupo» y, si lo desea, ajusta sus días de asistencia. El sistema conserva su puesto para el nuevo período y lo muestra como renovado en la lista del conductor. |
| 2. Plazo vencido / Fallo | Si la fecha límite transcurre sin confirmación, el sistema libera el cupo, lo vuelve visible en las búsquedas y notifica al estudiante. Si este intenta renovar después del plazo, debe enviar una nueva solicitud (HU-008). |
| Validaciones | - El sistema envía un recordatorio al estudiante antes de la fecha límite. <br> - Un estudiante solo puede renovar el cupo del turno en el que estaba inscrito. <br> - Las renovaciones no pueden exceder la capacidad del turno. |

Fuente: Andrade, Espina y Ramírez (2026)

Con la historia de usuario HU-016 (Cuadro 34) se sustituye el mecanismo
informal de reserva entre períodos descrito por los transportistas en el
Cuadro 7. Según la Tabla 15, el 52,9 % de los estudiantes conserva su cupo
gracias a un acuerdo verbal, el 29,4 % tuvo que pagar por adelantado durante
las vacaciones para apartarlo y un 5,9 % se quedó sin transporte por falta de
comunicación. La renovación con plazo y recordatorio brinda certeza a ambas
partes y permite al conductor conocer con anticipación los cupos disponibles.

---

## 4. Apartados nuevos 1.1.1.5 y 1.1.1.6 (actividades 1.4 y 1.5)

**Inserta** ambos apartados después del párrafo que cierra HU-016.

> Estos apartados llevan estimaciones y asignaciones que **tiene que validar
> el equipo**. Las cifras son una propuesta coherente con el cronograma del
> Cap. III (Cuadro 3: codificación de Dic S3 a Feb S2, cuatro iteraciones de
> dos semanas) y con lo que ya está construido. No las peguen sin revisarlas.

---

**1.1.1.5. ESTIMACIÓN DE TIEMPOS Y RECURSOS POR MÓDULO**

En atención a la cuarta actividad de la Fase I, y conforme al juego de la
planificación propuesto por Beck (2004), las historias de usuario se agruparon
en módulos funcionales y se estimaron en puntos de historia, donde un (1)
punto equivale a un día ideal de trabajo de una pareja de programación, es
decir, sin interrupciones. Las historias se distribuyeron luego en cuatro (4)
iteraciones de dos semanas, que corresponden al período de codificación
previsto en el cronograma de actividades del Capítulo III (Cuadro 3).

Para definir la carga de cada iteración se consideró una velocidad inicial
estimada de [completar: 10 a 12] puntos por iteración, de acuerdo con la
disponibilidad de los tres integrantes del equipo. Conforme a la práctica de
XP, esta velocidad se recalculará al cierre de cada iteración con los puntos
efectivamente completados, y las historias pendientes se reasignarán según su
prioridad. La estimación resultante se presenta en el Cuadro 35.

**Cuadro 35**
**Estimación y plan de iteraciones por módulo**

| Módulo | Historias | Puntos | Iteración | Recursos técnicos |
| --- | --- | --- | --- | --- |
| M1. Acceso y cuentas | HU-001 (2), HU-002 (2) | 4 | 1 | Flutter y Dart; Supabase Auth; PostgreSQL |
| M2. Verificación y administración | HU-004 (3), HU-012 (3) | 6 | 1 | Supabase Storage para fotos y documentos; políticas de seguridad a nivel de fila (RLS) |
| M3. Geolocalización y zonas | HU-003 (3), HU-005 (3) | 6 | 1 y 2 | PostGIS; flutter_map con OpenStreetMap; GPS del dispositivo |
| M4. Oferta y búsqueda de transporte | HU-006 (3), HU-007 (3) | 6 | 2 | PostgreSQL y PostGIS; consultas por zona y turno |
| M5. Gestión de cupos | HU-008 (2), HU-009 (3), HU-016 (2) | 7 | 3 | Transacciones en PostgreSQL; Supabase Realtime |
| M6. Pagos | HU-013 (3) | 3 | 3 | PostgreSQL |
| M7. Operación diaria y seguimiento | HU-010 (3), HU-011 (5), HU-014 (2), HU-015 (2) | 12 | 4 | Supabase Realtime; servicio de ubicación en primer plano de Android; servicio de notificaciones push [completar: proveedor] |
| **Total** | **16 historias** | **44** | **4 iteraciones** | |

Fuente: Andrade, Espina y Ramírez (2026)

Distribución por iteración: la Iteración 1 (Dic S3–Dic S4) reúne las
historias de acceso, verificación y domicilio (HU-001 a HU-004 y HU-012,
13 puntos); la Iteración 2 (Ene S1–Ene S2), las zonas del conductor, los
turnos y la búsqueda (HU-005 a HU-007, 9 puntos); la Iteración 3
(Ene S3–Ene S4), la gestión de cupos y los pagos (HU-008, HU-009, HU-013 y
HU-016, 10 puntos); y la Iteración 4 (Feb S1–Feb S2), la operación diaria y el
seguimiento en tiempo real (HU-010, HU-011, HU-014 y HU-015, 12 puntos). La
historia de mayor estimación es HU-011 (5 puntos), por depender de la
transmisión continua de la ubicación en el dispositivo del conductor, el
principal riesgo técnico del proyecto.

En cuanto a los recursos humanos, cada módulo es desarrollado por una pareja
de programación, mientras el tercer integrante prepara las pruebas de
aceptación y revisa la integración, según la rotación definida en el apartado
siguiente. Como recurso de hardware, se requiere al menos un teléfono Android
físico para las pruebas de ubicación y notificaciones, que no pueden
verificarse por completo en un emulador.

---

**1.1.1.6. ORGANIZACIÓN DE LAS PAUTAS DE TRABAJO Y PROGRAMACIÓN EN PARES**

Para completar la Fase I, y en cumplimiento de la quinta actividad
planificada, el equipo acordó las pautas de trabajo que regirán la fase de
codificación, basadas en las prácticas de la Programación Extrema descritas
por Beck (2004): programación en pares, desarrollo guiado por pruebas,
estándares de codificación, integración continua, propiedad colectiva del
código y ritmo sostenible. Las pautas acordadas son las siguientes:

1. **Programación en pares.** Toda historia de usuario se codifica en pareja:
   un integrante escribe el código mientras el otro revisa y propone mejoras,
   y ambos intercambian el rol durante la sesión. El tercer integrante redacta
   las pruebas de aceptación de las historias de la iteración y revisa cada
   integración. Las parejas rotan en cada iteración, según el Cuadro 36.
2. **Desarrollo guiado por pruebas.** Antes de implementar una funcionalidad
   se escribe la prueba automatizada que la verifica. Una historia se
   considera terminada solo cuando todas sus pruebas pasan y se cumplen sus
   criterios de aceptación.
3. **Estándares de codificación.** El código sigue la guía de estilo del
   proyecto, que define la estructura de carpetas, la nomenclatura y el
   sistema de diseño de la interfaz. Ningún cambio se integra con advertencias
   del analizador estático del lenguaje.
4. **Integración continua.** El código se aloja en un repositorio Git en
   GitHub. Cada historia se desarrolla en una rama propia, que se integra a la
   rama principal mediante una solicitud de integración (pull request) revisada
   por un integrante que no la escribió. Las integraciones son frecuentes y
   pequeñas, para evitar conflictos.
5. **Propiedad colectiva del código.** Cualquier integrante puede modificar
   cualquier parte del sistema. Cada cambio referencia el identificador de la
   historia que atiende (por ejemplo, HU-008), lo que permite rastrear el
   aporte de cada integrante.
6. **Ritmo sostenible.** Cada integrante dedica [completar: N] horas semanales
   al proyecto, distribuidas en sesiones de pares acordadas al inicio de la
   iteración y compatibles con la carga académica. No se planifican horas
   extra de manera sostenida: si la velocidad real resulta menor a la
   estimada, se ajusta el alcance de la iteración y no la jornada.
7. **Reuniones.** Cada iteración inicia con una sesión de planificación, en
   la que se seleccionan y estiman las historias, y cierra con una revisión
   de lo entregado. Durante la iteración, el equipo mantiene una reunión
   breve de seguimiento [completar: frecuencia] para reportar avances e
   impedimentos.

**Cuadro 36**
**Rotación de pares por iteración**

| Iteración | Período | Pareja de programación | Pruebas de aceptación y revisión |
| --- | --- | --- | --- |
| 1 | Dic S3 – Dic S4 | Espina y Andrade | Ramírez |
| 2 | Ene S1 – Ene S2 | Andrade y Ramírez | Espina |
| 3 | Ene S3 – Ene S4 | Ramírez y Espina | Andrade |
| 4 | Feb S1 – Feb S2 | Espina y Andrade | Ramírez |

Fuente: Andrade, Espina y Ramírez (2026)

Con esta rotación, cada integrante programa en al menos tres de las cuatro
iteraciones y asume en al menos una el rol de responsable de las pruebas, lo
que favorece la propiedad colectiva del código y el conocimiento compartido de
todos los módulos de la aplicación.

---

## 5. Ajustes menores para mantener la coherencia

Estos cambios evitan que el análisis prometa algo que ninguna historia cumple.

### 5.1 Análisis de la Tabla 8 (solo si las calificaciones quedan fuera)

**Reemplaza** el segundo párrafo, que empieza «Estos resultados indican que la
aplicación debe incorporar…»:

> Estos resultados indican que la aplicación debe incorporar un sistema robusto
> de perfiles verificados que incluya la documentación del conductor y del
> vehículo, así como la visualización de las zonas que atiende. Si bien las
> calificaciones de otros estudiantes obtuvieron un porcentaje relevante
> (58,8 %), su implementación se plantea como trabajo futuro (Cuadro 18): en
> esta primera versión, la confianza se sustenta en la verificación previa del
> conductor por parte del administrador.

### 5.2 Análisis del Cuadro 9

En el segundo párrafo, **reemplaza** «muestre al transportista la distancia y
el tiempo adicional que implicaría el desvío» por:

> muestre al transportista, sobre el mapa, la ubicación del domicilio del
> solicitante respecto a su zona de cobertura

(El tiempo adicional exige un motor de ruteo, que queda fuera del alcance,
Cuadro 18.)

### 5.3 HU-006 (Cuadro 24): sentido del servicio

La Tabla 5 concluye que la aplicación «debe permitir la contratación del
servicio en ambas modalidades (solo ida, solo vuelta o completo)», pero HU-006
no lo recoge. **Agrega** a sus Validaciones:

> - El turno debe indicar si ofrece servicio de ida, de regreso o ambos.

Corrige además la numeración de sus criterios: «3. Publicación fallida» debe
ser «2. Publicación fallida».

### 5.4 Eliminar la copia duplicada de HU-010

Borra el segundo «Cuadro 25 / Historia de usuario 10», que aparece después de
HU-011 junto con su párrafo, y que tiene los criterios numerados 3 y 4.
