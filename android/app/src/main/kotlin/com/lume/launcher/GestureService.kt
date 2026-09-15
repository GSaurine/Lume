package com.lume.launcher

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils

/**
 * FASE 9 (gestos) — ações do sistema que a UI Flutter pode pedir.
 *
 * Abrir o painel de notificações não tem API pública. Usamos duas vias:
 *   1. o AccessibilityService do Lume, se o utilizador o tiver ativado;
 *   2. reflexão sobre o StatusBarManager (funciona em vários OEM até ao
 *      Android 11; a partir do 12 costuma estar bloqueado).
 * Se ambas falharem devolvemos false e a UI explica o que fazer.
 */
class GestureService(private val context: Context) {

    fun expandNotifications(): Boolean {
        if (LumeAccessibilityService.expandNotifications()) return true
        return expandViaReflection()
    }

    fun isAccessibilityServiceEnabled(): Boolean {
        val expected = "${context.packageName}/${LumeAccessibilityService::class.java.name}"
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false

        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabled)
        while (splitter.hasNext()) {
            if (splitter.next().equals(expected, ignoreCase = true)) return true
        }
        return false
    }

    fun openAccessibilitySettings(): Boolean =
        startSafely(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))

    fun openSystemSettings(): Boolean = startSafely(Intent(Settings.ACTION_SETTINGS))

    @SuppressLint("WrongConstant", "PrivateApi")
    private fun expandViaReflection(): Boolean = try {
        val service = context.getSystemService("statusbar")
        val statusBarManager = Class.forName("android.app.StatusBarManager")
        statusBarManager.getMethod("expandNotificationsPanel").invoke(service)
        true
    } catch (e: Throwable) {
        false
    }

    private fun startSafely(intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        false
    }
}
