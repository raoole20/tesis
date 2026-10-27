-- Diseño físico de la operación — Fase II, actividad 2.3
--
-- Extiende el esquema de identidad y ubicación ya migrado
-- (supabase/migrations/20260924000001 a 0009) con las entidades que exigen
-- las historias HU-004 a HU-016: vehículos, turnos, inscripciones,
-- inasistencias, renovaciones, viajes, posiciones, avisos, pagos y
-- notificaciones.
--
-- ⚠️ ES UN DISEÑO, NO UNA MIGRACIÓN. No está en supabase/migrations y no se
-- aplicó. Se validó ejecutándolo dentro de una transacción que se revierte
-- (BEGIN … ROLLBACK) contra la base de desarrollo. Cuando se implemente cada
-- historia, su parte se convierte en migración con sus pruebas.
--
-- Convenciones heredadas del esquema actual: nombres en español y
-- snake_case, claves uuid (salvo las bitácoras de alto volumen), fechas
-- timestamptz, geografía en WGS84 (SRID 4326), RLS en toda tabla y
-- escrituras sensibles solo a través de funciones security definer que
-- validan la regla de negocio.

-- 1. Tipos enumerados ---------------------------------------------------------

create type public.bloque_turno       as enum ('manana', 'tarde', 'noche');
create type public.sentido_servicio   as enum ('ida', 'regreso', 'ida_y_regreso');
create type public.modalidad_cobro    as enum ('semanal', 'quincenal', 'mensual');
create type public.estado_inscripcion as enum
  ('pendiente', 'aceptada', 'rechazada', 'cancelada', 'vencida');
create type public.estado_viaje       as enum ('en_curso', 'finalizado', 'cancelado');
create type public.metodo_pago        as enum
  ('dolares_efectivo', 'pago_movil', 'zelle', 'bolivares_efectivo');
create type public.motivo_contingencia as enum
  ('averia', 'combustible', 'via_cerrada', 'otro');
create type public.tipo_notificacion  as enum
  ('solicitud_nueva', 'solicitud_decidida', 'proximidad', 'contingencia',
   'renovacion', 'cuenta');

-- Días de la semana como en ISO 8601: 1 = lunes … 7 = domingo.
create domain public.dias_semana as smallint[]
  check (cardinality(value) >= 1 and value <@ array[1,2,3,4,5,6,7]::smallint[]);

-- 2. Tablas -------------------------------------------------------------------

-- HU-004. Un conductor puede registrar más de una unidad; cada turno usa una.
create table public.vehiculos (
  id           uuid primary key default gen_random_uuid(),
  conductor_id uuid not null references public.conductores (id) on delete cascade,
  placa        text not null unique check (placa ~ '^[A-Z0-9]{6,7}$'),
  marca        text not null,
  modelo       text not null,
  anio         smallint check (anio between 1970 and 2100),
  color        text not null,
  capacidad    smallint not null check (capacidad >= 1),
  url_foto     text,
  creado_en    timestamptz not null default now()
);
create index vehiculos_conductor_idx on public.vehiculos (conductor_id);

-- HU-006. La cobertura del turno es la de su conductor (conductor_zonas):
-- no se repite por turno.
create table public.turnos (
  id           uuid primary key default gen_random_uuid(),
  conductor_id uuid not null references public.conductores (id) on delete cascade,
  vehiculo_id  uuid not null references public.vehiculos (id) on delete restrict,
  bloque       public.bloque_turno not null,
  hora_ida     time,
  hora_regreso time,
  dias         public.dias_semana not null,
  sentido      public.sentido_servicio not null,
  cupos        smallint not null check (cupos >= 1),
  tarifa       numeric(10,2) not null check (tarifa > 0),
  modalidad    public.modalidad_cobro not null,
  activo       boolean not null default true,
  creado_en    timestamptz not null default now(),
  check (sentido = 'regreso' or hora_ida is not null),
  check (sentido = 'ida' or hora_regreso is not null),
  check (hora_ida is null or hora_regreso is null or hora_ida < hora_regreso)
);
create index turnos_conductor_idx on public.turnos (conductor_id);
create index turnos_activos_idx   on public.turnos (bloque) where activo;

