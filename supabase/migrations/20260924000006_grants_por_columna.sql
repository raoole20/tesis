-- 20260924000006 · Privilegios por columna
-- Corresponde al apartado 8.6 de docs/producto/modelo-de-datos.md
--
-- Es la regla más importante del módulo. Una política RLS decide QUÉ FILAS se
-- tocan, no QUÉ COLUMNAS. Con solo el RLS del archivo anterior, un usuario
-- puede actualizar su propia fila... incluyendo rol = 'administrador'. Eso
-- tumba el control de acceso entero.
--
-- Los privilegios por columna son de PostgreSQL, no de Supabase, y son lo que
-- cierra el hueco.

revoke update on public.usuarios from authenticated;

grant update (nombres, apellidos, telefono, cedula, url_foto)
  on public.usuarios to authenticated;

-- rol, estado, onboarding_completo y motivo_rechazo quedan fuera de la lista:
-- los cambia el administrador o una función security definer (archivo 07).

revoke update on public.conductores from authenticated;

grant update (
  licencia_numero, licencia_vence_en,
  certificado_medico, certificado_vence_en
) on public.conductores to authenticated;

-- 'verificado' lo marca el administrador, no el conductor.

revoke update on public.estudiantes from authenticated;

grant update (
  universidad, carrera, carnet,
  domicilio, domicilio_direccion, domicilio_referencia
) on public.estudiantes to authenticated;

-- zona_id y domicilio_fijado_en los escribe el trigger detectar_zona(), no la
-- app: si el estudiante pudiera escribir zona_id, podría declararse en una
-- zona donde no vive.
