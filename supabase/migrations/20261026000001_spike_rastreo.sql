-- 20261026000001 · SPIKE: rastreo del conductor en segundo plano (HU-011)
--
-- ⚠️ Tabla de spike, desechable. Responde una sola pregunta: ¿la app del
-- conductor sigue mandando su ubicación a Supabase con la app minimizada y
-- con la pantalla apagada? La llena la pantalla «Prueba de rastreo» (solo en
-- modo debug, cupo/lib/features/spike_rastreo/) y se lee con
-- spike_reporte(). El diseño de la medición y el protocolo están en
-- docs/producto/spike-rastreo.md.
--
-- No es el modelo de la ubicación en vivo de HU-011: esa tabla se diseña
-- cuando existan los viajes. Aquí cada fila repite la configuración de su
-- sesión (inicio, duración de fase, intervalo, wake lock, permiso, teléfono)
-- para no necesitar una segunda tabla.
--
-- Para borrar el spike entero:
--
--   drop view     if exists public.spike_sesiones;
--   drop function if exists public.spike_reporte(uuid, numeric, numeric, numeric);
--   drop table    if exists public.spike_posiciones;

-- spike_posiciones ----------------------------------------------------------

create table public.spike_posiciones (
  id                      bigint generated always as identity primary key,
  conductor_id            uuid not null default auth.uid()
                            references public.usuarios (id) on delete cascade,

  -- La sesión: una corrida del protocolo de tres fases.
  sesion_id               uuid        not null,
  -- Hora del teléfono en que llegó la primera ubicación. Las fases se
  -- cuentan desde aquí, para no castigar el tiempo que tarda el GPS en
  -- engancharse.
  sesion_inicio           timestamptz not null,
  duracion_fase_s         integer     not null check (duracion_fase_s > 0),
  intervalo_s             integer     not null check (intervalo_s > 0),
  wakelock                boolean     not null,
  permiso                 text        not null
                            check (permiso in ('mientras_se_usa', 'siempre')),
  -- null si no se pudo leer (p. ej. fuera de Android).
  bateria_sin_restriccion boolean,
  dispositivo             text,

  -- La muestra.
  -- Contador dentro de la sesión, asignado al capturar. Un hueco en seq es
  -- una muestra que el teléfono capturó y nunca llegó; un hueco de tiempo
  -- sin hueco en seq es una muestra que nunca se capturó.
  seq                     integer     not null check (seq > 0),
  lat                     double precision not null check (lat between -90 and 90),
  lng                     double precision not null check (lng between -180 and 180),
  precision_m             double precision,
  -- Hora del fix según el sistema de ubicación.
  fijada_en               timestamptz,
  -- Hora del teléfono en que la ubicación llegó a la app.
  capturada_en            timestamptz not null,
  -- Hora del teléfono en que salió el intento de envío que la entregó. Con
  -- capturada_en comparte reloj: su diferencia es lo que esperó en la cola.
  enviada_en              timestamptz not null,
  -- Hora del servidor. Otro reloj: restarle capturada_en mezcla latencia y
  -- desfase entre relojes.
  recibida_en             timestamptz not null default now(),
  -- AppLifecycleState de Flutter al capturar.
  estado_app              text        not null
                            check (estado_app in
                              ('resumed', 'inactive', 'paused', 'hidden', 'detached')),
  -- PowerManager.isInteractive al capturar; null si no se pudo leer.
  pantalla_encendida      boolean,
  fase                    text        not null
                            check (fase in
                              ('1_primer_plano', '2_minimizada', '3_pantalla_apagada')),
  intentos                integer     not null default 1 check (intentos > 0),

  -- Un reintento cuya respuesta se perdió no duplica la muestra: la app
  -- inserta con ON CONFLICT DO NOTHING sobre esta clave.
  unique (sesion_id, seq)
);

create index spike_posiciones_conductor_idx
  on public.spike_posiciones (conductor_id, sesion_inicio desc);

alter table public.spike_posiciones enable row level security;

-- (select auth.uid()) y no auth.uid(): así PostgreSQL lo evalúa una vez por
-- consulta y no una vez por fila.
create policy spike_posiciones_inserta_el_conductor on public.spike_posiciones
  for insert to authenticated
  with check (
    conductor_id = (select auth.uid())
    and exists (
      select 1 from public.usuarios u
       where u.id = (select auth.uid()) and u.rol = 'conductor'
    )
  );

