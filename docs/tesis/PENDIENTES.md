# PENDIENTES

Lista de trabajo de errores, inconsistencias y dudas detectadas en el material
de la tesis.

**Nada de esto se corrige en las copias de lectura** de `docs/tesis/`: esas
copias deben reflejar exactamente lo entregado. Las correcciones van al `.docx`
original, y de ahí se regenera el `.md`.

- Última revisión: **2026-09-07**
- Pendientes: **31** · Resueltos: **0**
- Por prioridad: **P0** 7 · **P1** 12 · **P2** 7 · **P3** 5

Convención: `- [ ]` pendiente · `- [x]` resuelto · `P0` bloqueante ·
`P1` alta · `P2` media · `P3` baja.

---

## P0 · Bloqueantes — impiden generar las copias de lectura

Ninguna copia de lectura se pudo generar. El repositorio está vacío: no hay
`CLAUDE.md` ni carpeta `/originales`, y no hay ningún `.docx`/`.pdf` de la tesis
dentro del proyecto. El material localizado está en `~/Downloads` y no sirve
como fuente de verdad tal como está.

- [ ] **P0.1 — Confirmar el tema y título real de la tesis.**
      El material encontrado pertenece a tres investigaciones distintas
      (ver [Anexo A](#anexo-a--inventario-de-archivos-encontrados)). Sin esto no
      se puede decidir qué archivo convertir.

- [ ] **P0.2 — Crear `/originales` y colocar ahí solo los archivos propios
      entregados a la universidad.**
      No se copió nada automáticamente: decidir qué archivo es "lo entregado" es
      una decisión de autoría, más aún habiendo dos tesis ajenas mezcladas.

- [ ] **P0.3 — Conseguir el original del Capítulo I (El Problema).**
      No existe **ningún** archivo del Capítulo I en el equipo, en ningún
      formato ni carpeta. `capitulo-1-el-problema.md` no se puede generar.

- [ ] **P0.4 — Conseguir el original del Capítulo II (Marco Teórico).**
      Igual que el anterior: no existe. `capitulo-2-marco-teorico.md` no se
      puede generar.

- [ ] **P0.5 — Indicar, por capítulo, cuál archivo es la versión entregada y con
      qué fecha.**
      Necesario para llenar `archivo_origen` y `fecha_version` del frontmatter.
      Un `archivo_origen` inventado vuelve la copia inútil como referencia.

- [ ] **P0.6 — Revisar a mano `Capítulo-III_V5_FINAL.doc`.**
      1,5 MB, formato binario Word antiguo; **no se pudo extraer su texto**. Por
      el nombre (`V5_FINAL`) podría ser la versión vigente del capítulo.
      Abrirlo en Word y, si es la buena, reguardarlo como `.docx`.

- [ ] **P0.7 — Descargar `REPÚBLICA BOLIVARIANA DE VENEZUELA.docx` de OneDrive.**
      En `~/OneDrive/Dokumente/`. Solo está el marcador en la nube, no el
      archivo, por lo que no se pudo abrir. El nombre sugiere que son la portada
      o las páginas preliminares.

---

## P1 · Integridad de citas — revisar antes de cualquier entrega

- [ ] **P1.1 — Párrafos idénticos a otra tesis. Lo más urgente de la lista.**
      Se detectaron **4 oraciones textualmente idénticas** entre
      `~/Downloads/Capitulo 3.docx` y la tesis de Alzheimer de Chirino, Nava y
      Suárez (2023), una de ellas un bloque de 548 caracteres:
    - [ ] El párrafo completo de **Dudovskiy (2022)** sobre los tres propósitos
          del estudio descriptivo ("describir, explicar y validar...").
    - [ ] `"Este tipo de investigación es popular con temas no cuantificados,
          siendo utilizada para describir varios aspectos del fenómeno."`
    - [ ] `"Este tipo de investigación se utiliza para describir las
          características y/o el comportamiento de la muestra de población..."`
    - [ ] `"A raíz de esta afirmación, puede inferirse que este tipo de
          investigación persigue el fin de brindar solución a una problemática a
          través de la ejecución de un plan dado."`

- [ ] **P1.2 — Reescribir el primer párrafo del Capítulo III: es un empalme de
      las dos tesis ajenas.**
      La oración de apertura ("Para poder seleccionar el tipo de investigación
      correctamente, se debe analizar a fondo el problema a solucionar") es la
      apertura del capítulo de **palma aceitera**; la que le sigue, de **Tamayo
      y Tamayo (2009)**, aparece igual en el de **Alzheimer**.

- [ ] **P1.3 — Verificar `Dudovskiy (2022)`.**
      Citado sin página. Es un sitio web (Business Research Methodology).
      Confirmar si se admite como fuente en las normas de la universidad.

- [ ] **P1.4 — Verificar `Sarango, Pallmay, Sarzosa y Pozo (2024, p. 7)`.**
      Cuatro autores, año muy reciente. Comprobar que exista y que diga lo que
      se le atribuye: afirma que en la investigación proyectiva "los datos se
      recopilan en tiempo real", lo cual **no** es lo que sostiene Hurtado de
      Barrera. Ver también P2.5.

- [ ] **P1.5 — Verificar `Tamayo y Tamayo (2009)`.** Citado sin página.

- [ ] **P1.6 — Resolver la edición de Arias: `(2016, p. 24)` vs `(2012, p. 31)`.**
      La definición de investigación descriptiva ("la caracterización de un
      hecho, fenómeno, individuo o grupo...") se cita como **Arias (2016, p. 24)**
      en `Capitulo 3.docx`, pero como **Arias (2012, p. 31)** en
      `Diseno_de_la_investigacion.docx`. El PDF disponible es el de **2012** y no
      hay edición 2016 entre el material. Unificar a una sola edición y verificar
      la página.

- [ ] **P1.7 — Corregir el apellido truncado `"Barrera (2010, p.567)"`.**
      El apellido de la autora es **Hurtado de Barrera** (Jacqueline Hurtado de
      Barrera). Así truncado es difícil de ubicar en la bibliografía y
      probablemente sea observado en la revisión. Verificar además edición y
      página.

### Verificables ya, con los PDF que están en `~/Downloads/tesis/`

- [ ] **P1.8 — Confirmar que el PDF de Sampieri sea la 6.ª edición (2014).**
      Hacerlo **antes** de P1.9 y P1.10: la paginación cambia entre ediciones y
      de eso dependen las páginas citadas.
- [ ] **P1.9 — `Hernández, Fernández y Baptista (2014, p. 152)`** — diseño no
      experimental, contra `Metodologia_de_la_Investigacion_Sampieri.pdf`.
- [ ] **P1.10 — `Hernández, Fernández y Baptista (2014, p. 154)`** — diseño
      transversal, mismo PDF.
- [ ] **P1.11 — `Arias (2012, p. 31)`** — investigación de campo, contra
      `El-proyecto-de-investigación-F.G.-Arias-2012-pdf-1.pdf`.
- [ ] **P1.12 — `Bernal (2010, p. 118)`** — seccionales o transversales, contra
      `El-proyecto-de-investigación-bernal-pdf.pdf`.

---

## P2 · Consistencia y completitud del Capítulo III

- [ ] **P2.1 — Redactar los apartados faltantes.**
      `Capitulo 3.docx` pasa de "Tipo y diseño de la investigación" directamente
      a "Metodología seleccionada". Falta:
    - [ ] Población / población objeto de estudio, con su **Cuadro 1**
    - [ ] Técnicas e instrumentos de recolección de datos
    - [ ] Recursos

      El capítulo está incompleto **respecto a lo que él mismo anuncia**: su
      introducción declara que "se indican las técnicas e instrumentos de
      recolección de datos utilizados... y los recursos". Los dos archivos
      ajenos sí traen estos apartados.

- [ ] **P2.2 — Fundir los dos `Diseno_de_la_investigacion`: ninguno está
      completo.**

      | | `Diseno_de_la_investigacion.docx` | `Diseno_de_la_investigacion (1).docx` |
      |---|---|---|
      | Fecha | 30/08 14:51 | 30/08 14:58 (más reciente) |
      | Encabezado `DISEÑO DE LA INVESTIGACIÓN` | sí | **no, se perdió** |
      | Párrafo introductorio | sí | **no, se perdió** |
      | Citas textuales | parafraseadas | entrecomilladas |

      La versión más reciente mejoró el manejo de las citas textuales pero perdió
      el encabezado del apartado y su párrafo introductorio.

- [ ] **P2.3 — Decidir si `Powell (2001)` corresponde en la metodología.**
      `Capitulo 3.docx` declara una metodología híbrida de **Beck (1999)** +
      **Kendall y Kendall (2011)** (Fases I–IV a Beck, Fase V a Kendall). El
      archivo de palma aceitera declara la misma estructura de 5 fases pero
      sustentada en **Beck (1999), Powell (2001) y Kendall y Kendall (2011)**.

- [ ] **P2.4 — Cotejar los objetivos específicos con el Capítulo I cuando
      exista.**
      Hoy los cinco objetivos específicos aparecen **únicamente** en el cuadro de
      actividades del Capítulo III, mapeados a las fases. Es contra esa lista que
      habrá que verificar el Capítulo I — y es también el contrato de alcance del
      software.

- [ ] **P2.5 — Unificar la definición de "investigación proyectiva", hoy
      incompatible consigo misma.**
      En el mismo documento se define vía **Barrera (2010)** como "elaboración de
      una propuesta, un plan o procedimiento", y vía **Sarango et al. (2024)**
      como que "los datos se recopilan en tiempo real". Lo segundo no es lo que
      sostiene Hurtado de Barrera.

- [ ] **P2.6 — Reformular la equivalencia "campo = no experimental".**
      `Diseno_de_la_investigacion.docx` atribuye a Arias (2012, p. 31) que el
      autor "deriva de esta característica el carácter no experimental de este
      tipo de estudio, lo que evidencia la correspondencia directa entre el
      diseño de campo y el diseño no experimental". Esa equivalencia es
      interpretación de los autores de la tesis, no afirmación de Arias: él
      clasifica diseño de campo frente a documental y experimental como
      dimensiones distintas. Reformular para no atribuirle una conclusión que no
      hace.

- [ ] **P2.7 — Renombrar `tesis/CAPITULOIII - Corregido.docx`: el nombre miente.**
      No es una versión corregida; es un duplicado byte a byte de
      `CAPITULOIII.docx` (mismo MD5 `c76a71b5...`). El único archivo que
      realmente difiere y se llama "Corregido" está en `~/Downloads/Telegram
      Desktop/`, y ese es la tesis de Alzheimer.

---

## P3 · Tipeo y acentuación

En `Capitulo 3.docx`. **No corregir en el `.md`** — corregir en el original y
regenerar.

- [ ] **P3.1** — `"Tipo y diseño de la investigacion"` (encabezado): falta tilde
      en "investigación".
- [ ] **P3.2** — `"...problema a solucionar.Sobre esto, Tamayo..."`: falta el
      espacio después del punto.
- [ ] **P3.3** — `"la investigacion a realizar se considera proyectiva debido a
      que plantea el desarrollo de una aplicacion movil"`: párrafo entero sin
      tildes (investigación, aplicación, móvil, propósito, transportista).
- [ ] **P3.4** — `"para asi poder especificar"`: falta tilde en "así".
- [ ] **P3.5** — `"Funcionabilidad extra"` (cuadro de actividades, Fase II):
      probablemente debe ser "Funcionalidad extra".

---

## Anexo A · Inventario de archivos encontrados

Los archivos del Capítulo III **no son versiones de un mismo capítulo**: son de
tres investigaciones con temas, autores y años diferentes. Solo los tres
primeros tratan el tema de transporte universitario; los otros dos son de otros
autores y presumiblemente se usaron como modelo.

| Archivo | Tema | Autores en el cuadro de población |
|---|---|---|
| `~/Downloads/Capitulo 3.docx` | App móvil de transporte para comunidad universitaria (SIG) | — |
| `~/Downloads/Diseno_de_la_investigacion.docx` | App móvil de transporte universitario | — |
| `~/Downloads/Diseno_de_la_investigacion (1).docx` | App móvil de transporte universitario | — |
| `~/Downloads/tesis/CAPITULOIII.docx` | App móvil de detección de plagas en palma aceitera | Fuenmayor, Niebles y Zabala (2024) |
| `~/Downloads/Telegram Desktop/CAPITULOIII - Corregido.docx` | Dispositivo de monitoreo para pacientes de Alzheimer | Chirino, Nava y Suárez (2023) |
| `~/Downloads/tesis/Capítulo-III_V5_FINAL.doc` | **no se pudo leer** (ver P0.6) | — |
| `~/OneDrive/Dokumente/REPÚBLICA BOLIVARIANA DE VENEZUELA.docx` | **no se pudo leer** (ver P0.7) | — |

### Los PDF no son capítulos

Son bibliografía de metodología, no material propio. Útiles para verificar citas
(P1.8–P1.12), no para convertir.

| PDF | Uso |
|---|---|
| `Metodologia_de_la_Investigacion_Sampieri.pdf` | P1.8, P1.9, P1.10 |
| `El-proyecto-de-investigación-F.G.-Arias-2012-pdf-1.pdf` | P1.6, P1.11 |
| `El-proyecto-de-investigación-bernal-pdf.pdf` | P1.12 |
| `Dialnet-TiposYClasificacionDeLasInvestigaciones-9541046.pdf` | consulta general |
