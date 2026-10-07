-- 20260924000007 · Funciones que mueven el estado de la cuenta
--
-- No está en el documento, y hace falta. El archivo anterior revocó el update
-- sobre usuarios.estado y usuarios.onboarding_completo — correcto, porque si
-- no cualquiera se autoaprobaría. Pero entonces NADIE puede pasar de
-- 'perfil_incompleto' a 'pendiente', y el registro queda trancado.
--
-- La salida son funciones security definer: el usuario no escribe la columna,
-- invoca una transición que valida sus condiciones. El diagrama de estados del
-- apartado 4 queda expresado como código, no como confianza.

-- Enviar el perfil a revisión: perfil_incompleto | rechazada -> pendiente.
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
  end if;

  update public.usuarios
     set estado = 'pendiente',
         motivo_rechazo = null   -- se limpia el motivo anterior al reenviar
   where id = u.id;
end;
$$;

-- Cerrar el onboarding: solo si el paso de ubicación del rol ya está hecho.
create or replace function public.completar_onboarding()
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

  if u.estado <> 'aprobada' then
    raise exception 'La cuenta todavía no está aprobada';
  end if;

  if u.rol = 'conductor' then
    if not exists (
      select 1 from public.conductor_zonas where conductor_id = u.id
    ) then
      raise exception 'Hay que elegir al menos una zona de trabajo';
    end if;
  elsif u.rol = 'estudiante' then
    -- Basta con que el pin exista. zona_id puede ser null: el domicilio fuera
    -- de toda zona no tranca el registro (apartado 3.4).
    if not exists (
      select 1 from public.estudiantes
       where id = u.id and domicilio is not null
    ) then
      raise exception 'Falta fijar el domicilio en el mapa';
    end if;
  end if;

  update public.usuarios set onboarding_completo = true where id = u.id;
end;
$$;

-- Sello de último acceso. La app lo llama después de cada login.
create or replace function public.registrar_acceso()
returns void
language sql
security definer
set search_path = public
as $$
  update public.usuarios set ultimo_acceso = now() where id = auth.uid();
$$;

grant execute on function public.enviar_a_revision()    to authenticated;
grant execute on function public.completar_onboarding() to authenticated;
grant execute on function public.registrar_acceso()     to authenticated;
