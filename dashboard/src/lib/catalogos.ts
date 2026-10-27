import {
  Ban, Bus, CircleCheck, CircleDashed, CircleQuestionMark, CircleX, Clock,
  GraduationCap, Monitor, ShieldCheck, Smartphone, Terminal,
} from '@lucide/astro';
import type { EstadoCuenta, Rol, TipoDispositivo } from './panel';

export const ROLES: Record<Rol, { nombre: string; plural: string; icono: typeof Bus }> = {
  estudiante: { nombre: 'Estudiante', plural: 'Estudiantes', icono: GraduationCap },
  conductor: { nombre: 'Conductor', plural: 'Conductores', icono: Bus },
  administrador: { nombre: 'Administrador', plural: 'Administradores', icono: ShieldCheck },
};

/**
 * Orden fijo: el color sigue al estado, nunca a su posición. `texto` es el
 * color del número cuando va dentro de la barra, elegido por contraste.
 */
export const ESTADOS: Record<EstadoCuenta, {
  nombre: string;
  icono: typeof Bus;
  color: string;
  texto: string;
}> = {
  aprobada: { nombre: 'Aprobada', icono: CircleCheck, color: 'var(--success)', texto: 'var(--ink)' },
  pendiente: { nombre: 'Pendiente', icono: Clock, color: 'var(--warning)', texto: 'var(--ink)' },
  perfil_incompleto: { nombre: 'Perfil incompleto', icono: CircleDashed, color: 'var(--text-support-soft)', texto: 'var(--ink)' },
  rechazada: { nombre: 'Rechazada', icono: CircleX, color: 'var(--danger)', texto: 'var(--surface)' },
  suspendida: { nombre: 'Suspendida', icono: Ban, color: 'var(--ink)', texto: 'var(--surface)' },
};

export const ORDEN_ESTADOS = Object.keys(ESTADOS) as EstadoCuenta[];

export const DISPOSITIVOS: Record<TipoDispositivo, typeof Bus> = {
  movil: Smartphone,
  escritorio: Monitor,
  otro: Terminal,
  desconocido: CircleQuestionMark,
};
