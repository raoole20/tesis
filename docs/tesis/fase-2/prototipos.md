# Prototipos de interfaz: figuras para el Capítulo IV

Actividad 2.4 de la Fase II: *Construcción de prototipos de interfaz de usuario
(UI/UX) para mapas y paradas*.

- Fuente navegable: [`prototipos.html`](prototipos.html) (las 13 pantallas en
  cuadrícula, con su historia de usuario).
- Imágenes para insertar: carpeta [`prototipos/`](prototipos/), PNG a 2×
  (824 × 1664 px; la Figura 1 lleva dos teléfonos y mide 1632 × 1728 px).

> **Numeración final:** en la tesis estas figuras son los **Gráficos 35 a 47**
> (Figura N de esta lista = Gráfico N + 34), siguiendo la convención del
> Cap. IV. El texto ya integrado y renumerado está en
> [`fase-2-diseno.md`](fase-2-diseno.md), apartado 1.1.2.4; úsese ese.

## Lista de figuras

| N.º | Pie de figura | Archivo | HU | RF |
| --- | --- | --- | --- | --- |
| 1 | Figura 1. Prototipo de la fijación del domicilio en el mapa: a) zona detectada; b) sector sin cobertura | `prototipos/01-fijar-domicilio.png` | HU-003 | RF-03, RF-04 |
| 2 | Figura 2. Prototipo de los resultados de búsqueda de transportistas por zona | `prototipos/02-resultados-busqueda.png` | HU-007 | RF-10 |
| 3 | Figura 3. Prototipo del detalle del turno y la solicitud de cupo | `prototipos/03-detalle-turno.png` | HU-008 | RF-11 |
| 4 | Figura 4. Prototipo de la vista semanal del estudiante, con aviso de inasistencia y renovación del cupo | `prototipos/04-mi-semana.png` | HU-010, HU-016 | RF-14, RF-15 |
| 5 | Figura 5. Prototipo del seguimiento del viaje en vivo y del aviso de proximidad | `prototipos/05-viaje-en-vivo.png` | HU-011, HU-014 | RF-16, RF-17 |
| 6 | Figura 6. Prototipo del estado de cuenta del estudiante | `prototipos/06-estado-de-cuenta.png` | HU-013 | RF-19 |
| 7 | Figura 7. Prototipo de la selección de zonas de trabajo del conductor | `prototipos/07-zonas-de-trabajo.png` | HU-005 | RF-08 |
| 8 | Figura 8. Prototipo de la creación y publicación de un turno | `prototipos/08-crear-turno.png` | HU-006 | RF-09, RF-13 |
| 9 | Figura 9. Prototipo de la evaluación de una solicitud de cupo por el conductor | `prototipos/09-solicitud-de-cupo.png` | HU-009 | RF-12, RF-13 |
| 10 | Figura 10. Prototipo de la pantalla «Hoy» del conductor, con la nómina y el orden de paradas | `prototipos/10-hoy-conductor.png` | HU-010, HU-011 | RF-15, RF-16 |
| 11 | Figura 11. Prototipo del aviso de contingencia a los pasajeros del turno | `prototipos/11-aviso-contingencia.png` | HU-015 | RF-18 |
| 12 | Figura 12. Prototipo del registro de pagos por el conductor | `prototipos/12-registrar-pago.png` | HU-013 | RF-19 |
| 13 | Figura 13. Prototipo de la revisión del expediente de un conductor por el administrador | `prototipos/13-revision-conductor.png` | HU-012 | RF-05, RF-06 |

Bajo cada figura va la línea de fuente: *Fuente: Andrade, Espina y Ramírez
(2026)*.

## Texto para la tesis

### Párrafo de apertura

En cumplimiento de la cuarta actividad de la Fase II, se construyeron los
prototipos de interfaz de usuario de la aplicación móvil, con énfasis en las
pantallas que operan sobre mapas y paradas. Cada prototipo responde a una o más
historias de usuario del catálogo y a los requerimientos funcionales del
Cuadro 16, de modo que la interfaz materializa las necesidades expresadas por
los transportistas y los estudiantes. Los prototipos se elaboraron en alta
fidelidad, aplicando el sistema de diseño definido para la aplicación: el verde
lago como color de acento, la tipografía Teko para títulos y botones, Manrope
para el resto del texto, la iconografía Lucide y una jerarquía visual basada en
bordes y fondos en lugar de sombras. Los estados se expresan con una
convención cromática constante: verde para lo confirmado, ámbar para lo
pendiente o próximo a vencer y rojo para lo cancelado. Los mapas son
representaciones esquemáticas de la ciudad de Maracaibo, que muestran la
lógica de zonas, domicilios, paradas y unidades sin reproducir la cartografía
real, y los nombres, documentos y montos que aparecen son datos ficticios. Las
Figuras 1 a 13 presentan las pantallas del estudiante, del conductor y del
administrador.

