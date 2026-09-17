package com.lume.launcher

import android.app.Activity
import android.app.ActivityOptions
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Rect
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Ponte única entre Flutter e Android (plano, secção 5).
 *
 * - [METHOD_CHANNEL] responde a pedidos vindos do Flutter.
 * - [EVENT_CHANNEL] empurra eventos do Android para o Flutter
 *   (app instalada/removida, botão Home premido).
 */
class AppManager(
    private val context: Context,
    private val packages: PackageManagerService,
    private val roles: LauncherRoleManager,
    private val gestures: GestureService,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "com.lume.launcher/apps"
        const val EVENT_CHANNEL = "com.lume.launcher/events"
        private const val DEFAULT_ICON_SIZE = 128
    }

    /** Activity atual; necessária para diálogos do sistema. Pode ser null. */
    var activity: Activity? = null

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var packageReceiver: BroadcastReceiver? = null

    fun attach(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).apply {
            setMethodCallHandler(this@AppManager)
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL).apply {
            setStreamHandler(this@AppManager)
        }
    }

    fun detach() {
        unregisterPackageReceiver()
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        activity = null
    }

    /** Chamado pela Activity quando o utilizador carrega em Home já dentro do Lume. */
    fun notifyHomePressed() = emit("home_pressed", null)

    // --- MethodChannel ---------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getInstalledApps" -> result.success(packages.getInstalledApps())

                "getApp" -> result.success(packages.getApp(call.requireArg("packageName")))

                "getAppIcon" -> {
                    val packageName = call.requireArg<String>("packageName")
                    val size = call.argument<Int>("size") ?: DEFAULT_ICON_SIZE
                    result.success(packages.getAppIcon(packageName, size))
                }

                "launchApp" -> result.success(
                    launchApp(
                        call.requireArg("packageName"),
                        call.argument("activityName"),
                        call.argument("sourceBounds"),
                    ),
                )

                "openAppInfo" -> result.success(openAppInfo(call.requireArg("packageName")))

                "requestUninstall" -> result.success(requestUninstall(call.requireArg("packageName")))

                "isAppInstalled" -> result.success(packages.isInstalled(call.requireArg("packageName")))

                "isDefaultLauncher" -> result.success(roles.isDefaultLauncher())

                "requestDefaultLauncher" -> result.success(roles.requestHomeRole(activity))

                "expandNotifications" -> result.success(gestures.expandNotifications())

                "isAccessibilityEnabled" -> result.success(gestures.isAccessibilityServiceEnabled())

                "openAccessibilitySettings" -> result.success(gestures.openAccessibilitySettings())

                "openSystemSettings" -> result.success(gestures.openSystemSettings())

                "openWallpaperPicker" -> result.success(openWallpaperPicker())

                "lockScreen" -> result.success(LumeAccessibilityService.lockScreen())

                "openRecents" -> result.success(LumeAccessibilityService.openRecents())

                "clearIconCache" -> {
                    packages.clearIconCache()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        } catch (e: IllegalArgumentException) {
            result.error("bad_arguments", e.message, null)
        } catch (e: Exception) {
            result.error("platform_error", e.message, e.stackTraceToString())
        }
    }

    // --- EventChannel ----------------------------------------------------

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        registerPackageReceiver()
    }

    override fun onCancel(arguments: Any?) {
        unregisterPackageReceiver()
        eventSink = null
    }

    private fun emit(type: String, packageName: String?) {
        eventSink?.success(mapOf("type" to type, "packageName" to packageName))
    }

    private fun registerPackageReceiver() {
        if (packageReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                val pkg = intent?.data?.schemeSpecificPart ?: return
                if (pkg == context.packageName) return
                val type = when (intent.action) {
                    Intent.ACTION_PACKAGE_ADDED -> "package_added"
                    Intent.ACTION_PACKAGE_REMOVED -> "package_removed"
                    else -> "package_changed"
                }
                emit(type, pkg)
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_CHANGED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
        packageReceiver = receiver
    }

    private fun unregisterPackageReceiver() {
        packageReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: IllegalArgumentException) {
                // Já tinha sido removido.
            }
        }
        packageReceiver = null
    }

    // --- FASE 4: abrir aplicativos ---------------------------------------

    private fun launchApp(
        packageName: String,
        activityName: String?,
        bounds: List<Double>?,
    ): Boolean {
        val intent = buildLaunchIntent(packageName, activityName) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)

        // Faz a animação do sistema partir do sítio onde o utilizador tocou.
        val rect = bounds?.takeIf { it.size == 4 }?.let {
            Rect(it[0].toInt(), it[1].toInt(), it[2].toInt(), it[3].toInt())
        }
        intent.sourceBounds = rect

        val decorView = activity?.window?.decorView
        val options = if (rect != null && decorView != null) {
            ActivityOptions
                .makeScaleUpAnimation(decorView, rect.left, rect.top, rect.width(), rect.height())
                .toBundle()
        } else {
            null
        }

        return try {
            context.startActivity(intent, options)
            true
        } catch (e: Exception) {
            // Alguns apps declaram uma activity que já não existe ou foi desativada.
            launchFallback(packageName)
        }
    }

    private fun launchFallback(packageName: String): Boolean {
        val fallback = context.packageManager
            .getLaunchIntentForPackage(packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            ?: return false
        return try {
            context.startActivity(fallback)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun buildLaunchIntent(packageName: String, activityName: String?): Intent? {
        if (!activityName.isNullOrBlank()) {
            return Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_LAUNCHER)
                .setComponent(ComponentName(packageName, activityName))
        }
        return context.packageManager.getLaunchIntentForPackage(packageName)
    }

    /**
     * Abre o seletor de wallpaper do sistema.
     *
     * Um launcher não deve pintar o seu próprio wallpaper: o Android já tem
     * um seletor, que respeita o que o fabricante acrescentou (ecrã de
     * bloqueio, wallpapers animados). Só o abrimos.
     */
    private fun openWallpaperPicker(): Boolean {
        val intent = Intent(Intent.ACTION_SET_WALLPAPER)
        return startSafely(Intent.createChooser(intent, "Mudar wallpaper"))
    }

    private fun openAppInfo(packageName: String): Boolean = startSafely(
        Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        ),
    )

    @Suppress("DEPRECATION")
    private fun requestUninstall(packageName: String): Boolean = startSafely(
        Intent(Intent.ACTION_DELETE, Uri.fromParts("package", packageName, null)),
    )

    private fun startSafely(intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        false
    }
}

private inline fun <reified T> MethodCall.requireArg(name: String): T =
    argument<T>(name) ?: throw IllegalArgumentException("Argumento obrigatório em falta: $name")
