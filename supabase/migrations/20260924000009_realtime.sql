-- 20260924000009 · Realtime sobre public.usuarios
--
-- El apartado 5 del modelo pide que la app escuche su propia fila: si el
-- administrador suspende la cuenta mientras la persona la tiene abierta, la
-- app debe enterarse. Eso no funciona solo: la tabla tiene que estar en la
-- publicación que Supabase Realtime lee.

alter publication supabase_realtime add table public.usuarios;

-- Sin replica identity full, un UPDATE llega sin las columnas que no cambiaron
-- y el filtro por id del lado del cliente no encuentra a quién aplicar el
-- evento.
alter table public.usuarios replica identity full;

-- El RLS sigue mandando: por el canal de Realtime solo viajan las filas que la
-- política usuarios_ve_el_suyo deja ver. Nadie recibe eventos de otra cuenta.