### Figura 1. Fijación del domicilio en el mapa

La Figura 1 muestra el paso en que el estudiante marca su domicilio sobre el
mapa, en atención a la historia de usuario HU-003. Al ubicar el marcador, el
sistema resalta el polígono de la zona que lo contiene y confirma la zona
detectada, junto con las coordenadas del punto y un campo opcional para un
punto de referencia (a). Cuando el domicilio cae fuera de las zonas activas, la
interfaz advierte que el sector aún no tiene cobertura, pero permite guardar la
ubicación para notificar al estudiante cuando un conductor la atienda (b). De
esta forma, el estudiante no necesita conocer la división del servicio: le
basta con señalar su vivienda.

### Figura 2. Resultados de búsqueda

La Figura 2 presenta los transportistas que cubren la zona del estudiante,
según la historia de usuario HU-007. Cada tarjeta reúne los datos que los
estudiantes señalaron como determinantes para elegir un servicio: la foto del
conductor con su marca de verificación, el vehículo, el horario de ida o
regreso, el sentido del servicio, las zonas cubiertas, la tarifa con su
modalidad de cobro y los cupos libres. El contador de cupos cambia a color
ámbar cuando queda un solo puesto, lo que anticipa la disponibilidad sin que
el estudiante tenga que consultar al conductor.

### Figura 3. Detalle del turno y solicitud de cupo

La Figura 3 corresponde a la historia de usuario HU-008. En la parte superior,
el mapa sitúa las zonas que atiende el turno, el domicilio del estudiante y la
URBE; debajo, se resumen el conductor verificado, las horas de ida y de regreso,
la tarifa y los puestos disponibles. El estudiante marca los días de la semana
en que asiste a clases y envía la solicitud con el botón «Solicitar cupo». Un
aviso le indica que el conductor verá la ubicación de su casa y los días
elegidos para decidir, y que no realiza ningún pago en ese momento.

### Figura 4. Mi semana

La Figura 4 reúne dos historias de usuario del estudiante inscrito. Por un
lado, atiende la HU-010: cada día de la semana muestra el estado de la
inscripción (cancelado por el conductor, confirmado, sin clases o con
inasistencia notificada), y el día en curso ofrece el botón «No voy hoy», que
retira al estudiante de la nómina del conductor antes de la salida. Por otro
lado, responde a la HU-016 mediante un aviso de renovación que indica la fecha
límite para conservar el cupo en el período siguiente y advierte que, vencido
el plazo, el puesto queda libre.

### Figura 5. Viaje en vivo y aviso de proximidad

La Figura 5 ilustra las historias de usuario HU-011 y HU-014. El mapa muestra
la posición de la unidad, el domicilio del estudiante con su radio de
proximidad y la URBE como destino, unidos por el trazado del recorrido. Cuando
la unidad entra en ese radio, el estudiante recibe la notificación «Tu
transporte está cerca», aun con la aplicación cerrada. La hoja inferior
resume el avance del viaje en tres hitos (salida, recogida y llegada) con sus
horas previstas, indica cuándo se actualizó la posición y permite llamar al
conductor. Por resguardo de la privacidad, el estudiante no ve los domicilios
de los demás pasajeros.

### Figura 6. Estado de cuenta

La Figura 6 muestra la consulta que la historia de usuario HU-013 prevé para el
estudiante. Se destaca el monto por pagar del período en curso, en estado
pendiente, seguido del método de pago que acepta el conductor y del historial
de períodos, cada uno con su estado y el medio con que se pagó: Pago Móvil,
dólares en efectivo o Zelle. La pantalla aclara que el pago se entrega
directamente al conductor y que la aplicación solo deja constancia de él, sin
procesar transacciones.

### Figura 7. Zonas de trabajo del conductor