-- HU-008, HU-009. Un cupo es una inscripción aceptada.
create table public.inscripciones (
  id             uuid primary key default gen_random_uuid(),
  turno_id       uuid not null references public.turnos (id) on delete cascade,
  estudiante_id  uuid not null references public.estudiantes (id) on delete cascade,
  dias           public.dias_semana not null,
  estado         public.estado_inscripcion not null default 'pendiente',
  -- Hora a la que el conductor acordó pasar por el domicilio (como hoy, de
  -- palabra). No es un cálculo de llegada: ordena la nómina y las paradas.
  hora_recogida  time,
  motivo_rechazo text,
  solicitada_en  timestamptz not null default now(),
  decidida_en    timestamptz
);
-- Una sola solicitud vigente por estudiante y turno.
create unique index inscripciones_una_vigente_idx
  on public.inscripciones (turno_id, estudiante_id)
  where estado in ('pendiente', 'aceptada');
create index inscripciones_turno_estado_idx on public.inscripciones (turno_id, estado);
create index inscripciones_estudiante_idx   on public.inscripciones (estudiante_id);

-- HU-010. Solo se guardan las excepciones: por omisión, el inscrito viaja.
create table public.inasistencias (
  inscripcion_id uuid not null references public.inscripciones (id) on delete cascade,
  fecha          date not null,
  avisada_en     timestamptz not null default now(),
  primary key (inscripcion_id, fecha)
);

-- HU-016. El conductor abre un período; cada inscrito confirma o pierde el cupo.
create table public.periodos_renovacion (
  id        uuid primary key default gen_random_uuid(),
  turno_id  uuid not null references public.turnos (id) on delete cascade,
  inicia_en date not null,
  limite_en date not null,
  cerrado   boolean not null default false,
  creado_en timestamptz not null default now(),
  check (limite_en <= inicia_en)
);
create index periodos_renovacion_turno_idx on public.periodos_renovacion (turno_id);

create table public.renovaciones (
  periodo_id     uuid not null references public.periodos_renovacion (id) on delete cascade,
  inscripcion_id uuid not null references public.inscripciones (id) on delete cascade,
  dias           public.dias_semana not null,
  confirmada_en  timestamptz not null default now(),
  primary key (periodo_id, inscripcion_id)
);

-- HU-011, HU-015. Un viaje es un turno recorrido en una fecha y un sentido.
create table public.viajes (
  id            uuid primary key default gen_random_uuid(),
  turno_id      uuid not null references public.turnos (id) on delete cascade,
  fecha         date not null default (now() at time zone 'America/Caracas')::date,
  sentido       public.sentido_servicio not null check (sentido <> 'ida_y_regreso'),
  estado        public.estado_viaje not null default 'en_curso',
  iniciado_en   timestamptz not null default now(),
  finalizado_en timestamptz,
  unique (turno_id, fecha, sentido)
);

-- HU-011. Alto volumen (una fila cada 5 s por unidad): clave bigint.
create table public.posiciones (
  id           bigint generated always as identity primary key,
  viaje_id     uuid not null references public.viajes (id) on delete cascade,
  punto        geography(Point, 4326) not null,
  precision_m  real,
  capturada_en timestamptz not null,
  recibida_en  timestamptz not null default now()
);
create index posiciones_viaje_idx on public.posiciones (viaje_id, capturada_en desc);

-- HU-015.
create table public.avisos_contingencia (
  id                uuid primary key default gen_random_uuid(),
  viaje_id          uuid not null references public.viajes (id) on delete cascade,
  motivo            public.motivo_contingencia not null,
  detalle           text,
  demora_min        smallint check (demora_min > 0),
  cancela_recorrido boolean not null default false,
  enviado_en        timestamptz not null default now(),
  check (motivo <> 'otro' or length(trim(coalesce(detalle, ''))) > 0),
  check (cancela_recorrido or demora_min is not null)
);
create index avisos_contingencia_viaje_idx on public.avisos_contingencia (viaje_id);

