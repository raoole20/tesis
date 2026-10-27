import { defineMiddleware } from 'astro:middleware';
import { crearSupabase } from './lib/supabase';

const PUBLICAS = new Set(['/login']);

/**
 * Toda ruta pide sesión salvo /login. Ser administrador no se comprueba aquí
 * sino en la base: panel_admin() lo exige y la portada cierra la sesión si la
 * base dice que no (ver pages/index.astro).
 */
export const onRequest = defineMiddleware(async (ctx, next) => {
  // Archivos estáticos: no hay nada que proteger.
  if (/\.[a-z0-9]+$/i.test(ctx.url.pathname)) return next();

  const supabase = crearSupabase(ctx.request, ctx.cookies);
  // getUser() valida el token contra Auth; getSession() solo lee la cookie.
  const { data } = await supabase.auth.getUser();

  ctx.locals.supabase = supabase;
  ctx.locals.usuario = data.user;

  const publica = PUBLICAS.has(ctx.url.pathname);
  if (!data.user && !publica) return ctx.redirect('/login');
  if (data.user && publica && ctx.request.method === 'GET') return ctx.redirect('/');

  return next();
});
