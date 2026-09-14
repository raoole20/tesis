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

| Documento | Estado |
|---|---|
| `hallazgos-de-campo.md` | no escrito — depende de la Fase 1 |
| `especificacion-funcional.md` | no escrito |
| [`modelo-de-datos.md`](modelo-de-datos.md) | **borrador parcial** — identidad y ubicacion (usuario, estudiante, conductor, zonas), sobre Supabase |

El orden natural seria empezar por los hallazgos de campo, que alimentan a los
otros dos. Del modelo de datos se adelanto unicamente la parte de identidad,
que es la que hace falta para diagramar el login y la Iteracion 1. Las
entidades de la operacion se agregan cuando cierren la Fase 0 y el campo.

**Atencion:** ese documento ya esta escrito sobre **Supabase (PostgreSQL)**,
mientras que `../../README.md`, `../../cupo/README.md`, `../../TODO.md` y
`cupo/pubspec.yaml` todavia describen Firebase. El apartado 10 del modelo
lista que cambia en cada uno.
