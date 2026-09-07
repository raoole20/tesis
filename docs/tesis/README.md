# docs/tesis — copias de lectura

## Que es esta carpeta

Aqui viven **copias de lectura en markdown** de los capitulos de la tesis,
generadas a partir de los archivos entregados a la universidad que estan en
`/originales` (`.docx` / `.pdf`).

Sirven para consultar y citar el contenido de la tesis desde el codigo y desde
el resto de la documentacion, sin abrir Word.

## Reglas

1. **`/originales` es la fuente de verdad.** Los `.docx` y `.pdf` de esa carpeta
   son de solo lectura. No se editan, no se renombran, no se mueven.

2. **Los `.md` de esta carpeta NO se editan a mano.** Son material derivado.
   Cualquier cambio hecho aqui se pierde en la siguiente regeneracion y, peor,
   hace que el `.md` deje de reflejar lo que se entrego.

3. **Se regeneran cuando se entrega una version nueva de un capitulo.** El flujo
   es: se entrega el capitulo -> el `.docx` nuevo entra a `/originales` ->
   se regenera el `.md` correspondiente -> se actualiza `fecha_version` y
   `estado` en el frontmatter.

4. **La conversion es literal.** No se corrige ortografia, redaccion, numeracion
   ni citas, aunque esten mal. El `.md` debe reflejar exactamente lo entregado.
   Todo error detectado se anota en [PENDIENTES.md](PENDIENTES.md) en lugar de
   corregirse aqui.

5. **Se conserva la numeracion original** de los apartados (`1.`, `2.1.`,
   `2.1.1.`), porque la usamos para citar internamente.

## Archivos esperados

| Archivo | Capitulo | Estado |
|---|---|---|
| `capitulo-1-el-problema.md` | I — El Problema | **no generado** — falta el original |
| `capitulo-2-marco-teorico.md` | II — Marco Teorico | **no generado** — falta el original |
| `capitulo-3-marco-metodologico.md` | III — Marco Metodologico | **no generado** — original sin confirmar |

> **Ninguna copia de lectura existe todavia.** La carpeta `/originales` no esta
> presente en el repositorio, de modo que no hay de donde generarlas. El detalle
> de que falta y que hay que decidir esta en [PENDIENTES.md](PENDIENTES.md).

## Frontmatter

Cada capitulo generado abre con:

```yaml
---
capitulo: <numero y nombre, p. ej. "III — Marco Metodologico">
fecha_version: <YYYY-MM-DD de la version entregada>
estado: entregado | en revision | borrador
archivo_origen: originales/<nombre exacto del archivo>.docx
---
```

`archivo_origen` apunta al archivo concreto de `/originales` del que salio la
copia. Si no se puede identificar con certeza cual fue el archivo entregado, la
copia no se genera: un `archivo_origen` inventado vuelve el documento inutil
como referencia.

## Donde van los documentos editables

En [../producto/](../producto/). Esta carpeta es solo para material derivado de
la tesis ya entregada.
