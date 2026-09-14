# Bloque 6 · Geo

Prefijo de ID: `GEO`. Niveles: 1 básico · 2 intermedio · 3 avanzado.

Este bloque es el Spike 3 y es Dart puro: se puede estudiar y probar sin tocar
la interfaz.

---

### GEO-01 · nivel 1 · Haversine
¿Qué calcula la fórmula de Haversine?
- A) La distancia sobre la superficie de la esfera entre dos pares de latitud y longitud.
- B) La distancia en línea recta atravesando el interior de la Tierra.
- C) La distancia recorrida por carretera entre dos puntos.
- D) El rumbo, es decir el ángulo de un punto respecto a otro.

**Correcta:** A · **Por qué:** distancia de círculo máximo. Para las escalas de Cupo —centenares de metros— el error de tratar la Tierra como esfera es despreciable. · **Recurso:** https://www.movable-type.co.uk/scripts/latlong.html

### GEO-02 · nivel 2 · qué es un geohash
¿Qué propiedad del geohash lo hace útil en Firestore?
- A) Que dos puntos cercanos comparten prefijo, así que una consulta por rango de cadenas ordenadas aproxima una consulta por área.
- B) Que codifica la distancia exacta en metros dentro de la cadena.
- C) Que es reversible sin pérdida y devuelve la coordenada original exacta.
- D) Que Firestore lo indexa con un índice espacial dedicado.

**Correcta:** A · **Por qué:** el geohash convierte dos dimensiones en una cadena ordenable, y así una base de datos que solo sabe hacer rangos puede responder por proximidad. Es una codificación con pérdida: cada hash es una celda, no un punto. · **Recurso:** https://firebase.google.com/docs/firestore/solutions/geoqueries

### GEO-03 · nivel 3 · las celdas vecinas
¿Por qué una geoconsulta con geohash pide varios rangos y no solo la celda del punto central?
- A) Porque el punto puede caer junto al borde de su celda: hay que consultar también las vecinas para no perder resultados que están cerca pero al otro lado del borde.
- B) Porque cada celda admite un número limitado de documentos.
- C) Porque el geohash del centro cambia cada vez que se recalcula.
- D) Porque Firestore exige un mínimo de tres rangos por consulta.

**Correcta:** A · **Por qué:** dos puntos separados por un metro pueden tener prefijos completamente distintos si el borde de la celda pasa entre ellos. De ahí las 9 celdas: la propia y sus 8 vecinas. · **Recurso:** https://firebase.google.com/docs/firestore/solutions/geoqueries

### GEO-04 · nivel 3 · falsos positivos
Después de traer los documentos por rango de geohash, ¿qué falta?
- A) Filtrar por distancia real, porque el conjunto de celdas cubre un área mayor que el círculo pedido y devuelve puntos de más.
- B) Nada: el rango devuelve exactamente los puntos dentro del radio.
- C) Volver a consultar con un radio menor hasta que el número cuadre.
- D) Ordenar por geohash, que equivale a ordenar por distancia.

**Correcta:** A · **Por qué:** el geohash es un pre-filtro barato, nunca la respuesta final. Y ojo con la D: cadenas próximas no implican puntos próximos. · **Recurso:** https://firebase.google.com/docs/firestore/solutions/geoqueries

### GEO-05 · nivel 2 · punto en polígono
El algoritmo de ray casting decide que el punto está dentro del polígono cuando…
- A) …una semirrecta trazada desde el punto cruza los lados del polígono un número impar de veces.
- B) …el punto está a menos distancia del centro que el vértice más lejano.
- C) …la suma de las distancias a todos los vértices es mínima.
- D) …el punto cae dentro del rectángulo que encierra al polígono.

**Correcta:** A · **Por qué:** cada cruce cambia de dentro a fuera. Funciona con polígonos cóncavos, que es justo lo que serán las zonas de cobertura reales. La D es la caja envolvente: un pre-filtro útil, no la respuesta. · **Recurso:** https://wrfranklin.org/Research/Short_Notes/pnpoly.html

