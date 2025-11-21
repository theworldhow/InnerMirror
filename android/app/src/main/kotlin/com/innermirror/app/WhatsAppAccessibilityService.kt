package com.innermirror.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.*
import kotlin.collections.ArrayList

/**
 * Accessibility Service for reading WhatsApp messages (Android only)
 * 
 * This service reads WhatsApp messages from the screen as they appear
 * User must enable this service in:
 * Settings > Accessibility > Downloaded apps > InnerMirror Accessibility Service
 */
class WhatsAppAccessibilityService : AccessibilityService() {
    private var methodChannel: MethodChannel? = null
    private var flutterEngine: FlutterEngine? = null
    private val messageCache = mutableSetOf<String>() // Cache to avoid duplicates
    private val maxCacheSize = 1000
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "WhatsAppAccessibilityService connected")
        
        // Configure service info
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPES_ALL_MASK
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                     AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        info.notificationTimeout = 100
        setServiceInfo(info)
        
        // Initialize Flutter engine for communication
        try {
            flutterEngine = FlutterEngine(applicationContext)
            flutterEngine?.dartExecutor?.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            
            methodChannel = MethodChannel(
                flutterEngine?.dartExecutor?.binaryMessenger,
                "com.innermirror.app/whatsapp_accessibility"
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Flutter engine: $e")
        }
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            val packageName = event.packageName?.toString()
            
            // Check if it's WhatsApp
            if (packageName == "com.whatsapp" || packageName == "com.whatsapp.w4b") {
                when (event.eventType) {
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
                    AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
                    AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                        // Try to read messages from the screen
                        readWhatsAppMessages()
                    }
                }
            }
        }
    }
    
    private fun readWhatsAppMessages() {
        try {
            val rootNode = rootInActiveWindow ?: return
            
            // Look for message bubbles in WhatsApp
            val messages = findMessages(rootNode)
            
            for (message in messages) {
                val messageKey = "${message.sender}|${message.text}|${message.timestamp}"
                
                // Check cache to avoid duplicates
                if (!messageCache.contains(messageKey)) {
                    // Add to cache (limit size)
                    if (messageCache.size >= maxCacheSize) {
                        messageCache.clear()
                    }
                    messageCache.add(messageKey)
                    
                    // Send to Flutter
                    val messageData = mapOf(
                        "from" to message.sender,
                        "body" to message.text,
                        "timestamp" to message.timestamp,
                        "type" to "whatsapp"
                    )
                    
                    methodChannel?.invokeMethod("onWhatsAppMessage", messageData)
                    Log.d(TAG, "WhatsApp message read: From=${message.sender}, Body=${message.text}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading WhatsApp messages: $e")
        }
    }
    
    private fun findMessages(rootNode: AccessibilityNodeInfo?): List<WhatsAppMessage> {
        val messages = mutableListOf<WhatsAppMessage>()
        
        if (rootNode == null) return messages
        
        // Recursively search for message nodes
        // WhatsApp message structure: Container with text and sender info
        val nodeQueue: Queue<AccessibilityNodeInfo> = LinkedList()
        nodeQueue.add(rootNode)
        
        while (nodeQueue.isNotEmpty()) {
            val node = nodeQueue.poll() ?: continue
            
            // Check if this looks like a message bubble
            val text = node.text?.toString() ?: ""
            val contentDescription = node.contentDescription?.toString() ?: ""
            
            // WhatsApp message indicators
            if (text.isNotEmpty() && (
                node.className?.toString()?.contains("MessageText") == true ||
                node.className?.toString()?.contains("ConversationRow") == true ||
                (text.length > 10 && node.parent?.className?.toString()?.contains("Bubble") == true)
            )) {
                // Try to find sender name (usually in parent or sibling)
                val sender = findSenderName(node) ?: "Unknown"
                
                // Extract timestamp if available
                val timestamp = findTimestamp(node) ?: System.currentTimeMillis()
                
                if (text.isNotEmpty() && text.length > 3) {
                    messages.add(WhatsAppMessage(sender, text, timestamp))
                }
            }
            
            // Add children to queue
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { child ->
                    nodeQueue.add(child)
                }
            }
        }
        
        return messages
    }
    
    private fun findSenderName(messageNode: AccessibilityNodeInfo?): String? {
        var current = messageNode?.parent
        var depth = 0
        val maxDepth = 5
        
        while (current != null && depth < maxDepth) {
            // Look for sender name in accessibility text
            val text = current.text?.toString()
            val contentDesc = current.contentDescription?.toString()
            
            // Check siblings for sender name
            val parent = current.parent
            if (parent != null) {
                for (i in 0 until parent.childCount) {
                    val sibling = parent.getChild(i)
                    val siblingText = sibling?.text?.toString() ?: ""
                    val siblingContent = sibling?.contentDescription?.toString() ?: ""
                    
                    // WhatsApp sender names are usually short and before the message
                    if ((siblingText.length < 50 && siblingText.isNotEmpty() && 
                         !siblingText.contains("•") && !siblingText.contains(":")) ||
                        (siblingContent.contains("name") || siblingContent.contains("contact"))) {
                        return siblingText.ifEmpty { siblingContent }
                    }
                }
            }
            
            // Check current node
            if (text != null && text.length < 50 && text.isNotEmpty() && 
                text != messageNode?.text?.toString() &&
                !text.contains("•") && !text.contains(":")) {
                return text
            }
            
            current = current.parent
            depth++
        }
        
        return null
    }
    
    private fun findTimestamp(messageNode: AccessibilityNodeInfo?): Long? {
        // Try to extract timestamp from content description or text
        var current = messageNode
        var depth = 0
        val maxDepth = 3
        
        while (current != null && depth < maxDepth) {
            val contentDesc = current.contentDescription?.toString() ?: ""
            val text = current.text?.toString() ?: ""
            
            // Look for time patterns
            val timePattern = Regex("""\d{1,2}:\d{2}""")
            val timeMatch = timePattern.find(contentDesc) ?: timePattern.find(text)
            
            if (timeMatch != null) {
                // Found a time - return current time (we can't parse exact timestamp from screen)
                return System.currentTimeMillis()
            }
            
            current = current.parent
            depth++
        }
        
        return null
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "WhatsAppAccessibilityService interrupted")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        flutterEngine?.destroy()
        messageCache.clear()
        Log.d(TAG, "WhatsAppAccessibilityService destroyed")
    }
    
    private data class WhatsAppMessage(
        val sender: String,
        val text: String,
        val timestamp: Long
    )
    
    companion object {
        private const val TAG = "WhatsAppAccessibilityService"
    }
}

