-- 20260924000002 · Tablas
-- Corresponde al apartado 8.2 de docs/producto/modelo-de-datos.md
--
-- Cambio respecto del documento: se agrega usuarios.motivo_rechazo. La tabla
-- de enrutamiento (apartado 6) manda al usuario rechazado a una pantalla que
-- muestra el motivo, y no había dónde guardarlo.

create table public.usuarios (
  id                  uuid primary key
                        references auth.users (id) on delete cascade,
  email               text not null unique,
  telefono            text unique,
  nombres             text not null default '',
  apellidos           text not null default '',
  cedula              text unique,
  rol                 rol_usuario   not null,
  estado              estado_cuenta not null default 'perfil_incompleto',
  url_foto            text,
  motivo_rechazo      text,
  onboarding_completo boolean     not null default false,
  creado_en           timestamptz not null default now(),
  ultimo_acceso       timestamptz
);

comment on column public.usuarios.motivo_rechazo is
  'Lo escribe el administrador al rechazar. Se limpia al reenviar a revisión.';

create table public.zonas (
  id        uuid primary key default gen_random_uuid(),
  nombre    text not null,
  municipio text,
  poligono  geography(Polygon, 4326) not null,
  activa    boolean     not null default true,
  creada_en timestamptz not null default now(),
  unique (nombre, municipio)
);

-- Sin este índice, detectar la zona de un domicilio recorre todos los
-- polígonos. Con veinte zonas no se nota; con doscientas, sí.
create index zonas_poligono_idx on public.zonas using gist (poligono);

create table public.estudiantes (
  id                   uuid primary key
                         references public.usuarios (id) on delete cascade,
  universidad          text,
  carrera              text,
  carnet               text,
  domicilio            geography(Point, 4326),
  domicilio_direccion  text,
  domicilio_referencia text,
  -- Nullable a propósito: el pin puede caer fuera de toda zona y aun así la
  -- cuenta se completa (apartado 3.4 del modelo).
  zona_id              uuid references public.zonas (id) on delete set null,
  domicilio_fijado_en  timestamptz
);

create index estudiantes_domicilio_idx
  on public.estudiantes using gist (domicilio);
create index estudiantes_zona_idx on public.estudiantes (zona_id);

create table public.conductores (
  id                   uuid primary key
                         references public.usuarios (id) on delete cascade,
  licencia_numero      text,
  licencia_vence_en    date,
  certificado_medico   text,
  certificado_vence_en date,
  verificado           boolean not null default false
);

-- Resuelve el N:M entre conductores y zonas. La clave primaria compuesta
-- impide por sí sola que un conductor registre dos veces la misma zona.
create table public.conductor_zonas (
  conductor_id uuid not null
                 references public.conductores (id) on delete cascade,
  zona_id      uuid not null
                 references public.zonas (id) on delete cascade,
  agregada_en  timestamptz not null default now(),
  primary key (conductor_id, zona_id)
);

create index conductor_zonas_zona_idx on public.conductor_zonas (zona_id);
