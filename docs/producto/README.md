# docs/producto — documentacion editable

## Que es esta carpeta

A diferencia de [../tesis/](../tesis/), **aqui si se edita**. Esta carpeta
contiene la documentacion viva del producto: la que evoluciona mientras se
construye el software.

La distincion importa:

| | `docs/tesis/` | `docs/producto/` |
|---|---|---|
| Origen | generado desde `/originales` | escrito a mano |
| Se edita | no | si |
| Que representa | lo que se entrego a la universidad | lo que estamos construyendo |
| Al cambiar | se regenera completo | se versiona en git como cualquier fuente |

## Que va aqui

- **Especificacion funcional** (`especificacion-funcional.md`) — que hace la
  aplicacion, pantalla por pantalla y caso por caso. Es la traduccion de los
  objetivos especificos del Capitulo I a requerimientos implementables.
- **Hallazgos de campo** (`hallazgos-de-campo.md`) — resultado de las
  entrevistas y observacion: lo que realmente dijeron y hacen los informantes.
  Es la materia prima de los requerimientos y lo que respalda las decisiones de
  diseno cuando alguien pregunta "por que asi".
- **Modelo de datos** (`modelo-de-datos.md`) — entidades, atributos, relaciones
  y decisiones de persistencia.

Se pueden agregar otros documentos (decisiones de arquitectura, plan de pruebas,
manual de usuario) a medida que hagan falta.

## Relacion con la tesis

Los objetivos especificos del Capitulo I son **el contrato de alcance** del
software. Cuando un documento de esta carpeta desarrolle o acote uno de esos
objetivos, conviene citarlo por su numeracion original, por ejemplo:

> Cubre el objetivo especifico 3 (ver `docs/tesis/capitulo-1-el-problema.md`,
> apartado de objetivos especificos).

Asi queda rastreable que cada pieza construida responde a algo comprometido en
la tesis, y se detecta cuando el software se esta saliendo del alcance
declarado.

## Estado

Carpeta creada y vacia de contenido. Los tres documentos base todavia no se han
escrito; conviene empezar por los hallazgos de campo, que son los que alimentan
a los otros dos.
