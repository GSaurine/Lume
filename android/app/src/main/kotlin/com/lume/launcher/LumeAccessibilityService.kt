package com.lume.launcher

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

/**
 * Serviço opcional. Só existe para executar ações globais que a API pública
 * não expõe (abrir notificações, bloquear ecrã).
 *
 * Não lê conteúdo de ecrã: `canRetrieveWindowContent` é false no XML de
 * configuração e [onAccessibilityEvent] ignora todos os eventos.
 */
class LumeAccessibilityService : AccessibilityService() {

    companion object {
        private var instance: LumeAccessibilityService? = null

        fun expandNotifications(): Boolean =
            instance?.performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS) ?: false

        fun lockScreen(): Boolean {
            val service = instance ?: return false
            if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.P) return false
            return service.performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
        }

        fun openRecents(): Boolean =
            instance?.performGlobalAction(GLOBAL_ACTION_RECENTS) ?: false
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) { /* intencionalmente vazio */ }

    override fun onInterrupt() { /* intencionalmente vazio */ }
}
