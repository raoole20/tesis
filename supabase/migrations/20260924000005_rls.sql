-- 20260924000005 · Políticas RLS
-- Corresponde al apartado 8.5 de docs/producto/modelo-de-datos.md
--
-- Cambio respecto del documento: se agregan las políticas de public.conductores,
-- que faltaban. Sin ellas, con RLS activo, el conductor no podía ni leer ni
-- escribir su propio perfil.

alter table public.usuarios        enable row level security;
alter table public.estudiantes     enable row level security;
alter table public.conductores     enable row level security;
alter table public.zonas           enable row level security;
alter table public.conductor_zonas enable row level security;

-- Saber si quien consulta es administrador, sin recursión.
--
-- security definer es lo que evita el bucle: una política sobre usuarios que
-- consulte usuarios para averiguar el rol entra en recursión infinita y
-- PostgreSQL la corta con un error. Al ser security definer, esta función
-- salta el RLS de la tabla y la consulta termina.
create or replace function public.es_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.usuarios
     where id = auth.uid() and rol = 'administrador'
  );
$$;

-- usuarios ------------------------------------------------------------------

create policy usuarios_ve_el_suyo on public.usuarios
  for select using (auth.uid() = id or public.es_admin());

create policy usuarios_edita_el_suyo on public.usuarios
  for update using (auth.uid() = id)
  with check (auth.uid() = id);

-- estudiantes ---------------------------------------------------------------

create policy estudiantes_ve_el_suyo on public.estudiantes
  for select using (auth.uid() = id or public.es_admin());

create policy estudiantes_edita_el_suyo on public.estudiantes
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- conductores ---------------------------------------------------------------

create policy conductores_ve_el_suyo on public.conductores
  for select using (auth.uid() = id or public.es_admin());

create policy conductores_edita_el_suyo on public.conductores
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- No hay política de insert ni de delete a propósito: la fila la crea el
-- trigger del registro y se borra en cascada con la cuenta.

-- conductor_zonas -----------------------------------------------------------

create policy conductor_zonas_las_suyas on public.conductor_zonas
  for all using (auth.uid() = conductor_id)
  with check (auth.uid() = conductor_id);

create policy conductor_zonas_las_ve_el_admin on public.conductor_zonas
  for select using (public.es_admin());

-- zonas ---------------------------------------------------------------------

create policy zonas_las_lee_cualquiera on public.zonas
  for select using (auth.role() = 'authenticated');

create policy zonas_las_escribe_el_admin on public.zonas
  for all using (public.es_admin()) with check (public.es_admin());
