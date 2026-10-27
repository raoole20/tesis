# Panel de administración de Cupo

Panel web para ver los inicios de sesión, los registros y el estado general de
la app: usuarios por rol y estado, embudo de alta, sesiones abiertas y zonas.

Hecho con [Astro](https://astro.build) en modo servidor. Todo se pinta en el
servidor: el navegador recibe HTML listo y un script mínimo para los tooltips.

## Cómo levantarlo

```bash
cd dashboard
cp .env.example .env   # y llena los dos valores (ver abajo)
npm install
npm run dev            # http://localhost:4321
```

Para producción: `npm run build` y luego `npm start`, que corre el servidor de
Node leyendo el `.env`.

`.env` lleva la URL del proyecto y la clave **anon** (las mismas de
`cupo/dart_define.json`). Nunca la `service_role`.

## Quién puede entrar

Solo cuentas con `rol = 'administrador'`. La app nunca concede ese rol (ver el
trigger `crear_usuario`), así que se marca a mano. Para promover una cuenta
existente, en el SQL Editor de Supabase:

```sql
update public.usuarios
   set rol = 'administrador', estado = 'aprobada', onboarding_completo = true
 where email = 'correo@ejemplo.com';
delete from public.estudiantes where id = (select id from public.usuarios where email = 'correo@ejemplo.com');
delete from public.conductores where id = (select id from public.usuarios where email = 'correo@ejemplo.com');
```

Si una cuenta que no es administradora inicia sesión, el panel la saca con
«Esta cuenta no tiene permisos de administrador».

## De dónde salen los datos

Todo viene de una sola función, `public.panel_admin(desde)`, definida en
[`supabase/migrations/20261025000001_panel_admin.sql`](../supabase/migrations/20261025000001_panel_admin.sql).
Es `security definer` porque lee `auth.users` y `auth.sessions`, y lo primero
que hace es exigir `es_admin()`.

- **Inicios de sesión**: la tabla `public.accesos`, que llena un trigger sobre
  `auth.sessions` (cada login crea una sesión). La bitácora empezó el
  25-10-2026; de antes solo quedaron las sesiones abiertas y el último login de
  cada usuario, que se cargaron como punto de partida. Esos aparecen con
  dispositivo «Sin datos».
- **Registros**: `usuarios.creado_en`.
- **Último login**: `auth.users.last_sign_in_at`.
- La sección *Actividad* no cuenta a los administradores.
- Los días se cuentan en hora de Caracas.

## Estructura

```
src/
├── middleware.ts      sesión obligatoria salvo en /login
├── lib/
│   ├── supabase.ts    cliente de Supabase atado a las cookies
│   ├── panel.ts       tipos de panel_admin() y cálculos (períodos, series)
│   ├── formato.ts     fechas y números en es-VE
│   └── catalogos.ts   roles y estados con su icono y color
├── components/        KPIs, gráficos, tablas
├── layouts/Base.astro HTML base, fuentes y tooltip compartido
├── styles/global.css  tokens de color copiados de cupo/lib/theme
└── pages/             index (panel), login, salir
```

La identidad visual sigue el `CLAUDE.md` de la raíz: Teko para títulos y
botones, Manrope para el resto, Caveat solo en el logotipo, verde lago como
acento e iconos Lucide (`@lucide/astro`).

## Comprobar

```bash
npm run check   # tipos de .astro y .ts
npm run build
```
