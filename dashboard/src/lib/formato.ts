// Fechas y números en es-VE. Los días se cuentan en hora de Caracas, sin
// importar dónde corra el servidor.

export const ZONA = 'America/Caracas';
const DIA = 86_400_000;

const fmtClave = new Intl.DateTimeFormat('en-CA', {
  timeZone: ZONA, year: 'numeric', month: '2-digit', day: '2-digit',
});
const fmtNumero = new Intl.NumberFormat('es-VE');
const fmtFecha = new Intl.DateTimeFormat('es-VE', {
  timeZone: ZONA, day: 'numeric', month: 'short', year: 'numeric',
});
const fmtFechaHora = new Intl.DateTimeFormat('es-VE', {
  timeZone: ZONA, day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit',
});
const fmtHora = new Intl.DateTimeFormat('es-VE', {
  timeZone: ZONA, hour: 'numeric', minute: '2-digit',
});
// Las claves de día se formatean en UTC a mediodía: así ningún huso las corre.
const fmtDiaCorto = new Intl.DateTimeFormat('es-VE', {
  timeZone: 'UTC', day: 'numeric', month: 'short',
});
const fmtDiaLargo = new Intl.DateTimeFormat('es-VE', {
  timeZone: 'UTC', weekday: 'long', day: 'numeric', month: 'long',
});
const fmtRelativo = new Intl.RelativeTimeFormat('es', { numeric: 'auto' });

type Instante = string | number | Date;

/** 'YYYY-MM-DD' del instante, en hora de Caracas. */
export const claveDe = (f: Instante) => fmtClave.format(new Date(f));
export const fechaDeClave = (clave: string) => new Date(`${clave}T12:00:00Z`);
export const sumarDias = (clave: string, n: number) =>
  new Date(fechaDeClave(clave).getTime() + n * DIA).toISOString().slice(0, 10);
/** Medianoche de ese día en Caracas, que es UTC−4 todo el año. */
export const inicioDeClave = (clave: string) => new Date(`${clave}T00:00:00-04:00`);
export const lunesDe = (clave: string) =>
  sumarDias(clave, -((fechaDeClave(clave).getUTCDay() + 6) % 7));
export const diasEntre = (desde: string, hasta: string) =>
  Math.round((fechaDeClave(hasta).getTime() - fechaDeClave(desde).getTime()) / DIA);

export const numero = (n: number) => fmtNumero.format(n);
export const plural = (n: number, uno: string, varios: string) =>
  `${numero(n)} ${n === 1 ? uno : varios}`;
export const porcentaje = (parte: number, total: number) =>
  total ? Math.round((parte / total) * 100) : 0;

export const fecha = (f: Instante) => fmtFecha.format(new Date(f));
export const fechaHora = (f: Instante) => fmtFechaHora.format(new Date(f));
export const hora = (f: Instante) => fmtHora.format(new Date(f));
export const diaCorto = (clave: string) => fmtDiaCorto.format(fechaDeClave(clave));
export const diaLargo = (clave: string) => fmtDiaLargo.format(fechaDeClave(clave));

const PASOS: [number, Intl.RelativeTimeFormatUnit][] = [
  [60, 'second'], [60, 'minute'], [24, 'hour'], [30, 'day'], [12, 'month'], [Infinity, 'year'],
];

/** «hace 3 horas», «ayer», «hace 2 meses». */
export function haceCuanto(f: Instante, ahora = Date.now()) {
  let v = (new Date(f).getTime() - ahora) / 1000;
  for (const [tope, unidad] of PASOS) {
    if (Math.abs(v) < tope) return fmtRelativo.format(Math.round(v), unidad);
    v /= tope;
  }
  return '';
}

/** Minúsculas y sin acentos, para buscar. */
export const normalizar = (s: string | null | undefined) =>
  (s ?? '').normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase();
