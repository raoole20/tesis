package com.cupo.cupo

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad única de Cupo.
 *
 * El canal `cupo/spike_rastreo` es del spike de rastreo en segundo plano
 * (HU-011, docs/producto/spike-rastreo.md). Da lo que geolocator no trae y la
 * prueba necesita, sin sumar dependencias: el permiso de notificaciones de
 * Android 13+, mantener la pantalla encendida, saber si está encendida, el
 * estado de la optimización de batería y de la carga, y los avisos de
 * cambio de fase. Lo
 * usa cupo/lib/features/spike_rastreo/data/canal_dispositivo.dart; al borrar
 * el spike se borra el canal entero.
 *
 * Hereda de [FlutterFragmentActivity] y no de `FlutterActivity` porque
 * `local_auth` (entrar con huella) muestra el aviso biométrico del sistema,
 * y en Android ese aviso necesita una `FragmentActivity`.
 */
class MainActivity : FlutterFragmentActivity() {
    private var permisoPendiente: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL)
            .setMethodCallHandler { llamada, resultado ->
                when (llamada.method) {
                    "info" -> resultado.success(info())
                    "pantallaEncendida" ->
                        resultado.success(energia().isInteractive)
                    "estadoAlCapturar" -> resultado.success(
                        mapOf(
                            "pantallaEncendida" to energia().isInteractive,
                        ) + bateria(),
                    )
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
                    "estadoEnVivo" -> resultado.success(
                        estadoEnVivo(
                            titulo = llamada.argument<String>("titulo") ?: "",
                            texto = llamada.argument<String>("texto") ?: "",
                            inicioMs = llamada.argument<Number>("inicioMs")?.toLong(),
                            progreso = llamada.argument<Int>("progreso"),
                            maximo = llamada.argument<Int>("maximo") ?: 1000,
                            color = llamada.argument<Number>("color")?.toInt(),
                            fijo = llamada.argument<Boolean>("fijo") ?: true,
                        ),
                    )
                    "cerrarEstado" -> {
                        getSystemService(NotificationManager::class.java)
                            .cancel(ID_SERVICIO_GEOLOCATOR)
                        resultado.success(null)
                    }
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

    private fun info(): Map<String, Any?> = mapOf(
        "fabricante" to Build.MANUFACTURER,
        "modelo" to Build.MODEL,
        "android" to Build.VERSION.RELEASE,
        "sdk" to Build.VERSION.SDK_INT,
        "bateriaSinRestriccion" to energia().isIgnoringBatteryOptimizations(packageName),
    ) + bateria()

    /** Carga en % y si está conectado a un cargador (también el del carro). */
    private fun bateria(): Map<String, Any?> {
        val gestor = getSystemService(BatteryManager::class.java)
        val nivel = gestor.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        // «Enchufado» y no isCharging: con la batería llena, isCharging da
        // false aunque el cargador del carro siga conectado.
        val estado = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val enchufado = estado?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        return mapOf(
            "bateriaPct" to nivel.takeIf { it in 0..100 },
            "cargando" to enchufado?.let { it != 0 },
        )
    }

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

    /**
     * La notificación en vivo de la prueba: título, texto que Dart actualiza
     * en cada muestra, cronómetro que dibuja el sistema solo (si no avanza,
     * la app murió) y barra de progreso.
     *
     * Usa el **mismo id que la notificación del servicio en primer plano de
     * geolocator** (`ONGOING_NOTIFICATION_ID = 75415` en
     * `GeolocatorLocationService`, geolocator_android 5.0.3). Publicar con ese
     * id reemplaza esa notificación en vez de sumar otra: sigue siendo la del
     * servicio, así que Android no lo deja sin notificación. Además la saca
     * del canal de geolocator, que es de importancia NONE y por eso no se veía
     * en la barra. Si una versión nueva de geolocator cambia el id, habría dos
     * notificaciones: revisar ese archivo al actualizar el paquete.
     *
     * En la simulación no hay servicio: la notificación es solo informativa y
     * con `fijo` no se puede descartar (en Android 14+ el sistema igual deja
     * descartarla; vuelve con la siguiente actualización).
     *
     * El color lo manda Dart: es `AppColors.primary` (#007C8A).
     */
    private fun estadoEnVivo(
        titulo: String,
        texto: String,
        inicioMs: Long?,
        progreso: Int?,
        maximo: Int,
        color: Int?,
        fijo: Boolean,
    ): Boolean {
        val gestor = getSystemService(NotificationManager::class.java)
        if (!gestor.areNotificationsEnabled()) return false
        if (gestor.getNotificationChannel(CANAL_ESTADO) == null) {
            // Baja: se ve en la barra, sin sonido ni vibración.
            gestor.createNotificationChannel(
                NotificationChannel(
                    CANAL_ESTADO,
                    "Prueba de rastreo: estado en vivo",
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
        val abrir = alAbrir()
        val constructor = Notification.Builder(this, CANAL_ESTADO)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(titulo)
            .setContentText(texto)
            .setStyle(Notification.BigTextStyle().bigText(texto))
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setContentIntent(abrir)
            // «Abrir» y nada más: terminar desde la barra, manejando, no.
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, applicationInfo.icon),
                    "Abrir",
                    abrir,
                ).build(),
            )
            .setOngoing(fijo)
            .setOnlyAlertOnce(true)
        if (color != null) constructor.setColor(color)
        if (inicioMs != null) {
            constructor.setWhen(inicioMs).setShowWhen(true).setUsesChronometer(true)
        }
        if (progreso != null) constructor.setProgress(maximo, progreso, false)
        gestor.notify(if (fijo) ID_SERVICIO_GEOLOCATOR else ID_RESUMEN, constructor.build())
        return true
    }

    private fun alAbrir(): PendingIntent {
        val abrir = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        return PendingIntent.getActivity(
            this,
            0,
            abrir,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
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
        const val CANAL_ESTADO = "spike_rastreo_estado"

        /** El de la notificación del servicio de geolocator (ver estadoEnVivo). */
        const val ID_SERVICIO_GEOLOCATOR = 75415

        /** El resumen final, descartable. */
        const val ID_RESUMEN = 4203
        const val ID_AVISO = 4201
        const val CODIGO_NOTIFICACIONES = 4202
    }
}
