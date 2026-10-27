-- 20261025000001 · Panel de administración (dashboard/)
--
-- Dos piezas:
--
--   1. public.accesos, la bitácora de inicios de sesión. Hasta ahora solo
--      quedaba el último (usuarios.ultimo_acceso y auth.users.last_sign_in_at):
--      auth.sessions se borra al cerrar sesión y el audit log de Auth llega
--      vacío a la base. La llena un trigger sobre auth.sessions —cada inicio de
--      sesión crea exactamente una fila ahí—, así que cuenta los accesos de
--      cualquier cliente, no solo los de la app que llaman registrar_acceso().
--
--   2. public.panel_admin(), la única lectura del panel. Es security definer
--      porque necesita datos de auth.*, que ningún rol de la API puede leer, y
--      por eso mismo lo primero que hace es exigir es_admin().

-- accesos -------------------------------------------------------------------

create table public.accesos (
  id          bigint generated always as identity primary key,
  usuario_id  uuid not null references public.usuarios (id) on delete cascade,
  ocurrido_en timestamptz not null default now(),
  user_agent  text
);

create index accesos_ocurrido_en_idx on public.accesos (ocurrido_en desc);
create index accesos_usuario_idx     on public.accesos (usuario_id);

alter table public.accesos enable row level security;

create policy accesos_los_ve_el_admin on public.accesos
  for select using (public.es_admin());

-- Nadie escribe la bitácora desde la API: solo el trigger de abajo.
revoke insert, update, delete on public.accesos from anon, authenticated;

create or replace function public.registrar_sesion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  begin
    insert into public.accesos (usuario_id, ocurrido_en, user_agent)
    values (new.user_id, coalesce(new.created_at, now()), new.user_agent);
  exception when others then
    -- Que la bitácora falle nunca debe impedir entrar.
    null;
  end;
  return new;
end;
$$;

create trigger on_auth_session_created
  after insert on auth.sessions
  for each row execute function public.registrar_sesion();

-- Lo que ya había: las sesiones abiertas y, de quien no tenga una cerca de su
-- último inicio de sesión, ese último inicio. Lo anterior se perdió.
insert into public.accesos (usuario_id, ocurrido_en, user_agent)
select s.user_id, s.created_at, s.user_agent
  from auth.sessions s
  join public.usuarios u on u.id = s.user_id;

insert into public.accesos (usuario_id, ocurrido_en)
select au.id, au.last_sign_in_at
  from auth.users au
  join public.usuarios u on u.id = au.id
 where au.last_sign_in_at is not null
   and not exists (
     select 1 from public.accesos a
      where a.usuario_id = au.id
        and abs(extract(epoch from a.ocurrido_en - au.last_sign_in_at)) < 60
   );

-- panel_admin ---------------------------------------------------------------

-- Devuelve todo lo que pinta el panel en un solo viaje. Los agregados por día
-- los hace el navegador: así cambiar el rango no vuelve a pedir usuarios ni
-- zonas. 'desde' recorta solo la bitácora, que es lo único que crece sin tope.
create or replace function public.panel_admin(desde timestamptz default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.es_admin() then
    raise exception 'Solo un administrador puede ver el panel'
      using errcode = '42501';
  end if;

  return jsonb_build_object(
    'generado_en', now(),

    'usuarios', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id',                  u.id,
               'email',               u.email,
               'nombres',             u.nombres,
               'apellidos',           u.apellidos,
               'rol',                 u.rol,
               'estado',              u.estado,
               'onboarding_completo', u.onboarding_completo,
               'creado_en',           u.creado_en,
               'ultimo_login',        au.last_sign_in_at,
               'email_confirmado',    au.email_confirmed_at is not null,
               'sesiones_abiertas',   (select count(*) from auth.sessions s
                                        where s.user_id = u.id),
               'domicilio_fijado',    e.domicilio is not null,
               'zona',                ze.nombre,
               'zonas_cubiertas',     (select count(*) from conductor_zonas cz
                                        where cz.conductor_id = u.id),
               'verificado',          c.verificado
             ) order by u.creado_en desc)
        from usuarios u
        join auth.users au      on au.id = u.id
        left join estudiantes e on e.id  = u.id
        left join zonas ze      on ze.id = e.zona_id
        left join conductores c on c.id  = u.id
    ), '[]'::jsonb),

    'accesos', coalesce((
      select jsonb_agg(jsonb_build_object(
               'usuario_id',  a.usuario_id,
               'ocurrido_en', a.ocurrido_en,
               'user_agent',  a.user_agent
             ) order by a.ocurrido_en desc)
        from (
          select * from accesos
           where desde is null or ocurrido_en >= desde
           order by ocurrido_en desc
           limit 5000
        ) a
    ), '[]'::jsonb),

    'zonas', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id',          z.id,
               'nombre',      z.nombre,
               'municipio',   z.municipio,
               'activa',      z.activa,
               'estudiantes', (select count(*) from estudiantes e
                                where e.zona_id = z.id),
               'conductores', (select count(*) from conductor_zonas cz
                                where cz.zona_id = z.id)
             ) order by z.nombre)
        from zonas z
    ), '[]'::jsonb),

    'estudiantes_sin_zona', (
      select count(*) from estudiantes
       where domicilio is not null and zona_id is null
    )
  );
end;
$$;

revoke execute on function public.panel_admin(timestamptz) from public, anon;
grant  execute on function public.panel_admin(timestamptz) to authenticated;

-- El trigger no se invoca por la API, pero por si acaso. PUBLIC se deja: es
-- por donde lo ejecuta supabase_auth_admin, y sin él no entra nadie.
revoke execute on function public.registrar_sesion() from anon, authenticated;