-- HU-013. La app registra pagos, no los procesa.
create table public.pagos (
  id             uuid primary key default gen_random_uuid(),
  inscripcion_id uuid not null references public.inscripciones (id) on delete restrict,
  monto          numeric(10,2) not null check (monto > 0),
  metodo         public.metodo_pago not null,
  periodo_inicio date not null,
  periodo_fin    date not null,
  registrado_en  timestamptz not null default now(),
  anulado_en     timestamptz,
  check (periodo_fin >= periodo_inicio)
);
create unique index pagos_uno_por_periodo_idx
  on public.pagos (inscripcion_id, periodo_inicio) where anulado_en is null;

-- Bandeja de avisos de cada usuario; un webhook la entrega por push.
create table public.notificaciones (
  id             bigint generated always as identity primary key,
  usuario_id     uuid not null references public.usuarios (id) on delete cascade,
  tipo           public.tipo_notificacion not null,
  titulo         text not null,
  cuerpo         text not null,
  viaje_id       uuid references public.viajes (id) on delete cascade,
  inscripcion_id uuid references public.inscripciones (id) on delete cascade,
  creada_en      timestamptz not null default now(),
  leida_en       timestamptz
);
create index notificaciones_usuario_idx on public.notificaciones (usuario_id, creada_en desc);
-- HU-014: un solo aviso de proximidad por estudiante y por viaje.
create unique index notificaciones_una_proximidad_idx
  on public.notificaciones (usuario_id, viaje_id) where tipo = 'proximidad';

-- Tokens de Firebase Cloud Messaging de cada teléfono.
create table public.dispositivos (
  token          text primary key,
  usuario_id     uuid not null references public.usuarios (id) on delete cascade,
  plataforma     text not null default 'android',
  actualizado_en timestamptz not null default now()
);
create index dispositivos_usuario_idx on public.dispositivos (usuario_id);

-- 3. Funciones auxiliares -----------------------------------------------------

create or replace function public.es_conductor_del_turno(p_turno uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from turnos t where t.id = p_turno and t.conductor_id = auth.uid());
$$;

create or replace function public.esta_inscrito_en(p_turno uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from inscripciones i
     where i.turno_id = p_turno and i.estudiante_id = auth.uid() and i.estado = 'aceptada');
$$;

create or replace function public.cupos_libres(p_turno uuid)
returns integer language sql stable security definer set search_path = public as $$
  select t.cupos - (select count(*) from inscripciones i
                     where i.turno_id = t.id and i.estado = 'aceptada')::integer
    from turnos t where t.id = p_turno;
$$;

-- Distancia a la que se avisa al estudiante (HU-014). Se calibra en la Fase IV.
create or replace function public.radio_proximidad_m()
returns double precision language sql immutable as $$ select 1500::double precision $$;

-- Pasajeros de un turno en una fecha: inscritos aceptados que asisten ese día
-- de la semana, marcando quién avisó inasistencia (HU-010).
create or replace function public.nomina_del_dia(p_turno uuid, p_fecha date)
returns table (inscripcion_id uuid, estudiante_id uuid, viaja boolean)
language plpgsql stable security definer set search_path = public as $$
begin
  if not (es_conductor_del_turno(p_turno) or es_admin()) then
    raise exception 'Solo el conductor del turno consulta su nómina.';
  end if;
  return query
    select i.id, i.estudiante_id,
           not exists (select 1 from inasistencias a
                        where a.inscripcion_id = i.id and a.fecha = p_fecha)
      from inscripciones i
     where i.turno_id = p_turno
       and i.estado = 'aceptada'
       and extract(isodow from p_fecha)::smallint = any (i.dias);
