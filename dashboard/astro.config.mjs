// @ts-check
import { defineConfig, envField } from 'astro/config';
import node from '@astrojs/node';

// Todo se pinta en el servidor: la sesión vive en una cookie y el navegador
// recibe HTML listo, más un script mínimo para los tooltips.
export default defineConfig({
  output: 'server',
  adapter: node({ mode: 'standalone' }),
  devToolbar: { enabled: false },
  env: {
    schema: {
      SUPABASE_URL: envField.string({ context: 'server', access: 'public', url: true }),
      SUPABASE_ANON_KEY: envField.string({ context: 'server', access: 'secret' }),
    },
  },
});
