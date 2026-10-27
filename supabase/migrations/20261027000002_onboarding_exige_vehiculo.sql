-- 20261027000002 · El onboarding del conductor exige vehículo (HU-004)
--
-- El onboarding del conductor ahora tiene dos pasos en la app: «Tu vehículo»
-- y «Tus zonas». Esta función los hace cumplir del lado que no se puede
-- saltar. Igual a la de 20260924000007, más la exigencia del vehículo.
--
-- Los conductores que ya completaron el onboarding sin vehículo no se tocan:
-- la función solo corre al completarlo. La app les pide registrarlo desde el
-- inicio y desde «Tu cuenta».

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
    if not exists (select 1 from public.vehiculos where conductor_id = u.id) then
      raise exception 'Falta registrar tu vehículo';
    end if;
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