La Figura 7 corresponde a la historia de usuario HU-005. El conductor elige los
sectores donde recoge estudiantes de dos maneras sincronizadas: tocando los
polígonos en el mapa o marcándolos en la lista de selección múltiple. Las
zonas elegidas se resaltan en ambos lugares, y el pie de la pantalla indica
cuántas van seleccionadas antes de guardar. Con esta selección, el sistema
vincula al conductor con los estudiantes que viven en esas zonas.

### Figura 8. Creación de un turno

La Figura 8 presenta el formulario de la historia de usuario HU-006. El
conductor define el bloque horario (mañana, tarde o noche), las horas de ida y
de regreso, el sentido del servicio (ida, regreso o ambos), los días de
operación, la cantidad de cupos y la tarifa con su modalidad de cobro. El
selector de cupos indica la capacidad del vehículo registrado e impide
ofrecer más puestos que los disponibles, conforme a la validación de la
historia.

### Figura 9. Evaluación de una solicitud de cupo

La Figura 9 atiende la historia de usuario HU-009. El mapa ubica el domicilio
de la solicitante respecto a las zonas del conductor y a las paradas de su
recorrido, lo que le permite valorar el desvío antes de comprometer un puesto.
Debajo, se muestra el perfil de la estudiante (foto, cédula y teléfono), los
días que solicita, la confirmación de que su casa está dentro de las zonas del
conductor y los cupos que quedarían libres, con los botones «Aceptar» y
«Rechazar».

### Figura 10. Pantalla «Hoy» del conductor

La Figura 10 integra las historias de usuario HU-010 y HU-011 en la vista
operativa del conductor. El mapa traza el recorrido del turno con las paradas
numeradas en orden de recogida; la parada del pasajero que notificó su
inasistencia aparece inactiva. La hoja inferior presenta la nómina del día,
ordenada por parada, con el estado de cada pasajero (va, por confirmar o no
va), y el botón «Iniciar recorrido», que activa la transmisión de la ubicación
de la unidad hacia los estudiantes del turno.

### Figura 11. Aviso de contingencia

La Figura 11 corresponde a la historia de usuario HU-015. En un solo paso, el
conductor elige el motivo de la contingencia (avería, combustible, vía cerrada
u otro), indica si continuará con una demora estimada o si cancela el
recorrido del día, y agrega un detalle opcional. El aviso llega a todos los
estudiantes que viajan ese día, sin que el conductor deba contactarlos uno por
uno.

### Figura 12. Registro de pagos

La Figura 12 muestra la contraparte del conductor en la historia de usuario
HU-013. El conductor selecciona al estudiante, indica el monto, el método de
pago (dólares en efectivo, Pago Móvil, Zelle o bolívares en efectivo) y el
período que cubre. Los períodos ya pagados aparecen deshabilitados, lo que
evita registrar dos veces el mismo pago, y el registro actualiza el estado de
cuenta que consulta el estudiante.

### Figura 13. Revisión del expediente de un conductor

La Figura 13 corresponde a la historia de usuario HU-012. El administrador
revisa el expediente de un conductor en estado pendiente: sus datos de
identificación, la vigencia de la licencia de conducir y del certificado
médico, y los datos y fotografías del vehículo. Desde la misma pantalla puede
aprobar la cuenta o rechazarla; en este último caso, el motivo es
obligatorio, para que el conductor sepa qué recaudo debe subsanar.

## Notas para el equipo

- **Regenerar un PNG** después de editar el HTML: el archivo acepta
  `?pantalla=NN` y deja una sola figura sobre fondo blanco. Desde PowerShell:

  ```powershell
  & "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --headless `
    --hide-scrollbars --force-device-scale-factor=2 --window-size=412,832 `
    --virtual-time-budget=8000 --screenshot="$PWD\02-resultados-busqueda.png" `
    "file:///C:/Users/raool/develop/urbe/tesis/docs/tesis/fase-2/prototipos.html?pantalla=02"
  ```

  La Figura 1 (dos teléfonos) usa `--window-size=816,864`. Hace falta
  conexión para que carguen las fuentes de Google Fonts.
- Los prototipos no muestran calificaciones de conductores ni tiempo estimado
  de llegada calculado por calles, porque el Cuadro 18 los deja fuera del
  alcance. La distancia que aparece en las Figuras 5 y 9 es en línea recta.
