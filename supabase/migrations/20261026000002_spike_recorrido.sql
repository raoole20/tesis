-- 20261026000002 · SPIKE: rastreo en un recorrido real (HU-011)
--
-- ⚠️ Spike desechable, segunda parte de 20261026000001_spike_rastreo.sql.
-- Agrega el modo «Recorrido real»: el conductor maneja una ruta de verdad
-- (por omisión, de la Av. 61 a la URBE) con el teléfono como lo usaría, y al
-- estacionar toca «Terminar recorrido». No hay fases por reloj: el reporte
-- separa el tiempo por lo que de verdad pasó en cada muestra (app a la vista,
-- minimizada o con la pantalla apagada). Ver docs/producto/spike-rastreo.md.
--
-- Para borrar solo esta parte (la tabla de muestras queda; para borrar todo,
-- ver también 20261026000001):
--
--   drop function if exists public.spike_ruta_geojson(uuid, numeric);
--   drop function if exists public.spike_reporte_ruta(uuid, geography, numeric, numeric, numeric, numeric, numeric, numeric);
--   drop table    if exists public.spike_recorridos;
--   alter table public.spike_posiciones
--     drop constraint spike_posiciones_modo_check,
--     drop constraint spike_posiciones_modo_duracion_check,
--     drop column modo, drop column bateria_pct, drop column cargando,
--     drop column cierre, drop column rumbo_deg, drop column rumbo_calculado,
--     drop column velocidad_ms;
--   (y devolver fase y duracion_fase_s a como estaban en 20261026000001)

-- spike_posiciones: lo que necesita el recorrido ---------------------------

alter table public.spike_posiciones
  add column modo        text     not null default 'fases',
  -- Batería al capturar: si el teléfono iba cargando (cargador del carro) y
  -- cuánto gastó la prueba. null si no se pudo leer.
  add column bateria_pct smallint check (bateria_pct between 0 and 100),
  add column cargando    boolean,
  -- La marca de cierre: la fila que la app escribe al tocar «Terminar
  -- recorrido». No es una muestra (no cuenta ni en cobertura ni en
  -- distancia): marca el fin de la ventana, y su seq permite ver si se
  -- perdieron muestras justo antes de terminar.
  add column cierre      boolean  not null default false,
  -- Rumbo (0 = norte, 90 = este) y velocidad del GPS. Si el GPS no da un
  -- rumbo válido (teléfono quieto: 0 o -1), la app lo calcula con el azimut
  -- desde la muestra anterior y lo marca en rumbo_calculado.
  add column rumbo_deg       double precision check (rumbo_deg >= 0 and rumbo_deg < 360),
  add column rumbo_calculado boolean,
  add column velocidad_ms    double precision check (velocidad_ms >= 0);

alter table public.spike_posiciones
  add constraint spike_posiciones_modo_check
    check (modo in ('fases', 'recorrido'));

-- En un recorrido no hay fases por reloj: fase = 'recorrido' y sin duración.
alter table public.spike_posiciones
  drop constraint spike_posiciones_fase_check,
  add constraint spike_posiciones_fase_check
    check (fase in ('1_primer_plano', '2_minimizada', '3_pantalla_apagada',
                    'recorrido'));

alter table public.spike_posiciones
  alter column duracion_fase_s drop not null,
  add constraint spike_posiciones_modo_duracion_check
    check ((modo = 'fases') = (duracion_fase_s is not null)
           and (modo = 'recorrido') = (fase = 'recorrido'));

grant insert (modo, bateria_pct, cargando, cierre, rumbo_deg, rumbo_calculado,
              velocidad_ms)
  on public.spike_posiciones to authenticated;

-- spike_recorridos ----------------------------------------------------------
-- Una fila por recorrido: la ruta planificada (para comparar la traza contra
-- las calles de verdad) y el domicilio de prueba. La escribe la app una vez,
-- al llegar la primera ubicación.

create table public.spike_recorridos (
  sesion_id        uuid primary key,
  conductor_id     uuid not null default auth.uid()
                     references public.usuarios (id) on delete cascade,
  -- La línea por las calles, de OSRM. null si no se pudo trazar: la prueba
  -- se hace igual y el reporte deja vacías las métricas de desviación.
  ruta_planificada geography(LineString, 4326),
  ruta_fuente      text,
  ruta_distancia_m double precision,
  ruta_duracion_s  double precision,
  ida_y_vuelta     boolean not null default false,
  inicio_plan      geography(Point, 4326),
  llegada_plan     geography(Point, 4326),
  -- Opcional: un domicilio de prueba para medir el aviso de proximidad.
  domicilio        geography(Point, 4326),
  radio_aviso_m    integer not null default 1500 check (radio_aviso_m > 0),
  creado_en        timestamptz not null default now()
);

