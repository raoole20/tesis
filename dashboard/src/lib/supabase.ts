import { createServerClient, parseCookieHeader } from '@supabase/ssr';
import type { AstroCookies, AstroCookieSetOptions } from 'astro';
import { SUPABASE_ANON_KEY, SUPABASE_URL } from 'astro:env/server';

/**
 * Cliente de Supabase atado a la petición: lee la sesión de las cookies y, si
 * el token se renueva, la vuelve a escribir en la respuesta.
 *
 * Las cookies van httpOnly porque ningún código del navegador las necesita:
 * todas las llamadas a Supabase salen del servidor.
 */
export function crearSupabase(request: Request, cookies: AstroCookies) {
  return createServerClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    cookies: {
      getAll: () =>
        parseCookieHeader(request.headers.get('cookie') ?? '').map(({ name, value }) => ({
          name,
          value: value ?? '',
        })),
      setAll: (lista) => {
        for (const { name, value, options } of lista) {
          cookies.set(name, value, { ...(options as AstroCookieSetOptions), httpOnly: true });
        }
      },
    },
  });
}
