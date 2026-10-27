// Datos del panel: la forma que devuelve panel_admin() y los cálculos que se
// hacen sobre ella. Ver supabase/migrations/20261025000001_panel_admin.sql.

import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js';
import {
  claveDe, diaCorto, diaLargo, diasEntre, inicioDeClave, lunesDe, sumarDias,
} from './formato';

export type Rol = 'estudiante' | 'conductor' | 'administrador';
export type EstadoCuenta = 'perfil_incompleto' | 'pendiente' | 'aprobada' | 'rechazada' | 'suspendida';

export interface Usuario {
  id: string;
  email: string;
  nombres: string;
  apellidos: string;
  rol: Rol;
  estado: EstadoCuenta;
  onboarding_completo: boolean;
  creado_en: string;
  ultimo_login: string | null;
  email_confirmado: boolean;
  sesiones_abiertas: number;
  domicilio_fijado: boolean;
  zona: string | null;
  zonas_cubiertas: number;
  verificado: boolean | null;
}

export interface Acceso {
  usuario_id: string;
  ocurrido_en: string;
  user_agent: string | null;
}

export interface Zona {
  id: string;
  nombre: string;
  municipio: string | null;
  activa: boolean;
  estudiantes: number;
  conductores: number;
}

interface PanelCrudo {
  generado_en: string;
  usuarios: Usuario[];
  accesos: Acceso[];
  zonas: Zona[];
  estudiantes_sin_zona: number;
}

export interface AccesoConUsuario extends Acceso {
  usuario: Usuario;
}

export interface Panel extends PanelCrudo {
  /** Estudiantes y conductores: la actividad no cuenta a los administradores. */
  app: Usuario[];
  accesosApp: AccesoConUsuario[];
}

// === Rango ===============================================================

export const RANGOS = [7, 30, 90, 0] as const;
export type Rango = (typeof RANGOS)[number];

export function leerRango(valor: string | null): Rango {
  const n = Number(valor);
  return valor !== null && (RANGOS as readonly number[]).includes(n) ? (n as Rango) : 30;
}

export const nombreRango = (r: Rango) => (r ? `${r} días` : 'Todo');

/** Desde cuándo pedir la bitácora: el período y el anterior, para comparar. */
function desdeParaConsulta(dias: Rango): string | null {
  if (!dias) return null;
  return inicioDeClave(sumarDias(claveDe(Date.now()), -(2 * dias - 1))).toISOString();
}

// === Carga ===============================================================

export async function cargarPanel(
  supabase: SupabaseClient,
  dias: Rango,
): Promise<{ panel: Panel; error: null } | { panel: null; error: PostgrestError }> {
  const { data, error } = await supabase.rpc('panel_admin', { desde: desdeParaConsulta(dias) });
  if (error) return { panel: null, error };

  const crudo = data as PanelCrudo;
  const porId = new Map(crudo.usuarios.map((u) => [u.id, u]));
  const accesosApp: AccesoConUsuario[] = [];
  for (const a of crudo.accesos) {
    const usuario = porId.get(a.usuario_id);
    if (usuario && usuario.rol !== 'administrador') accesosApp.push({ ...a, usuario });
  }
  return {
    panel: { ...crudo, app: crudo.usuarios.filter((u) => u.rol !== 'administrador'), accesosApp },
    error: null,
  };
}

// === Períodos y series ===================================================

export interface Periodo {
  inicio: string;
  fin: string;
  /** Inicio del período anterior de igual largo; null en «Todo». */
  previo: string | null;
  largo: number;
}

export function periodo(panel: Panel, dias: Rango): Periodo {
  const hoy = claveDe(Date.now());
  if (dias) {
    const inicio = sumarDias(hoy, -(dias - 1));
    return { inicio, fin: hoy, previo: sumarDias(inicio, -dias), largo: dias };
  }
  const claves = [
    ...panel.app.map((u) => u.creado_en),
    ...panel.accesosApp.map((a) => a.ocurrido_en),
  ].map(claveDe);
  const inicio = claves.length ? claves.reduce((a, b) => (a < b ? a : b)) : hoy;
  return { inicio, fin: hoy, previo: null, largo: diasEntre(inicio, hoy) + 1 };
}

export const enPeriodo = (f: string, p: Periodo) => {
  const c = claveDe(f);
  return c >= p.inicio && c <= p.fin;
};

export const enPrevio = (f: string, p: Periodo) => {
  if (!p.previo) return false;
  const c = claveDe(f);
  return c >= p.previo && c < p.inicio;
};

export interface Cubeta {
  clave: string;
  valor: number;
  corta: string;
  larga: string;
}

/** Cuenta fechas por día, o por semana si el período pasa de 120 días. */
export function serie(fechas: string[], p: Periodo): Cubeta[] {
  const semanal = p.largo > 120;
  const lista: Cubeta[] = [];
  for (let c = semanal ? lunesDe(p.inicio) : p.inicio; c <= p.fin; c = sumarDias(c, semanal ? 7 : 1)) {
    lista.push({
      clave: c,
      valor: 0,
      corta: diaCorto(c),
      larga: semanal ? `Semana del ${diaCorto(c)}` : diaLargo(c),
    });
  }
  const indice = new Map(lista.map((b, i) => [b.clave, i]));
  for (const f of fechas) {
    let c = claveDe(f);
    if (c < p.inicio || c > p.fin) continue;
    if (semanal) c = lunesDe(c);
    const i = indice.get(c);
    if (i !== undefined) lista[i].valor++;
  }
  return lista;
}

// === Usuarios ============================================================

export const nombreDe = (u: Usuario) => [u.nombres, u.apellidos].filter(Boolean).join(' ').trim();

export function detalleDe(u: Usuario) {
  if (u.rol === 'estudiante') {
    if (!u.domicilio_fijado) return 'Sin domicilio';
    return u.zona ? `Zona ${u.zona}` : 'Fuera de toda zona';
  }
  if (u.rol === 'conductor') {
    const z = `${u.zonas_cubiertas} ${u.zonas_cubiertas === 1 ? 'zona' : 'zonas'} de trabajo`;
    return u.verificado ? `${z} · verificado` : z;
  }
  return '—';
}

export type TipoDispositivo = 'movil' | 'escritorio' | 'otro' | 'desconocido';

/** Lectura gruesa del user agent de la sesión. */
export function dispositivo(ua: string | null): { tipo: TipoDispositivo; texto: string } {
  if (!ua) return { tipo: 'desconocido', texto: 'Sin datos' };
  if (/^Dart\//.test(ua)) return { tipo: 'movil', texto: 'App móvil' };
  const nav = /Edg\//.test(ua) ? 'Edge' : /Firefox\//.test(ua) ? 'Firefox'
    : /Chrome\//.test(ua) ? 'Chrome' : /Safari\//.test(ua) ? 'Safari' : null;
  const so = /Android/.test(ua) ? 'Android' : /iPhone|iPad/.test(ua) ? 'iOS'
    : /Windows/.test(ua) ? 'Windows' : /Mac OS/.test(ua) ? 'macOS'
    : /Linux/.test(ua) ? 'Linux' : null;
  if (!nav && !so) return { tipo: 'otro', texto: 'Otro cliente' };
  const movil = so === 'Android' || so === 'iOS';
  return { tipo: movil ? 'movil' : 'escritorio', texto: [nav, so].filter(Boolean).join(' · ') };
}
