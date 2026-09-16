#!/usr/bin/env bash
# Envia um gesto ou tecla para o dispositivo, mas só se o Lume estiver à frente.
#
# Mesma razão de tool/device_shot.sh: o telemóvel de teste é o telemóvel real
# de alguém. Um swipe enviado às cegas vai parar ao que estiver aberto.
#
# Usar:
#   tool/device_input.sh swipe X1 Y1 X2 Y2 [DURACAO_MS]
#   tool/device_input.sh tap X Y
#   tool/device_input.sh key KEYCODE_BACK

set -euo pipefail

PACKAGE="com.lume.launcher"
ADB="${ADB:-$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe}"

focus="$("$ADB" shell dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus' | tr -d '\r')"
if [[ "$focus" != *"$PACKAGE"* ]]; then
  echo "RECUSADO: o Lume não está em primeiro plano." >&2
  echo "  em foco: $focus" >&2
  exit 1
fi

action="$1"
shift

case "$action" in
  swipe) "$ADB" shell input swipe "$@" ;;
  tap)   "$ADB" shell input tap "$@" ;;
  key)   "$ADB" shell input keyevent "$@" ;;
  *)     echo "Ação desconhecida: $action" >&2; exit 2 ;;
esac

echo "OK: $action $*"