create index spike_recorridos_conductor_idx
  on public.spike_recorridos (conductor_id);

alter table public.spike_recorridos enable row level security;

create policy spike_recorridos_inserta_el_conductor on public.spike_recorridos
  for insert to authenticated
  with check (
    conductor_id = (select auth.uid())
    and exists (
      select 1 from public.usuarios u
       where u.id = (select auth.uid()) and u.rol = 'conductor'
    )
  );

create policy spike_recorridos_ve_los_suyos on public.spike_recorridos
  for select to authenticated
  using (conductor_id = (select auth.uid()) or public.es_admin());

revoke all on public.spike_recorridos from anon;
revoke insert, update, delete, truncate on public.spike_recorridos
  from authenticated;
grant insert (
  sesion_id, ruta_planificada, ruta_fuente, ruta_distancia_m, ruta_duracion_s,
  ida_y_vuelta, inicio_plan, llegada_plan, domicilio, radio_aviso_m
) on public.spike_recorridos to authenticated;

-- spike_reporte_ruta --------------------------------------------------------
-- Una sola fila con el resultado del recorrido. security invoker: respeta el
-- RLS de quien la llama.
--
-- Ventana: de la primera muestra a la marca de cierre (o a la última muestra
-- si no hay cierre: completa = false).
--
-- Estado de cada muestra:
--   primer_plano      app a la vista (resumed/inactive) con pantalla encendida
--   segundo_plano     app minimizada (paused/hidden/detached), pantalla encendida
--   pantalla_apagada  pantalla apagada, sea cual sea el estado de la app
-- El tiempo entre dos muestras se carga al estado de la primera: si Android
-- congela la app, el silencio cae en el estado en que estaba al congelarse.
--
-- Criterio (cumple): recorrido completo, cobertura ≥ p_cobertura_min en
-- segundo plano y con pantalla apagada (los estados que hubo), brecha máxima
-- ≤ p_brecha_max_s y salto máximo ≤ p_brecha_max_m.

