package com.lume.launcher

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.LruCache
import java.io.ByteArrayOutputStream

/**
 * FASE 3 — Descoberta de aplicativos.
 *
 * O Android é a fonte de verdade dos apps instalados (ver plano, secção 8).
 * Esta classe só lê o PackageManager; nada é persistido aqui.
 *
 * Nota de performance (FASE 10): a listagem NÃO devolve ícones. Codificar
 * ~150 ícones em PNG bloquearia o arranque do launcher por vários segundos.
 * Os ícones são pedidos um a um, sob demanda, e ficam em cache.
 */
class PackageManagerService(private val context: Context) {

    private val packageManager: PackageManager get() = context.packageManager

    /** ~4 MB de ícones já codificados. Chave: "$packageName|$sizePx". */
    private val iconCache = object : LruCache<String, ByteArray>(4 * 1024 * 1024) {
        override fun sizeOf(key: String, value: ByteArray): Int = value.size
    }

    /** Lista os apps que têm um ecrã de entrada (MAIN/LAUNCHER). */
    fun getInstalledApps(): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolved: List<ResolveInfo> = queryLauncherActivities(intent)

        return resolved.asSequence()
            .filter { it.activityInfo != null }
            // Um launcher não se deve listar a si próprio.
            .filter { it.activityInfo.packageName != context.packageName }
            .map { toMap(it) }
            .distinctBy { it["id"] as String }
            .sortedBy { (it["name"] as String).lowercase() }
            .toList()
    }

    /** Dados de um único app, ou null se já não estiver instalado. */
    fun getApp(packageName: String): Map<String, Any?>? {
        val intent = Intent(Intent.ACTION_MAIN, null)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .setPackage(packageName)
        return queryLauncherActivities(intent).firstOrNull()?.let { toMap(it) }
    }

    /** Ícone do app em PNG (ARGB_8888), redimensionado para [sizePx]. */
    fun getAppIcon(packageName: String, sizePx: Int): ByteArray? {
        val key = "$packageName|$sizePx"
        iconCache.get(key)?.let { return it }

        val drawable: Drawable = try {
            packageManager.getApplicationIcon(packageName)
        } catch (e: PackageManager.NameNotFoundException) {
            return null
        }

        val png = drawableToPng(drawable, sizePx) ?: return null
        iconCache.put(key, png)
        return png
    }

    fun clearIconCache() = iconCache.evictAll()

    fun isInstalled(packageName: String): Boolean = try {
        packageManager.getApplicationInfo(packageName, 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    // --- Internals -------------------------------------------------------

    @Suppress("DEPRECATION")
    private fun queryLauncherActivities(intent: Intent): List<ResolveInfo> = try {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(0L),
            )
        } else {
            packageManager.queryIntentActivities(intent, 0)
        }
    } catch (e: Exception) {
        emptyList()
    }

    private fun toMap(info: ResolveInfo): Map<String, Any?> {
        val activityInfo = info.activityInfo
        val packageName = activityInfo.packageName
        val activityName = activityInfo.name
        val label = info.loadLabel(packageManager)?.toString()?.trim()
        val isSystem = (activityInfo.applicationInfo.flags and
            (ApplicationInfo.FLAG_SYSTEM or ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0

        return mapOf(
            "id" to "$packageName/$activityName",
            "name" to (if (label.isNullOrEmpty()) packageName else label),
            "packageName" to packageName,
            "activityName" to activityName,
            "isSystemApp" to isSystem,
        )
    }

    private fun drawableToPng(drawable: Drawable, sizePx: Int): ByteArray? = try {
        val size = sizePx.coerceIn(48, 512)
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
        } else {
            Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888).also { bmp ->
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }
        }
        ByteArrayOutputStream(size * size).use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            if (!bitmap.isRecycled) bitmap.recycle()
            stream.toByteArray()
        }
    } catch (e: Exception) {
        null
    }
}