create policy spike_posiciones_ve_las_suyas on public.spike_posiciones
  for select to authenticated
  using (conductor_id = (select auth.uid()) or public.es_admin());

-- Sin políticas de update ni delete: una muestra no se corrige.

-- Privilegios por columna (patrón de la migración 06): la app no escribe ni
-- conductor_id, que sale de la sesión, ni recibida_en, que pone el servidor.
revoke all on public.spike_posiciones from anon;
revoke insert, update, delete, truncate on public.spike_posiciones
  from authenticated;
grant insert (
  sesion_id, sesion_inicio, duracion_fase_s, intervalo_s, wakelock, permiso,
  bateria_sin_restriccion, dispositivo,
  seq, lat, lng, precision_m, fijada_en, capturada_en, enviada_en,
  estado_app, pantalla_encendida, fase, intentos
) on public.spike_posiciones to authenticated;

-- spike_sesiones ------------------------------------------------------------
-- Una fila por sesión, para encontrar el sesion_id que se le pasa al
-- reporte. security_invoker: la vista respeta el RLS de quien consulta.

create view public.spike_sesiones
  with (security_invoker = true) as
select sesion_id,
       conductor_id,
       min(sesion_inicio)          as inicio,
       min(duracion_fase_s) / 60.0 as minutos_por_fase,
       min(dispositivo)            as dispositivo,
       min(permiso)                as permiso,
       bool_and(wakelock)          as wakelock,
       bool_and(bateria_sin_restriccion) as bateria_sin_restriccion,
       count(*)                    as muestras,
       max(seq)                    as ultima_seq,
       max(capturada_en)           as ultima_captura
  from public.spike_posiciones
 group by sesion_id, conductor_id;

revoke all on public.spike_sesiones from anon;

-- spike_reporte -------------------------------------------------------------
-- Una fila por fase con lo que decide si la prueba pasa. Corre con los
-- permisos de quien la llama (security invoker): el conductor solo puede
-- reportar sus sesiones y el administrador, todas.
--
-- Ventanas: la fase n va de inicio + (n-1)·duración a inicio + n·duración,
-- en el reloj del teléfono. Mientras la prueba corre, la ventana llega hasta
-- now() y `completa` es false.
--
--   esperadas      duración de la ventana / intervalo
--   cobertura_pct  recibidas / esperadas, tope 100
--   brecha_max_s   mayor silencio entre capturas consecutivas, contando el
--   brecha_p95_s   inicio y el fin de la ventana como bordes (un silencio al
--                  final de la fase también cuenta)
--   perdidas       huecos de seq: capturadas que nunca llegaron
--   tardias        llegaron, pero esperaron en la cola más de p_tardia_s
--                  (enviada_en − capturada_en, mismo reloj)
--   latencia_...   mediana de recibida_en − capturada_en; incluye el
--                  desfase entre el reloj del teléfono y el del servidor
--   estados        cuántas muestras hubo en cada estado de la app
--   cumple         cobertura ≥ p_cobertura_min y brecha máxima ≤ p_brecha_max_s

