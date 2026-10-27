-- 20261026000003 · SPIKE: simulación del recorrido (HU-011)
--
-- ⚠️ Spike desechable, tercera parte (ver 20261026000001 y 20261026000002).
-- También guarda las rutas recalculadas cuando la unidad se desvía
-- (spike_rutas_recalculadas), y el reporte mide el desvío contra la ruta
-- vigente en cada momento.
--
-- Agrega el modo «Simular recorrido»: la app recorre la ruta planificada sin
-- GPS (en el navegador o con el teléfono quieto) y manda las muestras por el
-- mismo camino que un recorrido real, para probar de punta a punta la cola,
-- el envío, el reporte y el mapa.
--
-- **Una sesión simulada NUNCA cuenta como evidencia**: no la produjo ningún
-- GPS ni la frenó ningún Android. Por eso queda marcada en cada fila
-- (simulada = true), en la vista de sesiones y en la primera columna del
-- reporte del recorrido.
--
-- Para borrar solo esta parte:
--
--   drop table if exists public.spike_rutas_recalculadas;
--   alter table public.spike_posiciones drop column simulada;
--   alter table public.spike_recorridos drop column simulada;
--   (y devolver el check de permiso, la vista y las dos funciones a como
--    estaban en 20261026000001 y 20261026000002)

-- La marca -------------------------------------------------------------------

alter table public.spike_posiciones
  add column simulada boolean not null default false;

alter table public.spike_recorridos
  add column simulada boolean not null default false;

grant insert (simulada) on public.spike_posiciones to authenticated;
grant insert (simulada) on public.spike_recorridos to authenticated;

-- Una simulación no pide permiso de ubicación: 'no_aplica'.
alter table public.spike_posiciones
  drop constraint spike_posiciones_permiso_check,
  add constraint spike_posiciones_permiso_check
    check (permiso in ('mientras_se_usa', 'siempre', 'no_aplica'));

-- spike_rutas_recalculadas --------------------------------------------------
-- Cuando la unidad se sale de la ruta (más de 80 m durante unos 15 s o 3
-- muestras), la app pide a OSRM una ruta nueva desde donde está hasta la
-- URBE (a lo sumo una cada 30 s) y la guarda aquí con su hora. El reporte mide
-- cada muestra contra la ruta vigente en su momento.

create table public.spike_rutas_recalculadas (
  id            bigint generated always as identity primary key,
  sesion_id     uuid not null,
  conductor_id  uuid not null default auth.uid()
                  references public.usuarios (id) on delete cascade,
  -- Hora del teléfono (la misma escala que capturada_en).
  calculada_en  timestamptz not null,
  desde         geography(Point, 4326) not null,
  ruta          geography(LineString, 4326) not null,
  distancia_m   double precision,
  duracion_s    double precision,
  desvio_m      double precision,
  simulada      boolean not null default false,
  unique (sesion_id, calculada_en)
);

alter table public.spike_rutas_recalculadas enable row level security;

create policy spike_rutas_recalculadas_inserta_el_conductor
  on public.spike_rutas_recalculadas
  for insert to authenticated
  with check (
    conductor_id = (select auth.uid())
    and exists (
      select 1 from public.usuarios u
       where u.id = (select auth.uid()) and u.rol = 'conductor'
    )
  );

create policy spike_rutas_recalculadas_ve_las_suyas
  on public.spike_rutas_recalculadas
  for select to authenticated
  using (conductor_id = (select auth.uid()) or public.es_admin());

revoke all on public.spike_rutas_recalculadas from anon;
revoke insert, update, delete, truncate on public.spike_rutas_recalculadas
  from authenticated;
grant insert (sesion_id, calculada_en, desde, ruta, distancia_m, duracion_s,
              desvio_m, simulada)
  on public.spike_rutas_recalculadas to authenticated;

-- spike_sesiones: dos columnas más al final (modo y simulada) -----------------

create or replace view public.spike_sesiones
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
       max(capturada_en)           as ultima_captura,
       min(modo)                   as modo,
       bool_or(simulada)           as simulada
  from public.spike_posiciones
 group by sesion_id, conductor_id;

revoke all on public.spike_sesiones from anon;

-- spike_reporte_ruta: la de 20261026000002 con tres cambios. Cambiar las
-- columnas de salida obliga a borrarla y crearla.
--   1. «simulada» como primera columna.
--   2. El desvío de cada muestra se mide contra la ruta vigente cuando se
--      capturó (la última recalculada antes de esa hora, o la original), y
--      «ruta cubierta» se mide contra la última ruta vigente: la que de
--      verdad llevó a la URBE.
--   3. rutas_recalculadas: cuántas veces se recalculó.

drop function public.spike_reporte_ruta(uuid, geography, numeric, numeric, numeric, numeric, numeric, numeric);

create function public.spike_reporte_ruta(
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
  simulada                 boolean,
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
  rutas_recalculadas       integer,
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
           coalesce(p_radio_m, r.radio_aviso_m, 1500)::numeric  as radio,
           -- La última ruta vigente: la última recalculada, o la original.
           coalesce((select rr.ruta from public.spike_rutas_recalculadas rr
                      where rr.sesion_id = p_sesion
                      order by rr.calculada_en desc limit 1),
                    r.ruta_planificada)                         as ultima_ruta,
           (select count(*) from public.spike_rutas_recalculadas rr
             where rr.sesion_id = p_sesion)                     as recalculos
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
  -- Cada muestra contra la ruta vigente en su momento: la última
  -- recalculada antes de capturarla, o la original.
  desvios as (
    select x.d from (
      select st_distance(m.punto, coalesce(
               (select rr.ruta from public.spike_rutas_recalculadas rr
                 where rr.sesion_id = p_sesion
                   and rr.calculada_en <= m.capturada_en
                 order by rr.calculada_en desc limit 1),
               pl.ruta_planificada))::float8 as d
        from muestras m cross join plan pl
    ) x
     where x.d is not null
  ),
  -- La ruta en puntos cada ≤ 25 m; un punto está cubierto si alguna muestra
  -- cayó a menos de p_cerca_ruta_m.
  vertices_ruta as (
    select (st_dumppoints(st_segmentize(pl.ultima_ruta, 25)::geometry)).geom::geography as v
      from plan pl
     where pl.ultima_ruta is not null
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
  select coalesce((select bool_or(f.simulada) from filas f), false),
         r.cerrada,
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
         (select pl.recalculos from plan pl)::int,
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

-- spike_ruta_geojson: la traza lleva properties.simulada ---------------------

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
           p.velocidad_ms, p.simulada, p.lat, p.lng
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
             'properties', jsonb_build_object('tipo', 'ruta_recalculada',
                             'calculada_en', rr.calculada_en,
                             'distancia_m', round(rr.distancia_m::numeric)),
             'geometry', st_asgeojson(rr.ruta::geometry, 6)::jsonb),
           1
      from public.spike_rutas_recalculadas rr
     where rr.sesion_id = p_sesion
    union all
    select jsonb_build_object(
             'type', 'Feature',
             'properties', jsonb_build_object('tipo', 'traza', 'sesion_id', p_sesion,
                             'muestras', count(*),
                             'simulada', bool_or(m.simulada)),
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
