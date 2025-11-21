package com.innermirror.app

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.innermirror.app/whatsapp_notifications"
    private val CHANNEL_PERMISSIONS = "com.innermirror.app/permissions"
    private val CHANNEL_ACCESSIBILITY = "com.innermirror.app/whatsapp_accessibility"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method channel for receiving WhatsApp messages from notification service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationAccess" -> {
                    result.success(isNotificationServiceEnabled())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Method channel for permission status
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PERMISSIONS).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }
                "checkAccessibilityAccess" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Method channel for accessibility service messages
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_ACCESSIBILITY).setMethodCallHandler { call, result ->
            when (call.method) {
                "onWhatsAppMessage" -> {
                    // Message received from accessibility service
                    // This is handled by the service itself via method channel invoke
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun isNotificationServiceEnabled(): Boolean {
        val packageName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val componentName = ComponentName.unflattenFromString(name)
                if (componentName != null) {
                    if (TextUtils.equals(packageName, componentName.packageName)) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }
    
    private fun isAccessibilityServiceEnabled(): Boolean {
        val accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        
        val serviceName = ComponentName(packageName, WhatsAppAccessibilityService::class.java.name)
        
        for (service in enabledServices) {
            if (service.resolveInfo.serviceInfo.name == serviceName.className) {
                return true
            }
        }
        return false
    }
    
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }
}


