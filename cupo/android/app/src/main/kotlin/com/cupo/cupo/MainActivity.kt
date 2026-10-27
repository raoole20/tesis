package com.cupo.cupo

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad única de Cupo.
 *
 * El canal `cupo/spike_rastreo` es del spike de rastreo en segundo plano
 * (HU-011, docs/producto/spike-rastreo.md). Da lo que geolocator no trae y la
 * prueba necesita, sin sumar dependencias: el permiso de notificaciones de
 * Android 13+, mantener la pantalla encendida, saber si está encendida, el
 * estado de la optimización de batería y los avisos de cambio de fase. Lo
 * usa cupo/lib/features/spike_rastreo/data/canal_dispositivo.dart; al borrar
 * el spike se borra el canal entero.
 */
class MainActivity : FlutterActivity() {
    private var permisoPendiente: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL)
            .setMethodCallHandler { llamada, resultado ->
                when (llamada.method) {
                    "info" -> resultado.success(info())
                    "pantallaEncendida" ->
                        resultado.success(energia().isInteractive)
                    "mantenerPantallaEncendida" -> {
                        val bandera = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                        if (llamada.arguments == true) {
                            window.addFlags(bandera)
                        } else {
                            window.clearFlags(bandera)
                        }
                        resultado.success(null)
                    }
                    "pedirNotificaciones" -> pedirNotificaciones(resultado)
                    "avisar" -> resultado.success(
                        avisar(
                            llamada.argument<String>("titulo") ?: "",
                            llamada.argument<String>("texto") ?: "",
                        ),
                    )
                    "abrirAjustesBateria" -> {
                        startActivity(
                            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                        )
                        resultado.success(null)
                    }
                    else -> resultado.notImplemented()
                }
            }
    }

    private fun energia(): PowerManager = getSystemService(PowerManager::class.java)

    private fun info(): Map<String, Any> = mapOf(
        "fabricante" to Build.MANUFACTURER,
        "modelo" to Build.MODEL,
        "android" to Build.VERSION.RELEASE,
        "sdk" to Build.VERSION.SDK_INT,
        "bateriaSinRestriccion" to energia().isIgnoringBatteryOptimizations(packageName),
    )

    /** En Android 12 o menos el permiso no existe: se da por concedido. */
    private fun pedirNotificaciones(resultado: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            resultado.success(true)
            return
        }
        if (permisoPendiente != null) {
            resultado.error("en_curso", "Ya hay una solicitud abierta", null)
            return
        }
        permisoPendiente = resultado
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            CODIGO_NOTIFICACIONES,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        // super reparte el resultado a los plugins (geolocator usa otro código).
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != CODIGO_NOTIFICACIONES) return
        permisoPendiente?.success(
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
        )
        permisoPendiente = null
    }

    /** Notificación con sonido y vibración; false si no se puede mostrar. */
    private fun avisar(titulo: String, texto: String): Boolean {
        val gestor = getSystemService(NotificationManager::class.java)
        if (!gestor.areNotificationsEnabled()) return false
        if (gestor.getNotificationChannel(CANAL_AVISOS) == null) {
            val canal = NotificationChannel(
                CANAL_AVISOS,
                "Prueba de rastreo: cambios de fase",
                NotificationManager.IMPORTANCE_HIGH,
            )
            canal.enableVibration(true)
            gestor.createNotificationChannel(canal)
        }
        val abrir = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        val alTocar = PendingIntent.getActivity(
            this,
            0,
            abrir,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val aviso = Notification.Builder(this, CANAL_AVISOS)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(titulo)
            .setContentText(texto)
            .setStyle(Notification.BigTextStyle().bigText(texto))
            .setCategory(Notification.CATEGORY_REMINDER)
            .setContentIntent(alTocar)
            .setAutoCancel(true)
            .build()
        gestor.notify(ID_AVISO, aviso)
        return true
    }

    private companion object {
        const val CANAL = "cupo/spike_rastreo"
        const val CANAL_AVISOS = "spike_rastreo_avisos"
        const val ID_AVISO = 4201
        const val CODIGO_NOTIFICACIONES = 4202
    }
}
