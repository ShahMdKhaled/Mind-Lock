package com.noorsoft.mindlock

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.Context
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Handler
import android.os.Looper
import android.util.Log

class MindLockAccessibilityService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private var isBlockingActive = false
    
    // Performance Caching
    private var lastPrefCacheTime = 0L
    private var cachedBreakEnabled = false
    private var cachedStudyModeEnabled = false
    private var cachedUninstallProtectionEnabled = false
    private var cachedAppLimitsEnabled = false
    private var cachedReelsEnabled = false
    private var cachedBlockedPackages = listOf<String>()
    private var cachedAppLimitPackages = listOf<String>()

    private fun updatePrefsCache(prefs: android.content.SharedPreferences) {
        val now = System.currentTimeMillis()
        if (now - lastPrefCacheTime < 2000) return // Update at most every 2 seconds
        lastPrefCacheTime = now

        cachedBreakEnabled = try { prefs.getBoolean("flutter.break_enabled", false) } catch (e: Exception) { false }
        cachedStudyModeEnabled = try { prefs.getBoolean("flutter.study_mode_enabled", false) } catch (e: Exception) { false }
        cachedUninstallProtectionEnabled = try { prefs.getBoolean("flutter.uninstall_protection_enabled", false) } catch (e: Exception) { false }
        cachedAppLimitsEnabled = try { prefs.getBoolean("flutter.app_limits_enabled", false) } catch (e: Exception) { false }
        cachedReelsEnabled = try { prefs.getBoolean("flutter.reels_blocker_enabled", false) } catch (e: Exception) { false }
        
        cachedBlockedPackages = getStringListFromPrefs(prefs, "flutter.reels_blocked_packages")
        cachedAppLimitPackages = getStringListFromPrefs(prefs, "flutter.app_limit_packages")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        
        val isRelevantEvent = event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED || 
                             event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED

        if (!isRelevantEvent) return

        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        updatePrefsCache(prefs)
        
        // --- App Time Break Reminder ---
        if (cachedBreakEnabled && packageName.lowercase() != "com.noorsoft.mindlock") {
            val breakIntervalMins = try {
                prefs.getLong("flutter.break_interval_minutes", 20L)
            } catch (e: Exception) {
                try {
                    prefs.getInt("flutter.break_interval_minutes", 20).toLong()
                } catch (e2: Exception) {
                    20L
                }
            }
            
            // In test mode: treat minutes as seconds for fast testing!
            val breakIntervalMs = breakIntervalMins * 1000
            val lastBreakTime = prefs.getLong("flutter.last_break_time_ms", 0L)
            val now = System.currentTimeMillis()
            
            if (lastBreakTime == 0L) {
                prefs.edit().putLong("flutter.last_break_time_ms", now).apply()
            } else if (now - lastBreakTime >= breakIntervalMs) {
                prefs.edit().putLong("flutter.last_break_time_ms", now).apply()
                prefs.edit().putString("flutter.active_overlay_type", "break").apply()
                
                Log.d("MindLock", "Break Time reached - showing popup")
                
                handler.post {
                    try {
                        val intent = Intent(this, ReelsBlockActivity::class.java)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        startActivity(intent)
                    } catch (e: Exception) {}
                }
                return
            }
        }
        // --- End App Time Break Reminder ---
        
        // --- Study Mode Blocking ---
        if (cachedStudyModeEnabled) {
            val lowerPkg = packageName.lowercase()
            val isAllowedApp = lowerPkg == "com.noorsoft.mindlock" ||
                    lowerPkg.contains("launcher") ||
                    lowerPkg.contains("systemui") ||
                    lowerPkg.contains("dialer") ||
                    lowerPkg.contains("incallui") ||
                    lowerPkg.contains("telecom") ||
                    lowerPkg.contains("call") ||
                    lowerPkg.contains("phone") ||
                    lowerPkg.contains("com.android.settings")

            if (!isAllowedApp) {
                Log.d("MindLock", "Study Mode Active - Blocking App: $packageName")
                performGlobalAction(GLOBAL_ACTION_HOME)
                performGlobalAction(GLOBAL_ACTION_BACK)
                
                handler.post {
                    try {
                        android.widget.Toast.makeText(applicationContext, "Study Mode Active! Return to Focus.", android.widget.Toast.LENGTH_SHORT).show()
                    } catch (e: Exception) {}
                }
                return
            }
        }
        // --- End Study Mode Blocking ---
        
        // --- Uninstall Protection Logic ---
        if (cachedUninstallProtectionEnabled && packageName.lowercase() != "com.noorsoft.mindlock") {
            val rootNode = rootInActiveWindow
            if (rootNode != null) {
                if (checkForUninstallAttempt(rootNode, packageName)) {
                    Log.d("MindLock", "Blocked uninstall or deactivate attempt")
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    
                    try {
                        val intent = Intent(this, ReelsBlockActivity::class.java)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        startActivity(intent)
                    } catch (e: Exception) { }
                    
                    return
                }
            }
        }
        // --- End Uninstall Protection ---
        
        // --- App Use Limit Blocking ---
        if (cachedAppLimitsEnabled) {
            val limitedPackages = cachedAppLimitPackages

            if (limitedPackages.contains(packageName)) {
                val limitMins = try {
                    prefs.getLong("flutter.app_limit_mins_$packageName", 0L)
                } catch (e: Exception) {
                    try {
                        prefs.getInt("flutter.app_limit_mins_$packageName", 0).toLong()
                    } catch (e2: Exception) {
                        0L
                    }
                }

                if (limitMins > 0) {
                    val usageMs = getPackageUsageMsToday(packageName)
                    val usageMins = usageMs / (1000 * 60)
                    
                    if (usageMins >= limitMins) {
                        Log.d("MindLock", "App Limit Reached - Blocking App: $packageName ($usageMins mins vs $limitMins mins limit)")
                        performGlobalAction(GLOBAL_ACTION_HOME)
                        performGlobalAction(GLOBAL_ACTION_BACK)
                        
                        handler.post {
                            try {
                                android.widget.Toast.makeText(
                                    applicationContext,
                                    "Daily usage limit reached for this app!",
                                    android.widget.Toast.LENGTH_SHORT
                                ).show()
                            } catch (e: Exception) {}
                        }
                        return
                    }
                }
            }
        }
        // --- End App Use Limit Blocking ---
        
        if (!cachedReelsEnabled) return

        // Check if this specific package is blocked
        val blockedPackages = cachedBlockedPackages
        val isBlocked = if (blockedPackages.isNotEmpty()) {
            blockedPackages.contains(packageName)
        } else {
            isSocialMediaApp(packageName)
        }

        if (isBlocked) {
            // Instantly block TikTok without waiting for UI nodes to load
            val lowerPkg = packageName.lowercase()
            if (lowerPkg.contains("tiktok") || lowerPkg.contains("musically") || lowerPkg.contains("trill")) {
                Log.d("MindLock", "TikTok is entirely blocked")
                blockContent(aggressiveBlock = true)
                return
            }

            val rootNode = rootInActiveWindow ?: return
            
            // Exclusion: Messenger and direct typing
            if (packageName.contains("messenger", true)) return

            val analysis = performUIAnalysis(rootNode, packageName)
            val isInstagram = packageName.contains("instagram", ignoreCase = true)
            
            // For Facebook and others: Restoring previous logic.
            // If comment input is active, abort blocking to allow typing.
            if (!isInstagram) {
                if (analysis.isCommentInputActive || analysis.isCommentSectionActive) {
                    return
                }
            }

            // Reels block takes precedence for Instagram! 
            if (analysis.isReel || analysis.isYouTubeShorts) {
                Log.d("MindLock", "Reels/Shorts blocked in $packageName")
                blockContent(aggressiveBlock = false)
                return
            }

            // For Instagram: Otherwise, allow typing in normal non-Reels sections
            if (isInstagram) {
                if (analysis.isCommentInputActive || analysis.isCommentSectionActive) {
                    return
                }
            }
        }
    }

    private fun isSocialMediaApp(packageName: String): Boolean {
        val lowerPkg = packageName.lowercase()
        return lowerPkg.contains("facebook") || 
               lowerPkg.contains("instagram") || 
               lowerPkg.contains("youtube") || 
               lowerPkg.contains("tiktok")
    }

    class UIAnalysisResult {
        var isReel = false
        var isYouTubeShorts = false
        var isCommentInputActive = false
        var isCommentSectionActive = false
        var rightSideClickablesList = mutableListOf<android.graphics.Rect>()
        var hasMainNavigation = false
        
        // Button detection flags for the new Facebook formula
        var hasLike = false
        var hasComment = false
        var hasShare = false
    }

    private val analyzers = mapOf(
        "com.facebook.katana" to FacebookMainAnalyzer(),
        "com.facebook.lite" to FacebookLiteAnalyzer(),
        "instagram" to InstagramAnalyzer(),
        "youtube" to YouTubeAnalyzer(),
        "tiktok" to TikTokAnalyzer(),
        "musically" to TikTokAnalyzer(),
        "trill" to TikTokAnalyzer(),
        "chrome" to ChromeAnalyzer()
    )

    private fun performUIAnalysis(rootNode: AccessibilityNodeInfo, packageName: String): UIAnalysisResult {
        val result = UIAnalysisResult()
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        val isLite = packageName.lowercase().contains("lite")
        val analyzer = analyzers.entries.find { packageName.contains(it.key) }?.value

        traverseNode(rootNode, result, screenWidth, screenHeight, analyzer, isLite)
        
        // Generic logic for other apps (YouTube Shorts, etc.) that rely on vertical stacks
        // Facebook and Instagram handle their own fast detection directly in their Analyzers.
        if (!result.isReel && result.rightSideClickablesList.size >= 2) {
            var verticalSeparationCount = 0
            val list = result.rightSideClickablesList
            // Sort by Y coordinate to check sequence
            list.sortBy { it.top }
            
            for (i in 0 until list.size - 1) {
                val diffY = Math.abs(list[i].centerY() - list[i+1].centerY())
                val diffX = Math.abs(list[i].centerX() - list[i+1].centerX())
                
                // Vertical stack: Y changes significantly, X stays similar
                if (diffY > 70 && diffX < 200) verticalSeparationCount++
            }
            
            if (verticalSeparationCount >= 1 && result.rightSideClickablesList.size >= 3) {
                result.isReel = true
            } else if (verticalSeparationCount >= 2) {
                result.isReel = true
            }
        }

        // Master Override: If we are on the Home page/Main Navigation, it's NOT a standalone Reel
        // UNLESS it's Facebook Lite and we've already confirmed it's a selected Reels tab
        if (result.hasMainNavigation) {
            val isLiteReelsTab = packageName.contains("com.facebook.lite") && result.isReel
            if (!isLiteReelsTab) {
                result.isReel = false
            }
        }

        return result
    }

    private fun traverseNode(
        node: AccessibilityNodeInfo, 
        result: UIAnalysisResult,
        screenWidth: Int,
        screenHeight: Int,
        analyzer: IReelsAnalyzer?,
        isLite: Boolean
    ) {
        if (!node.isVisibleToUser) return

        val rect = android.graphics.Rect()
        node.getBoundsInScreen(rect)
        
        val text = node.text?.toString() ?: ""
        val desc = node.contentDescription?.toString() ?: ""
        val className = node.className?.toString() ?: ""

        // 1. Detect Typing (Universal Protection)
        if (className.contains("EditText", true) || node.isEditable) {
            result.isCommentInputActive = true
        }

        // 2. Dispatch to specialized "Formula" based on App (Separate Sections)
        analyzer?.analyze(node, rect, text, desc, result, screenWidth, screenHeight)

        // 3. Recursive traversal
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            child?.let {
                traverseNode(it, result, screenWidth, screenHeight, analyzer, isLite)
                it.recycle() // Recycle node to prevent memory leaks and out of nodes error
            }
        }
    }

    private fun containsAny(input: String, targets: List<String>): Boolean {
        if (input.isEmpty()) return false
        for (target in targets) {
            if (input.contains(target, ignoreCase = true)) return true
        }
        return false
    }

    private fun blockContent(aggressiveBlock: Boolean = false) {
        if (isBlockingActive) return
        isBlockingActive = true

        Log.d("MindLock", "Blocking Reels Action")
        
        if (aggressiveBlock) {
            // Aggressive mode for TikTok: Home action + multiple back actions to ensure it fully closes
            performGlobalAction(GLOBAL_ACTION_HOME)
            performGlobalAction(GLOBAL_ACTION_BACK)
            handler.postDelayed({ performGlobalAction(GLOBAL_ACTION_BACK) }, 100)
            handler.postDelayed({ performGlobalAction(GLOBAL_ACTION_BACK) }, 250)
            handler.postDelayed({ performGlobalAction(GLOBAL_ACTION_BACK) }, 400)
        } else {
            // 1. First perform the back action
            performGlobalAction(GLOBAL_ACTION_BACK)
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        prefs.edit().putString("flutter.active_overlay_type", "reels").apply()

        // 2. Wait for 500ms, then show the Motivational Popup
        handler.postDelayed({
            try {
                val intent = Intent(this, ReelsBlockActivity::class.java)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                startActivity(intent)
            } catch (e: Exception) {
                Log.e("MindLock", "Failed to launch overlay: ${e.message}")
            }
        }, 500)

        handler.postDelayed({
            isBlockingActive = false
        }, 3000)
    }

    override fun onInterrupt() {}

    override fun onServiceConnected() {
        super.getServiceInfo()?.let { info ->
            info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or 
                             AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            info.notificationTimeout = 100
            serviceInfo = info
        }
        Log.d("MindLock", "Accessibility Service Connected")
    }

    private fun checkForUninstallAttempt(rootNode: AccessibilityNodeInfo, packageName: String): Boolean {
        // Fix: Use the package name of the actual window we are inspecting to avoid timing/transition bugs
        val actualPackage = rootNode.packageName?.toString()?.lowercase() ?: packageName.lowercase()
        
        // Immediately return false if the active window belongs to our own app,
        // so we don't accidentally scan our own Uninstall Protection settings.
        if (actualPackage == "com.noorsoft.mindlock") return false

        var hasMindLockText = false
        var hasDangerousAction = false
        var hasUninstallDialogText = false
        var hasCombinedText = false
        
        fun traverse(node: AccessibilityNodeInfo?) {
            if (node == null) return
            
            val text = node.text?.toString()?.lowercase()?.trim() ?: ""
            val desc = node.contentDescription?.toString()?.lowercase()?.trim() ?: ""
            
            // Explicit targeted text
            if ((text.contains("uninstall") || text.contains("remove") || text.contains("delete")) && 
                (text.contains("mindlock") || text.contains("mind lock"))) {
                hasCombinedText = true
            }
            if ((desc.contains("uninstall") || desc.contains("remove") || desc.contains("delete")) && 
                (desc.contains("mindlock") || desc.contains("mind lock"))) {
                hasCombinedText = true
            }
            
            if (text == "mindlock" || text == "mind lock" || 
                desc == "mindlock" || desc == "mind lock") {
                hasMindLockText = true
            }
            
            if (text == "uninstall" || text == "force stop" || text == "deactivate" || 
                desc == "uninstall" || desc == "force stop" || desc == "deactivate" ||
                text == "remove" || desc == "remove") {
                hasDangerousAction = true
            }
            
            if (text.contains("do you want to uninstall") || text.contains("uninstall this app") ||
                desc.contains("do you want to uninstall") || desc.contains("uninstall this app")) {
                hasUninstallDialogText = true
            }
            
            for (i in 0 until node.childCount) {
                traverse(node.getChild(i))
            }
        }
        
        traverse(rootNode)
        
        if (hasCombinedText) return true

        val isSettings = actualPackage.contains("settings")
        val isInstaller = actualPackage.contains("installer") || actualPackage.contains("parser") || actualPackage.contains("securitycenter")
        
        // Scenario 1: In the Settings app, blocking access to MindLock's App Info page (where Force Stop / Uninstall buttons live)
        if (isSettings && hasMindLockText && hasDangerousAction) {
            return true
        }

        // Scenario 2: Standard Package Installers / Uninstallers trying to remove MindLock
        if (isInstaller && hasMindLockText && hasDangerousAction) {
            return true
        }

        // Scenario 3: Any other app (e.g., Launcher). We only block if we strictly detect an uninstall confirmation dialog for MindLock.
        // This prevents blocking other apps when long-pressing them on the home screen while the MindLock icon is visible.
        if (hasMindLockText && hasUninstallDialogText) {
            return true
        }
        
        return false
    }

    private fun getPackageUsageMsToday(packageName: String): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
        val calendar = java.util.Calendar.getInstance()
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        val start = calendar.timeInMillis
        val end = System.currentTimeMillis()

        // We need events from 24 hours before to catch apps that were already in the foreground
        val searchStart = start - (1000 * 60 * 60 * 24)
        val events = usageStatsManager.queryEvents(searchStart, end)
        
        var totalDuration = 0L
        var startTime: Long? = null
        
        val event = android.app.usage.UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.packageName == packageName) {
                if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    startTime = event.timeStamp
                } else if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND) {
                    if (startTime != null) {
                        // Math.max ensures we only count time strictly after exactly 12:00 AM local time today
                        val actualStart = Math.max(startTime, start)
                        val actualEnd = Math.min(event.timeStamp, end)
                        
                        if (actualEnd > actualStart) {
                            totalDuration += (actualEnd - actualStart)
                        }
                        startTime = null
                    }
                }
            }
        }
        
        // Handle apps currently in foreground at the current time
        if (startTime != null) {
            val actualStart = Math.max(startTime, start)
            val actualEnd = end
            if (actualEnd > actualStart) {
                totalDuration += (actualEnd - actualStart)
            }
        }
        
        return totalDuration
    }

    private fun getStringListFromPrefs(prefs: android.content.SharedPreferences, key: String): List<String> {
        try {
            val set = prefs.getStringSet(key, null)
            if (set != null) {
                return set.toList()
            }
        } catch (e: Exception) {
            // ClassCastException expected if stored as a prefixed string by newer Flutter SharedPreferences
        }

        try {
            val str = prefs.getString(key, null)
            if (str != null && str.startsWith("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!")) {
                val jsonStr = str.substring("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!".length)
                return parseJsonStringList(jsonStr)
            }
        } catch (e: Exception) {
            Log.e("MindLock", "Error parsing string list for key $key: ${e.message}")
        }

        return emptyList()
    }

    private fun parseJsonStringList(jsonStr: String): List<String> {
        val result = mutableListOf<String>()
        val cleaned = jsonStr.trim().removeSurrounding("[", "]")
        if (cleaned.isEmpty()) return result
        
        val parts = cleaned.split(",")
        for (part in parts) {
            val element = part.trim().removeSurrounding("\"")
            if (element.isNotEmpty()) {
                result.add(element)
            }
        }
        return result
    }
}