end;
$$;

-- 4. Reglas que cruzan tablas (triggers) ---------------------------------------

-- HU-006: la unidad es del mismo conductor y los cupos no superan su capacidad.
create or replace function public.validar_turno()
returns trigger language plpgsql set search_path = public as $$
declare
  v_vehiculo vehiculos%rowtype;
begin
  select * into v_vehiculo from vehiculos where id = new.vehiculo_id;
  if v_vehiculo.conductor_id <> new.conductor_id then
    raise exception 'El vehículo no pertenece al conductor del turno.';
  end if;
  if new.cupos > v_vehiculo.capacidad then
    raise exception 'Los cupos del turno (%) superan la capacidad del vehículo (%).',
      new.cupos, v_vehiculo.capacidad;
  end if;
  return new;
end;
$$;
create trigger turnos_validar
  before insert or update of vehiculo_id, cupos, conductor_id on public.turnos
  for each row execute function public.validar_turno();

-- HU-014: cada posición nueva busca domicilios de la nómina dentro del radio.
create or replace function public.avisar_proximidad()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_viaje viajes%rowtype;
begin
  select * into v_viaje from viajes where id = new.viaje_id;
  -- Solo de ida se recoge en el domicilio.
  if v_viaje.estado <> 'en_curso' or v_viaje.sentido <> 'ida' then
    return new;
  end if;
  insert into notificaciones (usuario_id, tipo, titulo, cuerpo, viaje_id)
  select n.estudiante_id, 'proximidad', 'Tu transporte está cerca',
         'La unidad está a pocos minutos de tu casa.', new.viaje_id
    from nomina_del_dia(v_viaje.turno_id, v_viaje.fecha) n
    join estudiantes e on e.id = n.estudiante_id
   where n.viaja
     and e.domicilio is not null
     and st_dwithin(e.domicilio, new.punto, radio_proximidad_m())
  on conflict do nothing;
  return new;
end;
$$;
create trigger posiciones_avisar_proximidad
  after insert on public.posiciones
  for each row execute function public.avisar_proximidad();

-- 5. Transiciones de negocio (RPC) ---------------------------------------------

-- HU-008.
create or replace function public.solicitar_cupo(p_turno uuid, p_dias smallint[])
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_turno turnos%rowtype;
  v_id    uuid;
begin
  select * into v_turno from turnos where id = p_turno and activo;
  if not found then
    raise exception 'El turno no existe o no está activo.';
  end if;
  if not exists (select 1 from estudiantes e join usuarios u on u.id = e.id
                  where e.id = auth.uid() and u.estado = 'aprobada'
                    and e.domicilio is not null) then
    raise exception 'Fija tu domicilio antes de solicitar un cupo.';
  end if;
  if not (p_dias <@ v_turno.dias::smallint[]) then
    raise exception 'Elegiste días en los que el turno no opera.';
  end if;
  if exists (select 1 from inscripciones i join turnos t on t.id = i.turno_id
              where i.estudiante_id = auth.uid()
                and i.estado in ('pendiente', 'aceptada')
                and t.bloque = v_turno.bloque) then
    raise exception 'Ya tienes una solicitud o un cupo en ese bloque horario.';
  end if;
  if cupos_libres(p_turno) < 1 then
    raise exception 'El turno no tiene cupos libres.';
  end if;

  insert into inscripciones (turno_id, estudiante_id, dias)
  values (p_turno, auth.uid(), p_dias::dias_semana)
  returning id into v_id;

  insert into notificaciones (usuario_id, tipo, titulo, cuerpo, inscripcion_id)
  values (v_turno.conductor_id, 'solicitud_nueva', 'Nueva solicitud de cupo',
          'Un estudiante pidió un cupo en tu turno.', v_id);
  return v_id;
end;
$$;

