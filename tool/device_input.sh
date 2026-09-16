#!/usr/bin/env bash
# Envia um gesto ou tecla para o dispositivo, mas só se o Lume estiver à frente.
#
# Usar:
#   tool/device_input.sh swipe X1 Y1 X2 Y2 [DURACAO_MS]
#   tool/device_input.sh tap X Y
#   tool/device_input.sh key KEYCODE_BACK

set -euo pipefail

source "$(dirname "$0")/device_guard.sh"

require_lume_foreground

action="$1"
shift

case "$action" in
  swipe) "$ADB" shell input swipe "$@" ;;
  tap)   "$ADB" shell input tap "$@" ;;
  key)   "$ADB" shell input keyevent "$@" ;;
  *)     echo "Ação desconhecida: $action" >&2; exit 2 ;;
esac

echo "OK: $action $*"