create or replace function public.spike_reporte_ruta(
  p_sesion        uuid,
  p_domicilio     geography default null,
  p_radio_m       numeric   default null,
  p_cobertura_min numeric   default 90,
  p_brecha_max_s  numeric   default 30,
  p_brecha_max_m  numeric   default 500,
  p_tardia_s      numeric   default 30,
  p_cerca_ruta_m  numeric   default 50
)
returns table (
  completa                 boolean,
  inicio                   timestamptz,
  fin                      timestamptz,
  duracion_s               integer,
  distancia_m              numeric,
  velocidad_media_kmh      numeric,
  velocidad_max_gps_kmh    numeric,
  velocidad_max_traza_kmh  numeric,
  esperadas                integer,
  recibidas                integer,
  cobertura_pct            numeric,
  brecha_max_s             numeric,
  brecha_max_en            timestamptz,
  brecha_max_m             numeric,
  brecha_p95_s             numeric,
  brechas_largas           integer,
  pct_primer_plano         numeric,
  pct_segundo_plano        numeric,
  pct_pantalla_apagada     numeric,
  cobertura_primer_plano   numeric,
  cobertura_segundo_plano  numeric,
  cobertura_pantalla_apagada numeric,
  precision_p50_m          numeric,
  precision_p95_m          numeric,
  perdidas                 integer,
  tardias                  integer,
  latencia_mediana_s       numeric,
  pct_cargando             numeric,
  bateria_inicio_pct       integer,
  bateria_fin_pct          integer,
  ruta_planificada_m       numeric,
  desvio_mediana_m         numeric,
  desvio_p95_m             numeric,
  desvio_max_m             numeric,
  pct_muestras_cerca_ruta  numeric,
  pct_ruta_cubierta        numeric,
  dom_radio_m              integer,
  dom_distancia_min_m      numeric,
  dom_entrada_en           timestamptz,
  dom_entrada_m            numeric,
  dom_brecha_previa_s      numeric,
  dom_muestras_alrededor   integer,
  dom_aviso_a_tiempo       boolean,
  cumple                   boolean
)
language sql
stable
set search_path = public
as $$
  with filas as (
    select p.*
      from public.spike_posiciones p
     where p.sesion_id = p_sesion
  ),
  plan as (
    select r.ruta_planificada,
           coalesce(p_domicilio, r.domicilio)                   as domicilio,
           coalesce(p_radio_m, r.radio_aviso_m, 1500)::numeric  as radio
      from (select 1) uno
      left join public.spike_recorridos r on r.sesion_id = p_sesion
  ),
  muestras as (
    select f.seq, f.capturada_en, f.enviada_en, f.recibida_en, f.precision_m,
           f.bateria_pct, f.cargando, f.intervalo_s, f.velocidad_ms,
           st_setsrid(st_makepoint(f.lng, f.lat), 4326)::geography as punto,
           case when f.pantalla_encendida is false then 'pantalla_apagada'
                when f.estado_app in ('resumed', 'inactive') then 'primer_plano'
                else 'segundo_plano' end                              as estado
      from filas f
     where not f.cierre
  ),
  ventana as (
    select min(m.capturada_en)                                   as desde,
           coalesce((select max(f.capturada_en) from filas f where f.cierre),
                    max(m.capturada_en))                         as hasta,
           exists (select 1 from filas f where f.cierre)         as cerrada,
           min(m.intervalo_s)                                    as intervalo
      from muestras m
  ),
  -- Cada muestra con la siguiente; la última se cierra con el fin de la
  -- ventana (sin distancia: no se sabe dónde estaba).
  tramos as (
    select m.estado, m.capturada_en as desde, m.punto,
           coalesce(lead(m.capturada_en) over w, v.hasta)          as hasta,
           coalesce(st_distance(m.punto, lead(m.punto) over w), 0) as metros
      from muestras m
     cross join ventana v
    window w as (order by m.capturada_en, m.seq)
  ),
  tramos_s as (
    select t.*, extract(epoch from t.hasta - t.desde)::float8 as s from tramos t
  ),
  brecha_mayor as (
    select t.desde, t.s from tramos_s t order by t.s desc, t.desde limit 1
  ),
  por_estado as (
    select e.estado,
           coalesce(sum(t.s), 0)                                      as s,
           (select count(*) from muestras m where m.estado = e.estado) as recibidas
      from (values ('primer_plano'), ('segundo_plano'), ('pantalla_apagada')) e (estado)
      left join tramos_s t on t.estado = e.estado
     group by e.estado
  ),
  huecos as (
    select f.seq - coalesce(lag(f.seq) over (order by f.seq), 0) - 1 as faltan
      from filas f
  ),
  desvios as (
    select st_distance(m.punto, pl.ruta_planificada)::float8 as d
      from muestras m cross join plan pl
     where pl.ruta_planificada is not null
  ),
  -- La ruta en puntos cada ≤ 25 m; un punto está cubierto si alguna muestra
  -- cayó a menos de p_cerca_ruta_m.
  vertices_ruta as (
    select (st_dumppoints(st_segmentize(pl.ruta_planificada, 25)::geometry)).geom::geography as v
      from plan pl
     where pl.ruta_planificada is not null
  ),
  cobertura_ruta as (
    select count(*) as total,
           count(*) filter (
             where exists (select 1 from muestras m
                            where st_dwithin(m.punto, vr.v, p_cerca_ruta_m))
           ) as cubiertos
      from vertices_ruta vr
  ),
  -- Domicilio: la primera muestra dentro del radio.
  cerca_dom as (
    select m.capturada_en, st_distance(m.punto, pl.domicilio) as dist,
           extract(epoch from m.capturada_en
                   - lag(m.capturada_en) over (order by m.capturada_en, m.seq))::float8 as previa
      from muestras m cross join plan pl
     where pl.domicilio is not null
  ),
  entrada as (
    select c.* from cerca_dom c, plan pl
     where c.dist <= pl.radio
     order by c.capturada_en limit 1
  ),
  bateria as (
    select (select m.bateria_pct from muestras m where m.bateria_pct is not null
             order by m.capturada_en limit 1)      as inicio,
           (select m.bateria_pct from muestras m where m.bateria_pct is not null
             order by m.capturada_en desc limit 1) as fin
  ),
  resumen as (
    select v.cerrada, v.desde, v.hasta, v.intervalo,
           extract(epoch from v.hasta - v.desde)::float8                 as segundos,
           (select count(*) from muestras)                                as recibidas,
           (select sum(t.metros) from tramos_s t)                         as distancia,
           (select max(t.metros) from tramos_s t)                         as salto_max,
           (select percentile_cont(0.95) within group (order by t.s) from tramos_s t) as p95,
           (select count(*) from tramos_s t where t.s > p_brecha_max_s)   as largas
      from ventana v
  ),
  cob as (
    select pe.estado, pe.s, pe.recibidas,
           case when floor(pe.s / r.intervalo) > 0
                then least(100, 100.0 * pe.recibidas / floor(pe.s / r.intervalo)) end as pct
      from por_estado pe cross join resumen r
  )
  select r.cerrada,
         r.desde,
         r.hasta,
         round(r.segundos)::int,
         round(r.distancia::numeric),
         round((3.6 * r.distancia / nullif(r.segundos, 0))::numeric, 1),
         round((select 3.6 * max(m.velocidad_ms) from muestras m)::numeric, 1),
         -- Con tramos de al menos 3 s: entre dos muestras casi simultáneas el
         -- ruido del GPS daría velocidades absurdas.
         round((select 3.6 * max(t.metros / t.s) from tramos_s t
                 where t.s >= 3 and t.metros > 0)::numeric, 1),
         floor(r.segundos / r.intervalo)::int,
         r.recibidas::int,
         case when floor(r.segundos / r.intervalo) > 0
              then round(least(100, 100.0 * r.recibidas / floor(r.segundos / r.intervalo))::numeric, 1) end,
         round(bm.s::numeric, 1),
         bm.desde,
         round(r.salto_max::numeric),
         round(r.p95::numeric, 1),
         r.largas::int,
         round((100.0 * pp.s / nullif(r.segundos, 0))::numeric, 1),
         round((100.0 * sp.s / nullif(r.segundos, 0))::numeric, 1),
         round((100.0 * pa.s / nullif(r.segundos, 0))::numeric, 1),
         round(pp.pct::numeric, 1),
         round(sp.pct::numeric, 1),
         round(pa.pct::numeric, 1),
         round((select percentile_cont(0.5) within group (order by m.precision_m) from muestras m)::numeric, 1),
         round((select percentile_cont(0.95) within group (order by m.precision_m) from muestras m)::numeric, 1),
         coalesce((select sum(h.faltan) from huecos h where h.faltan > 0), 0)::int,
         (select count(*) from muestras m
           where extract(epoch from m.enviada_en - m.capturada_en) > p_tardia_s)::int,
         round((select percentile_cont(0.5) within group (
                   order by extract(epoch from m.recibida_en - m.capturada_en)::float8)
                  from muestras m)::numeric, 1),
         round((select 100.0 * count(*) filter (where m.cargando)
                       / nullif(count(m.cargando), 0) from muestras m)::numeric, 1),
         b.inicio::int,
         b.fin::int,
         round((select st_length(pl.ruta_planificada) from plan pl)::numeric),
         round((select percentile_cont(0.5) within group (order by d.d) from desvios d)::numeric, 1),
         round((select percentile_cont(0.95) within group (order by d.d) from desvios d)::numeric, 1),
         round((select max(d.d) from desvios d)::numeric, 1),
         round((select 100.0 * count(*) filter (where d.d <= p_cerca_ruta_m)
                       / nullif(count(*), 0) from desvios d)::numeric, 1),
         round((select 100.0 * cr.cubiertos / nullif(cr.total, 0) from cobertura_ruta cr)::numeric, 1),
         (select case when pl.domicilio is not null then pl.radio::int end from plan pl),
         round((select min(c.dist) from cerca_dom c)::numeric),
         e.capturada_en,
         round(e.dist::numeric),
         round(e.previa::numeric, 1),
         (select count(*) from muestras m
           where e.capturada_en is not null
             and m.capturada_en between e.capturada_en - interval '60 seconds'
                                    and e.capturada_en + interval '60 seconds')::int,
         case when e.capturada_en is not null
              then coalesce(e.previa, 0) <= p_brecha_max_s end,
         case when r.cerrada then
           coalesce(bm.s, 0) <= p_brecha_max_s
           and coalesce(r.salto_max, 0) <= p_brecha_max_m
           and coalesce(sp.pct >= p_cobertura_min, true)
           and coalesce(pa.pct >= p_cobertura_min, true)
         end
    from resumen r
    cross join bateria b
    left join brecha_mayor bm on true
    left join cob pp on pp.estado = 'primer_plano'
    left join cob sp on sp.estado = 'segundo_plano'
    left join cob pa on pa.estado = 'pantalla_apagada'
    left join entrada e on true
   where r.desde is not null;
