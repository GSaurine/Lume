#!/usr/bin/env bash
# Captura o ecrã do dispositivo, mas só se o Lume estiver mesmo à frente.
#
# Usar:  tool/device_shot.sh build/device/home.png [segundos_de_espera]

set -euo pipefail

source "$(dirname "$0")/device_guard.sh"

OUTPUT="${1:-build/device/shot.png}"
WAIT_SECONDS="${2:-0}"

if [[ "$WAIT_SECONDS" -gt 0 ]]; then
  sleep "$WAIT_SECONDS"
fi

require_lume_foreground

mkdir -p "$(dirname "$OUTPUT")"
"$ADB" exec-out screencap -p > "$OUTPUT"

# Segunda verificação: se a app em primeiro plano mudou durante a captura,
# a imagem já não é do Lume e não deve ficar no disco.
if ! require_lume_foreground; then
  rm -f "$OUTPUT"
  echo "Captura descartada: a app em primeiro plano mudou durante o screenshot." >&2
  exit 1
fi

echo "OK: $OUTPUT"
