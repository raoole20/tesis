-- 20260924000003 · Trigger: crear el perfil al registrarse
-- Corresponde al apartado 8.3 de docs/producto/modelo-de-datos.md
--
-- Dos cambios respecto del documento:
--
--   1. El rol se valida. El documento ya advierte el hueco: el rol viaja en
--      raw_user_meta_data, que lo controla el usuario, así que cualquiera
--      podría registrarse como 'administrador'. Aquí solo se aceptan los dos
--      roles de autoservicio; cualquier otro valor cae a 'estudiante'.
--
--   2. Se crea también la fila del subtipo. El documento solo insertaba en
--      usuarios, y sin la fila de conductores no hay a qué apuntar desde
--      conductor_zonas (su llave foránea es conductores.id).

create or replace function public.crear_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  rol_pedido text;
  rol_final  rol_usuario;
begin
  rol_pedido := new.raw_user_meta_data ->> 'rol';

  -- Lista blanca explícita. 'administrador' no se concede nunca por esta vía:
  -- esa cuenta la crea otro administrador o se marca a mano en la base.
  if rol_pedido in ('estudiante', 'conductor') then
    rol_final := rol_pedido::rol_usuario;
  else
    rol_final := 'estudiante';
  end if;

  insert into public.usuarios (id, email, rol, nombres, apellidos, telefono)
  values (
    new.id,
    new.email,
    rol_final,
    coalesce(new.raw_user_meta_data ->> 'nombres', ''),
    coalesce(new.raw_user_meta_data ->> 'apellidos', ''),
    nullif(new.raw_user_meta_data ->> 'telefono', '')
  );

  -- La fila del subtipo nace vacía y la llena el formulario de perfil.
  if rol_final = 'conductor' then
    insert into public.conductores (id) values (new.id);
  else
    insert into public.estudiantes (id) values (new.id);
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.crear_usuario();
