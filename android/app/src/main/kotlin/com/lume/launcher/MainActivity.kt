package com.lume.launcher

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine

/**
 * A Home Activity do Lume (o "LauncherActivity" do plano, secção 7).
 *
 * Mantém o nome MainActivity porque é o que o toolchain do Flutter gera e
 * referencia; o papel de launcher vem do intent-filter CATEGORY_HOME no
 * AndroidManifest, não do nome da classe.
 *
 * O botão Back é tratado do lado do Flutter (PopScope no HomeScreen): num
 * launcher, Back nunca deve terminar a Home.
 */
class MainActivity : FlutterActivity() {

    private var appManager: AppManager? = null

    /**
     * Desenha por cima do wallpaper do utilizador em vez de um fundo opaco.
     * Requer o tema translúcido definido em res/values/styles.xml.
     */
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        appManager = AppManager(
            context = applicationContext,
            packages = PackageManagerService(applicationContext),
            roles = LauncherRoleManager(applicationContext),
            gestures = GestureService(applicationContext),
        ).apply {
            activity = this@MainActivity
            attach(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        appManager?.detach()
        appManager = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /**
     * Carregar em Home enquanto o Lume já está à frente reentrega a intent aqui.
     * É o sinal para a UI voltar ao estado inicial (fechar pesquisa/overlays).
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.hasCategory(Intent.CATEGORY_HOME)) {
            appManager?.notifyHomePressed()
        }
    }
}