-- HU-009. El turno se bloquea (FOR UPDATE): dos aceptaciones simultáneas se
-- atienden una detrás de otra y nunca se asignan más cupos que los ofertados.
create or replace function public.decidir_solicitud(
  p_inscripcion uuid, p_acepta boolean, p_motivo text default null)
returns public.estado_inscripcion
language plpgsql security definer set search_path = public as $$
declare
  v_ins   inscripciones%rowtype;
  v_turno turnos%rowtype;
begin
  select * into v_ins from inscripciones where id = p_inscripcion;
  if not found then
    raise exception 'La solicitud no existe.';
  end if;
  select * into v_turno from turnos where id = v_ins.turno_id for update;
  if v_turno.conductor_id <> auth.uid() then
    raise exception 'Solo el conductor del turno decide sus solicitudes.';
  end if;
  select * into v_ins from inscripciones where id = p_inscripcion for update;
  if v_ins.estado <> 'pendiente' then
    raise exception 'La solicitud ya fue decidida.';
  end if;

  if p_acepta then
    if cupos_libres(v_turno.id) < 1 then
      raise exception 'No quedan asientos disponibles en este turno.';
    end if;
    update inscripciones set estado = 'aceptada', decidida_en = now()
     where id = p_inscripcion;
  else
    update inscripciones
       set estado = 'rechazada', decidida_en = now(),
           motivo_rechazo = nullif(trim(p_motivo), '')
     where id = p_inscripcion;
  end if;

  insert into notificaciones (usuario_id, tipo, titulo, cuerpo, inscripcion_id)
  values (v_ins.estudiante_id, 'solicitud_decidida',
          case when p_acepta then 'Tu cupo fue aceptado' else 'Tu solicitud fue rechazada' end,
          case when p_acepta then 'Ya formas parte de la nómina del turno.'
               else coalesce(nullif(trim(p_motivo), ''), 'El conductor no indicó un motivo.') end,
          p_inscripcion);

  return case when p_acepta then 'aceptada'::estado_inscripcion
              else 'rechazada'::estado_inscripcion end;
end;
$$;

-- Las demás transiciones siguen el mismo patrón y se detallan en el Cuadro de
-- funciones del documento: detalle_solicitud (el RLS de estudiantes no deja al
-- conductor leer domicilios ajenos; esta función se los entrega solo para
-- solicitudes de sus turnos), marcar_inasistencia, iniciar_viaje,
-- finalizar_viaje, enviar_contingencia, registrar_pago, anular_pago,
-- abrir_renovacion, renovar_cupo, vencer_renovaciones y buscar_turnos.

-- 6. Seguridad a nivel de fila --------------------------------------------------

alter table public.vehiculos           enable row level security;
alter table public.turnos              enable row level security;
alter table public.inscripciones       enable row level security;
alter table public.inasistencias       enable row level security;
alter table public.periodos_renovacion enable row level security;
alter table public.renovaciones        enable row level security;
alter table public.viajes              enable row level security;
alter table public.posiciones          enable row level security;
alter table public.avisos_contingencia enable row level security;
alter table public.pagos               enable row level security;
alter table public.notificaciones      enable row level security;
alter table public.dispositivos        enable row level security;

create policy vehiculos_los_gestiona_su_conductor on public.vehiculos
  for all using (conductor_id = auth.uid()) with check (conductor_id = auth.uid());
create policy vehiculos_los_lee_cualquier_usuario on public.vehiculos
  for select to authenticated using (true);

create policy turnos_los_gestiona_su_conductor on public.turnos
  for all using (conductor_id = auth.uid()) with check (conductor_id = auth.uid());
create policy turnos_activos_los_lee_cualquier_usuario on public.turnos
  for select to authenticated using (activo or public.es_admin());

create policy inscripciones_las_ven_sus_partes on public.inscripciones
  for select using (estudiante_id = auth.uid()
                    or public.es_conductor_del_turno(turno_id)
                    or public.es_admin());

