package com.tubetune.app

import android.app.KeyguardManager
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.os.Build
import android.os.PowerManager
import android.util.Rational
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.tubetune.app/pip"
    private var methodChannel: MethodChannel? = null
    private var isPipEnabled = true
    private var isVideoPlaying = false
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        const val ACTION_PIP_PLAY_PAUSE = "com.tubetune.app.PIP_PLAY_PAUSE"
        const val ACTION_PIP_NEXT = "com.tubetune.app.PIP_NEXT"
        const val ACTION_PIP_PREV = "com.tubetune.app.PIP_PREV"
        const val REQ_PLAY_PAUSE = 101
        const val REQ_NEXT = 102
        const val REQ_PREV = 103
    }

    private val pipActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_PIP_PLAY_PAUSE -> {
                    isVideoPlaying = !isVideoPlaying
                    updatePipParams()
                    methodChannel?.invokeMethod("onPipPlayPause", isVideoPlaying)
                }
                ACTION_PIP_NEXT -> {
                    methodChannel?.invokeMethod("onPipNext", null)
                }
                ACTION_PIP_PREV -> {
                    methodChannel?.invokeMethod("onPipPrev", null)
                }
            }
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    methodChannel?.invokeMethod("onScreenOff", null)
                }
                Intent.ACTION_SCREEN_ON -> {
                    methodChannel?.invokeMethod("onScreenOn", null)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "setPipEnabled" -> {
                        isPipEnabled = call.argument<Boolean>("enabled") ?: true
                        updatePipParams()
                        result.success(true)
                    }
                    "setVideoPlaying" -> {
                        isVideoPlaying = call.argument<Boolean>("playing") ?: false
                        if (isVideoPlaying) {
                            acquireWakeLock()
                        } else {
                            releaseWakeLock()
                        }
                        updatePipParams()
                        result.success(true)
                    }
                    "enterPip" -> {
                        val success = enterPipMode()
                        result.success(success)
                    }
                    "isPipActive" -> {
                        val active = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            isInPictureInPictureMode
                        } else {
                            false
                        }
                        result.success(active)
                    }
                    "isDeviceLockedOrScreenOff" -> {
                        val isLockedOrOff = checkDeviceLockedOrScreenOff()
                        result.success(isLockedOrOff)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        val screenFilter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        registerReceiver(screenReceiver, screenFilter)

        val pipFilter = IntentFilter().apply {
            addAction(ACTION_PIP_PLAY_PAUSE)
            addAction(ACTION_PIP_NEXT)
            addAction(ACTION_PIP_PREV)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipActionReceiver, pipFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(pipActionReceiver, pipFilter)
        }
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock == null) {
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "TubeTune::PlaybackWakeLock")
            }
            if (wakeLock?.isHeld != true) {
                wakeLock?.acquire(24 * 60 * 60 * 1000L)
            }
        } catch (_: Exception) {}
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
    }

    private fun checkDeviceLockedOrScreenOff(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        val isScreenOff = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
            !(powerManager?.isInteractive ?: true)
        } else {
            !(powerManager?.isScreenOn ?: true)
        }

        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        val isKeyguardLocked = keyguardManager?.isKeyguardLocked ?: false

        return isScreenOff || isKeyguardLocked
    }

    override fun onDestroy() {
        releaseWakeLock()
        try {
            unregisterReceiver(screenReceiver)
        } catch (_: Exception) {}
        try {
            unregisterReceiver(pipActionReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    private fun buildPipActions(): ArrayList<RemoteAction> {
        val actions = ArrayList<RemoteAction>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 1. Previous Action
            val prevIntent = PendingIntent.getBroadcast(
                this,
                REQ_PREV,
                Intent(ACTION_PIP_PREV).setPackage(packageName),
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            val prevIcon = Icon.createWithResource(this, android.R.drawable.ic_media_previous)
            actions.add(RemoteAction(prevIcon, "Previous", "Previous", prevIntent))

            // 2. Play / Pause Action
            val playPauseIntent = PendingIntent.getBroadcast(
                this,
                REQ_PLAY_PAUSE,
                Intent(ACTION_PIP_PLAY_PAUSE).setPackage(packageName),
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            val iconRes = if (isVideoPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            val title = if (isVideoPlaying) "Pause" else "Play"
            val playPauseIcon = Icon.createWithResource(this, iconRes)
            actions.add(RemoteAction(playPauseIcon, title, title, playPauseIntent))

            // 3. Next Action
            val nextIntent = PendingIntent.getBroadcast(
                this,
                REQ_NEXT,
                Intent(ACTION_PIP_NEXT).setPackage(packageName),
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            val nextIcon = Icon.createWithResource(this, android.R.drawable.ic_media_next)
            actions.add(RemoteAction(nextIcon, "Next", "Next", nextIntent))
        }
        return actions
    }

    private fun updatePipParams() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val builder = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .setActions(buildPipActions())

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setAutoEnterEnabled(isPipEnabled && isVideoPlaying)
            }
            try {
                setPictureInPictureParams(builder.build())
            } catch (_: Exception) {}
        }
    }

    private fun enterPipMode(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && isPipEnabled) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .setActions(buildPipActions())
                .build()
            return enterPictureInPictureMode(params)
        }
        return false
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isPipEnabled && isVideoPlaying && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            enterPipMode()
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        methodChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }
}