### GEO-06 · nivel 3 · distancia a una polilínea
¿Cómo se calcula la distancia de un domicilio a una ruta representada como polilínea?
- A) Como el mínimo, entre todos los segmentos, de la distancia del punto a cada segmento: se proyecta el punto sobre el segmento y se limita la proyección a sus extremos.
- B) Como la distancia al vértice más cercano de la polilínea.
- C) Como la distancia al punto medio de la polilínea.
- D) Como la distancia a la recta infinita que pasa por el primer y el último punto.

**Correcta:** A · **Por qué:** limitar la proyección (el *clamp*) es la parte que se olvida: sin ella, un punto que queda "más allá" del final del segmento devuelve una distancia menor que la real. La B falla cuando el punto está a mitad de un tramo largo y recto. · **Recurso:** https://www.movable-type.co.uk/scripts/latlong.html

### GEO-07 · nivel 2 · grados y metros
¿Por qué no sirve un umbral fijo en grados para decir "a menos de 500 metros"?
- A) Porque un grado de longitud mide menos cuanto más lejos del ecuador —se multiplica por el coseno de la latitud— mientras que uno de latitud se mantiene en torno a 111 km.
- B) Porque los grados no admiten decimales suficientes para expresar 500 metros.
- C) Porque la latitud y la longitud usan escalas distintas en cada país.
- D) Porque el GPS devuelve grados con precisión de kilómetro.

**Correcta:** A · **Por qué:** en Maracaibo, a unos 10° de latitud, el coseno vale ~0,985 y el error es pequeño, pero la fórmula debe llevarlo igual: es lo que hace correcto el código, no la latitud concreta donde se probó. · **Recurso:** https://www.movable-type.co.uk/scripts/latlong.html

### GEO-08 · nivel 3 · el filtrado en cadena
En el filtrado geográfico en cadena de Cupo, ¿qué orden tiene sentido?
- A) Primero lo barato y grosero —rango de geohash y filtros de turno y días en la propia consulta— y después lo caro y exacto —punto en polígono y distancia a la polilínea— sobre los pocos candidatos que quedan.
- B) Primero el cálculo exacto sobre toda la colección y después el descarte por geohash.
- C) Es indiferente: el resultado y el coste son los mismos en cualquier orden.
- D) Primero punto en polígono, porque descarta más que cualquier otro filtro.

**Correcta:** A · **Por qué:** cada documento que llega al cliente es una lectura facturada y un cálculo. El orden del filtrado es la decisión de diseño que sostiene la investigación. · **Recurso:** https://firebase.google.com/docs/firestore/solutions/geoqueries

### GEO-09 · nivel 1 · lat/lng
En `LatLng(10.6666, -71.6124)`, ¿qué es cada número?
- A) Primero la latitud (norte-sur, de −90 a 90) y después la longitud (este-oeste, de −180 a 180); el signo negativo indica oeste.
- B) Primero la longitud y después la latitud, como en GeoJSON.
- C) Primero la coordenada X y después la Y en metros desde el origen del mapa.
- D) El orden es indistinto: las librerías lo detectan por el rango del valor.

**Correcta:** A · **Por qué:** casi todo en Flutter usa (lat, lng), pero GeoJSON usa (lng, lat) — invertirlas es el bug clásico, y se manifiesta como puntos en mitad del océano. · **Recurso:** https://docs.fleaflet.dev

### GEO-10 · nivel 2 · precisión del geohash
¿Qué pasa al aumentar la longitud del geohash, por ejemplo de 5 a 7 caracteres?
- A) La celda se hace más pequeña y la consulta más precisa, pero hay que cubrir más celdas para el mismo radio.
- B) La precisión no cambia: solo se alarga la cadena.
- C) La celda crece, porque cada carácter añade área.
- D) Deja de poder compararse con geohashes de otra longitud.

**Correcta:** A · **Por qué:** cada carácter subdivide la celda. Elegir la precisión es equilibrar falsos positivos contra número de consultas: se escoge la que mejor se ajuste al radio de búsqueda. · **Recurso:** https://firebase.google.com/docs/firestore/solutions/geoqueries