create or replace function public.spike_reporte(
  p_sesion        uuid,
  p_cobertura_min numeric default 90,
  p_brecha_max_s  numeric default 30,
  p_tardia_s      numeric default 30
)
returns table (
  fase               text,
  completa           boolean,
  duracion_s         integer,
  esperadas          integer,
  recibidas          integer,
  cobertura_pct      numeric,
  brecha_max_s       numeric,
  brecha_p95_s       numeric,
  perdidas           integer,
  tardias            integer,
  latencia_mediana_s numeric,
  estados            text,
  cumple             boolean
)
language sql
stable
set search_path = public
as $$
  with muestras as (
    select m.seq, m.capturada_en, m.enviada_en, m.recibida_en,
           m.estado_app, m.pantalla_encendida,
           m.sesion_inicio, m.duracion_fase_s, m.intervalo_s
      from public.spike_posiciones m
     where m.sesion_id = p_sesion
  ),
  sesion as (
    select min(sesion_inicio)   as inicio,
           min(duracion_fase_s) as duracion,
           min(intervalo_s)     as intervalo
      from muestras
  ),
  ventanas as (
    select f.n, f.nombre, s.intervalo,
           s.inicio + make_interval(secs => (f.n - 1) * s.duracion) as desde,
           s.inicio + make_interval(secs => f.n * s.duracion)       as hasta_plan
      from sesion s
     cross join (values (1, '1_primer_plano'),
                        (2, '2_minimizada'),
                        (3, '3_pantalla_apagada')) as f (n, nombre)
     where s.inicio is not null
  ),
  ventanas_al_dia as (
    select v.n, v.nombre, v.intervalo, v.desde,
           greatest(v.desde, least(v.hasta_plan, now())) as hasta,
           v.hasta_plan <= now()                         as completa
      from ventanas v
  ),
  en_ventana as (
    select v.n, m.seq, m.capturada_en, m.enviada_en, m.recibida_en,
           m.estado_app, m.pantalla_encendida
      from ventanas_al_dia v
      join muestras m
        on m.capturada_en >= v.desde and m.capturada_en < v.hasta
  ),
  puntos as (
    select e.n, e.capturada_en as t from en_ventana e
    union all
    select v.n, v.desde from ventanas_al_dia v
    union all
    select v.n, v.hasta from ventanas_al_dia v
  ),
  brechas as (
    select p.n,
           extract(epoch from p.t - lag(p.t) over (partition by p.n order by p.t))::float8 as s
      from puntos p
  ),
  resumen_brechas as (
    select b.n,
           max(b.s)                                         as maxima,
           percentile_cont(0.95) within group (order by b.s) as p95
      from brechas b
     where b.s is not null
     group by b.n
  ),
  -- Lo que falta en seq se carga a la fase de la muestra que sigue al hueco.
  huecos as (
    select m.capturada_en,
           m.seq - coalesce(lag(m.seq) over (order by m.seq), 0) - 1 as faltan
      from muestras m
  ),
  perdidas as (
    select v.n, sum(h.faltan) as total
      from ventanas_al_dia v
      join huecos h
        on h.capturada_en >= v.desde and h.capturada_en < v.hasta
     where h.faltan > 0
     group by v.n
  ),
  estados as (
    select x.n,
           string_agg(x.clave || ' ' || x.cuantas, ' · ' order by x.cuantas desc) as resumen
      from (
        select e.n,
               e.estado_app
                 || case when e.pantalla_encendida is false
                         then ' (pantalla apagada)' else '' end as clave,
               count(*) as cuantas
          from en_ventana e
         group by 1, 2
      ) x
     group by x.n
  ),
  agregados as (
    select v.n, v.nombre, v.completa, v.intervalo,
           extract(epoch from v.hasta - v.desde)::float8 as segundos,
           count(e.seq) as recibidas,
           count(*) filter (
             where extract(epoch from e.enviada_en - e.capturada_en) > p_tardia_s
           ) as tardias,
           percentile_cont(0.5) within group (
             order by extract(epoch from e.recibida_en - e.capturada_en)::float8
           ) as latencia
      from ventanas_al_dia v
      left join en_ventana e on e.n = v.n
     group by v.n, v.nombre, v.completa, v.intervalo, v.desde, v.hasta
  ),
  resultado as (
    select a.*,
           floor(a.segundos / a.intervalo)::int as esperadas,
           case when floor(a.segundos / a.intervalo) > 0
                then least(100, 100.0 * a.recibidas / floor(a.segundos / a.intervalo))
           end as cobertura
      from agregados a
  )
  select r.nombre,
         r.completa,
         round(r.segundos)::int,
         r.esperadas,
         r.recibidas::int,
         round(r.cobertura::numeric, 1),
         round(b.maxima::numeric, 1),
         round(b.p95::numeric, 1),
         coalesce(p.total, 0)::int,
         r.tardias::int,
         round(r.latencia::numeric, 1),
         coalesce(es.resumen, '—'),
         case when r.cobertura is not null
              then r.cobertura >= p_cobertura_min and b.maxima <= p_brecha_max_s
         end
    from resultado r
    left join resumen_brechas b on b.n = r.n
    left join perdidas p        on p.n = r.n
    left join estados es        on es.n = r.n
   order by r.n;
$$;

revoke all on function public.spike_reporte(uuid, numeric, numeric, numeric)
  from public, anon;
grant execute on function public.spike_reporte(uuid, numeric, numeric, numeric)
  to authenticated;
