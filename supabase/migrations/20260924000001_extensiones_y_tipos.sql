-- 20260924000001 · Extensiones y tipos enumerados
-- Corresponde al apartado 8.1 de docs/producto/modelo-de-datos.md

-- PostGIS: geografía sobre el elipsoide. Se usa para el domicilio del
-- estudiante (Point) y el polígono de cada zona (Polygon).
create extension if not exists postgis;

-- gen_random_uuid() para las claves que no vienen de Supabase Auth.
create extension if not exists pgcrypto;

-- Los tres roles del sistema. Al ser un enum, el motor rechaza cualquier
-- valor fuera de la lista: no hay forma de escribir 'conducotr' por error.
create type rol_usuario as enum (
  'estudiante', 'conductor', 'administrador'
);

-- El estado que gobierna el login entero (apartado 4 del modelo).
create type estado_cuenta as enum (
  'perfil_incompleto', 'pendiente', 'aprobada', 'rechazada', 'suspendida'
);