create policy inasistencias_las_ven_sus_partes on public.inasistencias
  for select using (exists (
    select 1 from public.inscripciones i
     where i.id = inscripcion_id
       and (i.estudiante_id = auth.uid() or public.es_conductor_del_turno(i.turno_id))));

create policy periodos_los_gestiona_su_conductor on public.periodos_renovacion
  for all using (public.es_conductor_del_turno(turno_id))
  with check (public.es_conductor_del_turno(turno_id));
create policy periodos_los_ven_los_inscritos on public.periodos_renovacion
  for select using (public.esta_inscrito_en(turno_id));

create policy renovaciones_las_ven_sus_partes on public.renovaciones
  for select using (exists (
    select 1 from public.inscripciones i
     where i.id = inscripcion_id
       and (i.estudiante_id = auth.uid() or public.es_conductor_del_turno(i.turno_id))));

create policy viajes_los_ven_sus_partes on public.viajes
  for select using (public.es_conductor_del_turno(turno_id)
                    or public.esta_inscrito_en(turno_id)
                    or public.es_admin());

-- El conductor escribe posiciones solo de su viaje en curso.
create policy posiciones_las_escribe_el_conductor on public.posiciones
  for insert with check (exists (
    select 1 from public.viajes v
     where v.id = viaje_id and v.estado = 'en_curso'
       and public.es_conductor_del_turno(v.turno_id)));
create policy posiciones_las_ven_sus_partes on public.posiciones
  for select using (exists (
    select 1 from public.viajes v
     where v.id = viaje_id
       and (public.es_conductor_del_turno(v.turno_id) or public.esta_inscrito_en(v.turno_id))));

create policy avisos_los_ven_sus_partes on public.avisos_contingencia
  for select using (exists (
    select 1 from public.viajes v
     where v.id = viaje_id
       and (public.es_conductor_del_turno(v.turno_id) or public.esta_inscrito_en(v.turno_id))));

create policy pagos_los_ven_sus_partes on public.pagos
  for select using (exists (
    select 1 from public.inscripciones i
     where i.id = inscripcion_id
       and (i.estudiante_id = auth.uid() or public.es_conductor_del_turno(i.turno_id))));

create policy notificaciones_las_ve_su_destinatario on public.notificaciones
  for select using (usuario_id = auth.uid());
create policy notificaciones_las_marca_su_destinatario on public.notificaciones
  for update using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

create policy dispositivos_los_gestiona_su_dueno on public.dispositivos
  for all using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

-- Lo que cambia de estado solo se escribe a través de las funciones.
revoke insert, update, delete on
  public.inscripciones, public.inasistencias, public.renovaciones,
  public.viajes, public.avisos_contingencia, public.pagos
  from anon, authenticated;
revoke insert, delete on public.notificaciones from anon, authenticated;
revoke update on public.notificaciones from authenticated;
grant update (leida_en) on public.notificaciones to authenticated;
revoke all on
  public.vehiculos, public.turnos, public.inscripciones, public.inasistencias,
  public.periodos_renovacion, public.renovaciones, public.viajes,
  public.posiciones, public.avisos_contingencia, public.pagos,
  public.notificaciones, public.dispositivos
  from anon;

-- 7. Ajuste al trigger existente detectar_zona() ---------------------------------
-- Hoy toma cualquier zona que cubra el punto (limit 1 sin orden). Si dos
-- polígonos se solapan, el resultado no es determinista. Se propone elegir la
-- de menor área, que es la más específica.
create or replace function public.detectar_zona()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.domicilio is not null then
    select z.id into new.zona_id
      from public.zonas z
     where z.activa
       and st_covers(z.poligono, new.domicilio)
     order by st_area(z.poligono) asc
     limit 1;
    new.domicilio_fijado_en := now();
  end if;
  return new;
end;
$$;

-- 8. Realtime -----------------------------------------------------------------
-- La app escucha los cambios de estas tablas; el RLS filtra qué ve cada quien.
alter publication supabase_realtime
  add table public.inscripciones, public.posiciones, public.notificaciones;
