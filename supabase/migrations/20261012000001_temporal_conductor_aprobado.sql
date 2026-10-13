-- 20261012000001 · TEMPORAL: el conductor nace aprobado
--
-- ⚠️ Solo para desarrollo. Todavía no existen ni el formulario del perfil del
-- conductor (licencia y certificado) ni la bandeja del administrador, así que
-- un conductor nuevo se quedaba en 'perfil_incompleto' y no había forma de
-- llegar a «Tus zonas de trabajo» sin un UPDATE a mano.
--
-- Va en un trigger propio, y no dentro de crear_usuario(), para que quitarlo
-- no toque el alta: cuando exista la revisión, se revierte con
--
--   drop trigger usuarios_conductor_aprobado_temporal on public.usuarios;
--   drop function public.aprobar_conductor_temporal();
--
-- Los conductores que ya se aprobaron así seguirán aprobados: habrá que
-- devolverlos a 'perfil_incompleto' si se quiere que pasen por la revisión.

create or replace function public.aprobar_conductor_temporal()
returns trigger
language plpgsql
as $$
begin
  if new.rol = 'conductor' then
    new.estado := 'aprobada';
  end if;
  return new;
end;
$$;

-- BEFORE INSERT: cambia la fila que inserta crear_usuario() antes de que se
-- escriba. El estudiante no se toca: su perfil sí existe.
create trigger usuarios_conductor_aprobado_temporal
  before insert on public.usuarios
  for each row execute function public.aprobar_conductor_temporal();

-- Los conductores de prueba ya creados que esperaban perfil o revisión.
-- Los rechazados y suspendidos se dejan como están.
update public.usuarios
   set estado = 'aprobada'
 where rol = 'conductor'
   and estado in ('perfil_incompleto', 'pendiente');