$$;

revoke all on function public.spike_reporte_ruta(uuid, geography, numeric, numeric, numeric, numeric, numeric, numeric)
  from public, anon;
grant execute on function public.spike_reporte_ruta(uuid, geography, numeric, numeric, numeric, numeric, numeric, numeric)
  to authenticated;

-- spike_ruta_geojson --------------------------------------------------------
-- La sesión como GeoJSON (FeatureCollection) para dibujarla fuera de la app
-- (geojson.io, QGIS). Cada Feature lleva properties.tipo:
--   ruta_planificada  la línea de OSRM, si hubo
--   traza             la línea de las muestras, en orden
--   brecha            cada salto de más de p_brecha_s segundos sin muestras
--   muestra           cada punto, con seq, hora, estado_app y pantalla
--   inicio_plan, llegada_plan, domicilio   los puntos del plan
-- Coordenadas en [lng, lat] (WGS 84), como manda GeoJSON.

create or replace function public.spike_ruta_geojson(
  p_sesion   uuid,
  p_brecha_s numeric default 30
)
returns jsonb
language sql
stable
set search_path = public
as $$
  with m as (
    select p.seq, p.capturada_en, p.estado_app, p.pantalla_encendida,
           p.precision_m, p.bateria_pct, p.cargando, p.rumbo_deg,
           p.velocidad_ms, p.lat, p.lng
      from public.spike_posiciones p
     where p.sesion_id = p_sesion and not p.cierre
  ),
  o as (
    select m.*,
           lag(m.lat)          over w as lat0,
           lag(m.lng)          over w as lng0,
           lag(m.capturada_en) over w as t0
      from m
    window w as (order by m.capturada_en, m.seq)
  ),
  r as (
    select * from public.spike_recorridos where sesion_id = p_sesion
  ),
  features as (
    select jsonb_build_object(
             'type', 'Feature',
             'properties', jsonb_build_object('tipo', 'ruta_planificada',
                             'fuente', r.ruta_fuente,
                             'distancia_m', round(r.ruta_distancia_m::numeric)),
             'geometry', st_asgeojson(r.ruta_planificada::geometry, 6)::jsonb) as f,
           1 as orden
      from r where r.ruta_planificada is not null
    union all
    select jsonb_build_object(
             'type', 'Feature',
             'properties', jsonb_build_object('tipo', 'traza', 'sesion_id', p_sesion,
                             'muestras', count(*)),
             'geometry', st_asgeojson(
                           st_makeline(st_setsrid(st_makepoint(m.lng, m.lat), 4326)
                                       order by m.capturada_en, m.seq), 6)::jsonb),
           2
      from m
    having count(*) >= 2
    union all
    select jsonb_build_object(
             'type', 'Feature',
             'properties', jsonb_build_object('tipo', 'brecha',
                             'desde', o.t0, 'hasta', o.capturada_en,
                             'segundos', round(extract(epoch from o.capturada_en - o.t0)),
                             'metros', round(st_distance(
                                 st_setsrid(st_makepoint(o.lng0, o.lat0), 4326)::geography,
                                 st_setsrid(st_makepoint(o.lng, o.lat), 4326)::geography)::numeric)),
             'geometry', jsonb_build_object('type', 'LineString', 'coordinates',
                           jsonb_build_array(jsonb_build_array(o.lng0, o.lat0),
                                             jsonb_build_array(o.lng, o.lat)))),
           3
      from o
     where o.t0 is not null
       and extract(epoch from o.capturada_en - o.t0) > p_brecha_s
    union all
    select jsonb_build_object(
             'type', 'Feature',
             'properties', jsonb_build_object('tipo', 'muestra', 'seq', m.seq,
                             'capturada_en', m.capturada_en,
                             'estado_app', m.estado_app,
                             'pantalla_encendida', m.pantalla_encendida,
                             'precision_m', m.precision_m,
                             'bateria_pct', m.bateria_pct,
                             'cargando', m.cargando,
                             'rumbo_deg', m.rumbo_deg,
                             'velocidad_kmh', round((3.6 * m.velocidad_ms)::numeric, 1)),
             'geometry', jsonb_build_object('type', 'Point', 'coordinates',
                           jsonb_build_array(m.lng, m.lat))),
           4
      from m
    union all
    select jsonb_build_object(
             'type', 'Feature',
             'properties', jsonb_build_object('tipo', x.tipo),
             'geometry', st_asgeojson(x.g::geometry, 6)::jsonb),
           5
      from r
     cross join lateral (values ('inicio_plan', r.inicio_plan),
                                ('llegada_plan', r.llegada_plan),
                                ('domicilio', r.domicilio)) as x (tipo, g)
     where x.g is not null
  )
  select jsonb_build_object(
           'type', 'FeatureCollection',
           'features', coalesce(jsonb_agg(f order by orden), '[]'::jsonb))
    from features;
$$;

revoke all on function public.spike_ruta_geojson(uuid, numeric) from public, anon;
grant execute on function public.spike_ruta_geojson(uuid, numeric) to authenticated;
