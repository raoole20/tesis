-- 20261027000001 · Vehículos del conductor (HU-004)
-- Corresponde a la tabla `vehiculos` del diseño físico de la Fase II
-- (docs/tesis/fase-2/esquema-operacion.sql, Cuadro 56).
--
-- Dos cambios respecto del diseño:
--
--   1. La lectura queda en el propio conductor y el administrador. El diseño
--      abría los vehículos a cualquier usuario autenticado para la búsqueda;
--      eso se decide con HU-007, que podrá exponer solo lo necesario por RPC.
--
--   2. enviar_a_revision() pasa a exigir al menos un vehículo registrado,
--      como pide el criterio de aceptación de HU-004.

create table public.vehiculos (
  id           uuid primary key default gen_random_uuid(),
  -- El default hace que la app no tenga que mandarlo, y el grant de abajo
  -- impide cambiarlo después: un vehículo no se le pasa a otro conductor.
  conductor_id uuid not null default auth.uid()
                 references public.conductores (id) on delete cascade,
  -- Normalizada por la app: mayúsculas, sin espacios ni guiones (AB123CD).
  placa        text not null unique check (placa ~ '^[A-Z0-9]{6,7}$'),
  marca        text not null check (length(trim(marca)) > 0),
  modelo       text not null check (length(trim(modelo)) > 0),
  anio         smallint check (anio between 1970 and 2100),
  color        text not null check (length(trim(color)) > 0),
  capacidad    smallint not null check (capacidad >= 1),
  url_foto     text,
  creado_en    timestamptz not null default now()
);

create index vehiculos_conductor_idx on public.vehiculos (conductor_id);

-- RLS ------------------------------------------------------------------------

alter table public.vehiculos enable row level security;

-- La FK a conductores ya garantiza que solo un conductor tenga vehículos.
create policy vehiculos_los_gestiona_su_conductor on public.vehiculos
  for all using (conductor_id = auth.uid())
  with check (conductor_id = auth.uid());

create policy vehiculos_los_ve_el_admin on public.vehiculos
  for select using (public.es_admin());

-- Privilegios ------------------------------------------------------------------

revoke all on public.vehiculos from anon;
revoke update on public.vehiculos from authenticated;
grant select, insert, delete on public.vehiculos to authenticated;
grant update (placa, marca, modelo, anio, color, capacidad, url_foto)
  on public.vehiculos to authenticated;

-- enviar_a_revision() ------------------------------------------------------------
-- Igual a la de 20260924000007, más la exigencia del vehículo.

create or replace function public.enviar_a_revision()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  u public.usuarios%rowtype;
begin
  select * into u from public.usuarios where id = auth.uid();

  if not found then
    raise exception 'No hay usuario para la sesión actual';
  end if;

  if u.estado not in ('perfil_incompleto', 'rechazada') then
    raise exception 'La cuenta está en estado %, no se puede enviar a revisión',
      u.estado;
  end if;

  -- Datos comunes a los dos roles.
  if coalesce(u.nombres, '') = '' or coalesce(u.apellidos, '') = ''
     or coalesce(u.cedula, '') = '' or coalesce(u.telefono, '') = '' then
    raise exception 'Faltan datos personales: nombres, apellidos, cédula y teléfono';
  end if;

  -- Datos propios del rol.
  if u.rol = 'conductor' then
    if not exists (
      select 1 from public.conductores c
       where c.id = u.id
         and coalesce(c.licencia_numero, '') <> ''
         and c.licencia_vence_en is not null
    ) then
      raise exception 'Faltan los datos de la licencia';
    end if;

    if not exists (select 1 from public.vehiculos v where v.conductor_id = u.id) then
      raise exception 'Falta registrar tu vehículo';
    end if;
  end if;

  update public.usuarios
     set estado = 'pendiente',
         motivo_rechazo = null   -- se limpia el motivo anterior al reenviar
   where id = u.id;
end;
$$;
