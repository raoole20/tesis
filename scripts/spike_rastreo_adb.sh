#!/usr/bin/env bash
# Spike de rastreo (HU-011): cambia de fase por adb, sin tocar el teléfono.
#
# Uso (desde Git Bash, con el teléfono conectado y la depuración USB activa):
#
#   bash scripts/spike_rastreo_adb.sh [minutos_por_fase] [--doze]
#
#   minutos_por_fase  2, 10 o 20; el mismo que elegiste en la app (10 por omisión)
#   --doze            al empezar la fase 3, fuerza el reposo profundo de Android
#                     (lo que pasaría tras un buen rato con la pantalla apagada)
#
# Pasos: abre «Prueba de rastreo», elige la duración y toca «Empezar prueba».
# Cuando la pantalla diga «FASE 1 DE 3», pulsa Enter aquí. El script:
#   1. le hace creer a Android que el cargador está desconectado (por USB el
#      teléfono carga, y cargando Android no ahorra batería: la prueba no
#      diría nada);
#   2. al terminar la fase 1 pulsa Inicio (fase 2: minimizada);
#   3. al terminar la fase 2 apaga la pantalla (fase 3);
#   4. al terminar, enciende la pantalla y devuelve la batería a la normalidad.
# Guarda el logcat del servicio de ubicación en spike_rastreo_<fecha>.log.
#
# Ver docs/producto/spike-rastreo.md.

set -euo pipefail

minutos="${1:-10}"
doze=false
[[ "${2:-}" == "--doze" || "${1:-}" == "--doze" ]] && doze=true
[[ "$minutos" == "--doze" ]] && minutos=10

if ! adb get-state >/dev/null 2>&1; then
  echo "No hay ningún teléfono conectado (adb devices está vacío)." >&2
  exit 1
fi

segundos=$((minutos * 60))
registro="spike_rastreo_$(date +%Y%m%d_%H%M%S).log"

restaurar() {
  adb shell dumpsys battery reset >/dev/null 2>&1 || true
  adb shell dumpsys deviceidle unforce >/dev/null 2>&1 || true
  [[ -n "${pid_log:-}" ]] && kill "$pid_log" 2>/dev/null || true
}
trap restaurar EXIT

echo "Teléfono: $(adb shell getprop ro.product.manufacturer | tr -d '\r') $(adb shell getprop ro.product.model | tr -d '\r') · Android $(adb shell getprop ro.build.version.release | tr -d '\r')"
echo "Fases de $minutos min. Doze forzado en la fase 3: $doze"
read -r -p "Pulsa Enter cuando la app muestre «FASE 1 DE 3»… "

adb logcat -c
adb logcat -v time FlutterGeolocator:V flutter:V '*:S' >"$registro" &
pid_log=$!
adb shell dumpsys battery unplug

echo "$(date +%T) Fase 1: app abierta ($minutos min)"
sleep "$segundos"

adb shell input keyevent KEYCODE_HOME
echo "$(date +%T) Fase 2: minimizada ($minutos min)"
sleep "$segundos"

adb shell input keyevent KEYCODE_SLEEP
echo "$(date +%T) Fase 3: pantalla apagada ($minutos min)"
if $doze; then
  sleep 5
  adb shell dumpsys deviceidle force-idle
fi
# Un margen para que el cierre de la fase quede dentro de la medición.
sleep $((segundos + 15))

adb shell input keyevent KEYCODE_WAKEUP
echo "$(date +%T) Terminado. Desbloquea el teléfono y mira el resultado en la app."
echo "Logcat del servicio: $registro"
