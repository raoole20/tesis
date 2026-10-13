// Lanzador del servidor MCP de Supabase para Claude Code.
//
// Claude Code no lee archivos .env: la expansión ${VAR} de .mcp.json sale del
// entorno del proceso. Este script carga el .env de la raíz del repositorio y
// recién entonces arranca el servidor, así la credencial vive solo en .env
// (ignorado por git) y no hace falta copiarla al entorno de Windows.
//
// Variables que lee del .env:
//   SUPABASE_ACCESS_TOKEN  obligatoria · token personal de la cuenta
//   SUPABASE_PROJECT_REF   opcional    · limita el servidor a ese proyecto
//
// Las variables que ya estén en el entorno ganan sobre las del .env.

import { spawn } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const rutaEnv = join(raiz, '.env');

if (existsSync(rutaEnv)) {
  for (const linea of readFileSync(rutaEnv, 'utf8').split(/\r?\n/)) {
    const par = linea.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (!par) continue; // vacías y comentarios
    const [, nombre, crudo] = par;
    const valor = crudo.replace(/^(['"])(.*)\1$/, '$2');
    process.env[nombre] ??= valor;
  }
}

// Al stdout solo puede ir el protocolo MCP: los avisos van a stderr.
if (!process.env.SUPABASE_ACCESS_TOKEN) {
  console.error(
    'Falta SUPABASE_ACCESS_TOKEN en .env (ver .env.example y el Apéndice C de cupo/README.md).',
  );
  process.exit(1);
}

const ref = process.env.SUPABASE_PROJECT_REF;

// Con --project-ref el servidor solo ve el proyecto de la tesis, y el grupo
// `account` (listar y crear proyectos) se apaga solo: no hace falta pedirlo.
const args = [
  '-y',
  '@supabase/mcp-server-supabase@latest',
  ref
    ? '--features=database,debugging,development,docs'
    : '--features=account,database,debugging,development,docs',
  ...(ref ? [`--project-ref=${ref}`] : []),
];

// En Windows npx es un .cmd: se ejecuta a través de cmd.
const [comando, ...resto] =
  process.platform === 'win32' ? ['cmd', '/c', 'npx', ...args] : ['npx', ...args];
const hijo = spawn(comando, resto, { stdio: 'inherit', env: process.env });

hijo.on('exit', (codigo, senal) => {
  if (senal) process.kill(process.pid, senal);
  else process.exit(codigo ?? 0);
});

for (const senal of ['SIGINT', 'SIGTERM']) {
  process.on(senal, () => hijo.kill(senal));
}
