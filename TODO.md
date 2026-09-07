Fase 0 — Decisiones abiertas

Ninguna de estas es programable, pero todas cambian el modelo. Ciérralas primero.

 Resolver el conflicto del pre-test/post-test con el equipo y el tutor
 Decidir Google Maps SDK o OSM (flutter_map + OSRM). Afecta costos y arquitectura
 Decidir si se admiten carros por puesto de 4 asientos o solo unidades de transporte
 Confirmar con transportistas si un mismo puesto se comparte entre dos personas de días alternos
 Cerrar el estado "reservado" y su plazo de vencimiento
Fase 1 — Campo (Objetivos 1 y 2)
 Redactar el guion de entrevista semiestructurada para transportistas
 Redactar el cuestionario espejo para estudiantes
 Validar ambos instrumentos con el tutor
 Aplicar a 4–6 transportistas y a la muestra de estudiantes
 Tabular y analizar resultados
 Derivar la lista definitiva de requerimientos de esos resultados

Esto va primero por una razón formal: si diseñas la base de datos antes de aplicar los instrumentos, los requerimientos quedan justificados al revés y se nota.

Fase 2 — Prototipos de riesgo (en paralelo con la Fase 3)
 Crear el proyecto Flutter y conectar Firebase (flutterfire configure)
 Spike 1: rastreo de ubicación con la app minimizada y la pantalla apagada
 Spike 2: consulta por radio con geohash en Firestore
 Spike 3: punto en polígono y distancia punto-polilínea, con pruebas unitarias
 Documentar qué funcionó y qué obligó a cambiar el diseño

El Spike 1 es el que puede tumbar tu arquitectura. Hazlo esta semana.

Fase 3 — Diseño lógico y físico (Objetivo 3)

Antes de los diagramas

 Escribir las consultas que la app necesita, en lenguaje natural ("dado un domicilio, un turno y unos días, devolver los turnos con cupo libre")

Diagramas

 Diagrama de casos de uso con los tres actores
 Narrativa de cada caso de uso (precondiciones, flujo principal, alternativos)
 Diagrama de clases
 Diagramas de secuencia de los tres flujos críticos: inscripción, confirmación semanal y viaje en curso
 Diagrama de actividades del filtrado geográfico en cadena
 Diagrama de arquitectura cliente-servidor
 Diagrama de despliegue

Modelo de datos

 Definir colecciones y subcolecciones de Firestore
 Definir qué va en Realtime Database (solo posiciones en vivo) y qué en Firestore
 Decidir la desnormalización necesaria para la tarjeta de resultados
 Definir el campo geohash y los índices compuestos requeridos
 Redactar las reglas de seguridad
 Diccionario de datos con tipos y descripciones
Fase 4 — Diseño de interfaz
 Sistema de diseño en Figma: tipografía, paleta de marca, colores de estado del cupo
 Pantallas críticas primero: "Mi semana" y "Hoy"
 Flujo de onboarding y búsqueda
 Pantallas faltantes del mockup: solicitud enviada y turno lleno con lista de espera
Fase 5 — Construcción por iteraciones

Cada iteración cierra con algo funcionando y probado, como manda XP:

 Iteración 1 — autenticación, registros y aprobación del administrador
 Iteración 2 — rutas, turnos y zonas de cobertura
 Iteración 3 — búsqueda geográfica completa
 Iteración 4 — inscripción, confirmación semanal y nómina diaria
 Iteración 5 — viaje en vivo y notificaciones
 Iteración 6 — cuentas y lista de espera
Fase 6 — Verificación (Objetivo 4)
 Construir el instrumento de evaluación por juicio de expertos según ISO/IEC 25010
 Aplicarlo con tres especialistas
 Pruebas de usabilidad con estudiantes y choferes reales
 Manual de usuario por rol (Objetivo 5)