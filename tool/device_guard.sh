# Guarda partilhado pelos scripts de teste em dispositivo.
#
# O telemóvel de testes é o telemóvel real de alguém: um screenshot ou um
# gesto enviados às cegas vão parar ao que estiver aberto — email, mensagens,
# banco. Nada é enviado nem capturado sem o Lume estar mesmo em primeiro plano.
#
# Uso: source tool/device_guard.sh  &&  require_lume_foreground

PACKAGE="${PACKAGE:-com.lume.launcher}"
ADB="${ADB:-$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe}"

device_wakefulness() {
  "$ADB" shell dumpsys power 2>/dev/null \
    | grep -m1 'mWakefulness=' \
    | tr -d '\r' \
    | sed 's/.*mWakefulness=//'
}

device_focus() {
  "$ADB" shell dumpsys window 2>/dev/null \
    | grep -m1 'mCurrentFocus' \
    | tr -d '\r' \
    | sed 's/.*mCurrentFocus=//'
}

# Distingue as três razões possíveis, porque levam a ações diferentes:
# ecrã a dormir (desbloquear), outra app à frente (voltar ao Lume), ou tudo
# bem. Num Samsung o ecrã ambiente também aparece como "NotificationShade",
# por isso a wakefulness tem de ser verificada primeiro.
require_lume_foreground() {
  local wakefulness focus
  wakefulness="$(device_wakefulness)"

  if [[ "$wakefulness" != "Awake" ]]; then
    echo "RECUSADO: o ecrã do telemóvel não está aceso (mWakefulness=$wakefulness)." >&2
    echo "  Desbloqueie o telemóvel e deixe o Lume aberto." >&2
    return 1
  fi

  focus="$(device_focus)"
  if [[ "$focus" != *"$PACKAGE"* ]]; then
    echo "RECUSADO: o Lume não está em primeiro plano." >&2
    echo "  em foco: $focus" >&2
    return 1
  fi

  return 0
}
