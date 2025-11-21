package com.innermirror.app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.app.PendingIntent
import android.content.Context

/**
 * Notification Listener Service for WhatsApp messages (Android only)
 * 
 * User must enable this service in:
 * Settings > Accessibility > Downloaded apps > InnerMirror Notification Listener
 */
class WhatsAppNotificationService : NotificationListenerService() {
    private var methodChannel: MethodChannel? = null
    private var flutterEngine: FlutterEngine? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "WhatsAppNotificationService created")
        
        // Initialize Flutter engine for communication
        try {
            flutterEngine = FlutterEngine(applicationContext)
            flutterEngine?.dartExecutor?.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            
            methodChannel = MethodChannel(
                flutterEngine?.dartExecutor?.binaryMessenger,
                "com.innermirror.app/whatsapp_notifications"
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Flutter engine: $e")
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        
        sbn?.let { notification ->
            val packageName = notification.packageName
            
            // Check if it's a WhatsApp notification
            if (packageName == "com.whatsapp" || packageName == "com.whatsapp.w4b") {
                try {
                    val extras = notification.notification.extras
                    val title = extras?.getCharSequence("android.title")?.toString() ?: ""
                    val text = extras?.getCharSequence("android.text")?.toString() ?: ""
                    val bigText = extras?.getCharSequence("android.bigText")?.toString() ?: ""
                    
                    val messageBody = bigText.ifEmpty { text }
                    
                    if (messageBody.isNotEmpty() && title.isNotEmpty()) {
                        Log.d(TAG, "WhatsApp message detected: From=$title, Body=$messageBody")
                        
                        // Send to Flutter via method channel
                        val messageData = mapOf(
                            "from" to title,
                            "body" to messageBody,
                            "timestamp" to System.currentTimeMillis(),
                            "type" to "whatsapp"
                        )
                        
                        methodChannel?.invokeMethod("onWhatsAppMessage", messageData)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing WhatsApp notification: $e")
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        flutterEngine?.destroy()
        Log.d(TAG, "WhatsAppNotificationService destroyed")
    }

    companion object {
        private const val TAG = "WhatsAppNotificationService"
    }
}

