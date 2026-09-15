package com.lume.launcher

import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings

/**
 * FASE 2 — fluxo de seleção como launcher padrão.
 *
 * Não existe API para "tornar-se" launcher: a escolha é sempre do utilizador.
 * O melhor que podemos fazer é levá-lo ao ecrã certo do sistema.
 */
class LauncherRoleManager(private val context: Context) {

    companion object {
        const val REQUEST_CODE_HOME_ROLE = 4801
    }

    /** O Lume é o Home atual? */
    @Suppress("DEPRECATION")
    fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val resolved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.resolveActivity(
                intent,
                PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()),
            )
        } else {
            context.packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        }
        return resolved?.activityInfo?.packageName == context.packageName
    }

    /**
     * Abre o diálogo/ecrã para escolher o launcher padrão.
     * Devolve false se nenhum caminho estiver disponível no dispositivo.
     */
    fun requestHomeRole(activity: Activity?): Boolean {
        if (isDefaultLauncher()) return true

        // Android 10+: diálogo nativo de "role".
        if (activity != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val roleManager = context.getSystemService(RoleManager::class.java)
                if (roleManager != null &&
                    roleManager.isRoleAvailable(RoleManager.ROLE_HOME) &&
                    !roleManager.isRoleHeld(RoleManager.ROLE_HOME)
                ) {
                    activity.startActivityForResult(
                        roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME),
                        REQUEST_CODE_HOME_ROLE,
                    )
                    return true
                }
            } catch (e: Exception) {
                // Alguns fabricantes bloqueiam o role — cai no fallback.
            }
        }

        // Fallback 1: ecrã de definições de app padrão.
        if (startSafely(Intent(Settings.ACTION_HOME_SETTINGS))) return true

        // Fallback 2: obriga o sistema a mostrar o seletor "Abrir com".
        return startSafely(
            Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME)
                .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    private fun startSafely(intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        false
    }
}
