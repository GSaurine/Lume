#!/usr/bin/env bash
# Captura o ecrã do dispositivo, mas só se o Lume estiver mesmo à frente.
#
# Um launcher em teste partilha o telemóvel com o resto da vida da pessoa.
# Sem esta verificação, um screenshot apanha o que estiver aberto — email,
# mensagens, banco. O guarda confirma a app em primeiro plano antes e depois
# da captura, e descarta a imagem se ela mudou entretanto.
#
# Usar:  tool/device_shot.sh build/device/home.png [segundos_de_espera]

set -euo pipefail

PACKAGE="com.lume.launcher"
OUTPUT="${1:-build/device/shot.png}"
WAIT_SECONDS="${2:-0}"

ADB="${ADB:-$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe}"

foreground() {
  "$ADB" shell dumpsys window 2>/dev/null \
    | grep -m1 'mCurrentFocus' \
    | tr -d '\r'
}

assert_lume() {
  local focus
  focus="$(foreground)"
  if [[ "$focus" != *"$PACKAGE"* ]]; then
    echo "RECUSADO: o Lume não está em primeiro plano." >&2
    echo "  em foco: $focus" >&2
    return 1
  fi
}

if [[ "$WAIT_SECONDS" -gt 0 ]]; then
  sleep "$WAIT_SECONDS"
fi

assert_lume

mkdir -p "$(dirname "$OUTPUT")"
"$ADB" exec-out screencap -p > "$OUTPUT"

# Segunda verificação: se o utilizador mudou de app durante a captura,
# a imagem já não é do Lume e não deve ficar no disco.
if ! assert_lume; then
  rm -f "$OUTPUT"
  echo "Captura descartada: a app em primeiro plano mudou durante o screenshot." >&2
  exit 1
fi

echo "OK: $OUTPUT"
