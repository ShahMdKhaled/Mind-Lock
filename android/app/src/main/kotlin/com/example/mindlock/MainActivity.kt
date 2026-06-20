package com.example.mindlock

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import android.content.Intent
import android.text.TextUtils
import android.content.Context
import android.app.AppOpsManager
import android.os.Process
import android.app.NotificationManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mindlock/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPreciseUsage" -> {
                    val start = call.argument<Long>("start") ?: 0L
                    val end = call.argument<Long>("end") ?: System.currentTimeMillis()
                    
                    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
                    
                    // We need events from a bit earlier to catch apps that were already in foreground
                    val searchStart = start - (1000 * 60 * 60 * 24) // 24 hours before
                    val events = usageStatsManager.queryEvents(searchStart, end)
                    
                    val map = HashMap<String, Long>()
                    val startTimes = HashMap<String, Long>()
                    
                    val event = android.app.usage.UsageEvents.Event()
                    while (events.hasNextEvent()) {
                        events.getNextEvent(event)
                        val packageName = event.packageName
                        
                        if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                            startTimes[packageName] = event.timeStamp
                        } else if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND) {
                            val startTime = startTimes[packageName]
                            if (startTime != null) {
                                // If the app was opened before our 'start' window but closed inside it (or after start)
                                val actualStart = Math.max(startTime, start)
                                val actualEnd = Math.min(event.timeStamp, end)
                                
                                if (actualEnd > actualStart) {
                                    val duration = actualEnd - actualStart
                                    map[packageName] = (map[packageName] ?: 0L) + duration
                                }
                                startTimes.remove(packageName)
                            }
                        }
                    }
                    
                    // Handle apps currently in foreground at the 'end' time
                    for ((packageName, startTime) in startTimes) {
                        val actualStart = Math.max(startTime, start)
                        val actualEnd = end
                        if (actualEnd > actualStart) {
                            val duration = actualEnd - actualStart
                            map[packageName] = (map[packageName] ?: 0L) + duration
                        }
                    }
                    
                    result.success(map)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled(this))
                }
                "isUsageAccessGranted" -> {
                    result.success(isUsageAccessGranted(this))
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "openUsageAccessSettings" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "isNotificationPolicyAccessGranted" -> {
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    result.success(notificationManager.isNotificationPolicyAccessGranted)
                }
                "openNotificationPolicySettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "setNotificationPolicyControl" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    if (notificationManager.isNotificationPolicyAccessGranted) {
                        if (enabled) {
                            notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                        } else {
                            notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                        }
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        // Build both possible names for the service
        val fullServiceName = context.packageName + "/" + MindLockAccessibilityService::class.java.canonicalName
        val shortServiceName = context.packageName + "/.MindLockAccessibilityService"
        
        val accessibilityEnabled = Settings.Secure.getInt(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED, 0)
        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            if (settingValue != null) {
                val splitter = TextUtils.SimpleStringSplitter(':')
                splitter.setString(settingValue)
                while (splitter.hasNext()) {
                    val accessibilityService = splitter.next()
                    if (accessibilityService.equals(fullServiceName, ignoreCase = true) || 
                        accessibilityService.equals(shortServiceName, ignoreCase = true)) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private fun isUsageAccessGranted(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, 
            Process.myUid(), context.packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
