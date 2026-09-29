-- 20260924000004 · Trigger: detectar la zona del domicilio
-- Corresponde al apartado 8.4 de docs/producto/modelo-de-datos.md
--
-- El punto-en-polígono lo corre la base de datos sola. La app solo escribe el
-- punto; zona_id se llena aquí y no puede quedar inconsistente con él.

create or replace function public.detectar_zona()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.domicilio is not null then
    select z.id into new.zona_id
      from public.zonas z
     where z.activa
       and st_covers(z.poligono, new.domicilio)
     limit 1;

    new.domicilio_fijado_en := now();
  end if;
  return new;
end;
$$;

-- BEFORE, no AFTER: así se modifica NEW antes de escribir la fila y no hace
-- falta un segundo UPDATE.
create trigger estudiantes_detectar_zona
  before insert or update of domicilio on public.estudiantes
  for each row execute function public.detectar_zona();
