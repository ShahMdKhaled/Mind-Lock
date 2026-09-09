package com.noorsoft.mindlock

import android.view.accessibility.AccessibilityNodeInfo
import android.graphics.Rect

/**
 * Interface for specialized app analyzers.
 * Each implementation represents a "Separate Section" for a specific app's Reels blocking formula.
 */
interface IReelsAnalyzer {
    // Phase 1: Pre-analysis (Instant blocking)
    fun shouldInstantBlock(): Boolean = false
    fun isAggressiveBlock(): Boolean = false
    
    // Phase 2: Per-node analysis
    fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {}
    
    // Phase 3: Post-traversal evaluation (adjusting flags based on whole tree)
    fun postAnalyze(result: MindLockAccessibilityService.UIAnalysisResult) {}
    
    // Phase 4: Decision making
    fun shouldBlock(result: MindLockAccessibilityService.UIAnalysisResult): Boolean {
        if (result.hasMainNavigation) return false
        if (result.isCommentInputActive || result.isCommentSectionActive) return false
        return result.isReel || result.isYouTubeShorts
    }
}

// ==========================================
// SECTION: FACEBOOK MAIN
// ==========================================
class FacebookMainAnalyzer : IReelsAnalyzer {
    companion object {
        // Cached Regex: compiled once, reused across all analyze() calls to avoid GC pressure
        private val REEL_STAT_REGEX = Regex("^[0-9.,]+[kKmM]?\\s*(likes?|comments?|shares?|plays?|views?)?$", RegexOption.IGNORE_CASE)
    }

    override fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {
        
        if (result.isReel) return
        
        val cleanText = text.trim()
        val cleanDesc = desc.trim()

        // 1. Performance optimization: skip large texts immediately to reduce CPU pressure.
        if (cleanText.length > 50 || cleanDesc.length > 50) return

        // 2. Scan the right side of the screen (where Reels buttons are vertically stacked)
        if (rect.left > screenWidth * 0.7 && rect.top > screenHeight * 0.1 && rect.bottom < screenHeight * 0.9) {
            
            // Conditional string matching: skip contains() checks for flags already detected
            if (!result.hasLike) {
                val isLike = cleanText.contains("Like", true) || cleanDesc.contains("Like", true) || 
                             cleanText.contains("পছন্দ", true) || cleanDesc.contains("পছন্দ", true) ||
                             cleanDesc.contains("Double tap to like", true)
                if (isLike) result.hasLike = true
            }
                         
            if (!result.hasComment) {
                val isComment = cleanText.contains("Comment", true) || cleanDesc.contains("Comment", true) || 
                                cleanText.contains("মন্তব্য", true) || cleanDesc.contains("মন্তব্য", true)
                if (isComment) result.hasComment = true
            }
                            
            if (!result.hasShare) {
                val isShare = cleanText.contains("Share", true) || cleanDesc.contains("Share", true) || 
                              cleanText.contains("শেয়ার", true) || cleanDesc.contains("শেয়ার", true) ||
                              cleanDesc.contains("Send this", true)
                if (isShare) result.hasShare = true
            }
            
            // Robust numeric matching using cached Regex to allow formats like "1.5K" or "10K Likes"
            val isNumericText = cleanText.isNotEmpty() && cleanText.matches(REEL_STAT_REGEX)
            val isNumericDesc = cleanDesc.isNotEmpty() && cleanDesc.matches(REEL_STAT_REGEX)
            
            if (isNumericText) result.numericStrings.add(cleanText)
            if (isNumericDesc) result.numericStrings.add(cleanDesc)
            
            // Check for Shopping Post
            val isShop = cleanText.contains("shop", true) || cleanDesc.contains("shop", true) ||
                         cleanText.contains("shop now", true) || cleanDesc.contains("shop now", true)
            if (isShop) {
                result.isShoppingPost = true
            }

            // Check for Excluded Actions (User requested)
            val isExcluded = cleanText.contains("remove", true) || cleanDesc.contains("remove", true) ||
                             cleanText.contains("add friend", true) || cleanDesc.contains("add friend", true) ||
                             cleanText.contains("download", true) || cleanDesc.contains("download", true) ||
                             cleanText.contains("install", true) || cleanDesc.contains("install", true)
            if (isExcluded) {
                result.isExcludedPost = true
            }
            
            // We no longer set isReel here or early exit. 
            // We evaluate the totals after traversing the whole tree.
            
            // Fallback for unlabeled/icon-only buttons (which Facebook often uses)
            // Add purely numeric clickables OR unnamed clickables to rightSideClickablesList 
            // so the generic vertical stack detector can find the 3 stacked Reel icons.
            if (node.isClickable && rect.width() < screenWidth * 0.4) {
                val isUnnamedIcon = cleanText.isEmpty() && cleanDesc.isEmpty()
                if (isNumericText || isNumericDesc || isUnnamedIcon) {
                    result.rightSideClickablesList.add(Rect(rect))
                }
            }
        }
    }

    override fun postAnalyze(result: MindLockAccessibilityService.UIAnalysisResult) {
        val fbFoundCount = (if (result.hasLike) 1 else 0) + 
                           (if (result.hasComment) 1 else 0) + 
                           (if (result.hasShare) 1 else 0) + 
                           result.numericStrings.size
                           
        if (result.isShoppingPost || result.isExcludedPost) {
            // User requested: If "shop", "shop now", "remove", "add friend", "download", "install" is present, DO NOT block
            result.isReel = false
            result.rightSideClickablesList.clear()
        } else if (fbFoundCount >= 3) {
            // If it finds 3 or 4, it is a Reel
            result.isReel = true
        } else if (fbFoundCount == 1 || fbFoundCount == 2) {
            // User requested: If it finds exactly 1 or 2, it should NOT block
            result.isReel = false
            result.rightSideClickablesList.clear()
        }
    }
}

// ==========================================
// SECTION: FACEBOOK LITE
// ==========================================
class FacebookLiteAnalyzer : IReelsAnalyzer {
    override fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {
        val cleanDesc = desc.trim()

        if (result.isReel) return

        // Optional check: Double tap to like
        if (cleanDesc.contains("Double tap to like", true)) {
            result.isReel = true
            return
        }

        // Scan Area: Bottom 45% of the screen (top > 55%) and Right 30% of the screen (left > 70%)
        if (rect.top > screenHeight * 0.55 && rect.left > screenWidth * 0.70) {
            
            // Look for buttons (clickables) to check if 3 of them are stacked vertically
            // The generic vertical stack detector in MindLockAccessibilityService will handle the '3 buttons' logic
            if (node.isClickable) {
                result.rightSideClickablesList.add(Rect(rect))
            }
        }
    }
    
    override fun shouldBlock(result: MindLockAccessibilityService.UIAnalysisResult): Boolean {
        if (result.isCommentInputActive || result.isCommentSectionActive) return false
        // For Facebook Lite, if it's a Reels tab, we block even if hasMainNavigation is true
        return result.isReel || result.isYouTubeShorts
    }
}

// ==========================================
// SECTION: INSTAGRAM
// ==========================================
class InstagramAnalyzer : IReelsAnalyzer {
    override fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {
        val cleanText = text.trim()
        val cleanDesc = desc.trim()

        // Exact match to avoid false positives from "Suggested Reels" text in the feed
        val isExactReels = cleanText.equals("Reels", true) || cleanDesc.equals("Reels", true) || cleanText.equals("রিলস", true)

        if (isExactReels) {
            if (rect.top < screenHeight * 0.15) {
                result.isReel = true
            }
            if (node.isSelected) {
                result.isReel = true
            }
        }

        // Avoid top 30% (app bar/notifications) and bottom 10% (navigation bar)
        if (rect.left > screenWidth * 0.75 && rect.top > screenHeight * 0.3 && rect.bottom < screenHeight * 0.9) {
            val isLike = cleanDesc.contains("like", true) || cleanDesc.contains("love", true)
            val isComment = cleanDesc.contains("comment", true)
            val isRepost = cleanDesc.contains("share", true) || cleanDesc.contains("send", true) || cleanDesc.contains("repost", true)
            
            if (isLike) result.hasLike = true
            if (isComment) result.hasComment = true
            if (isRepost) result.hasShare = true

            val foundCount = (if (result.hasLike) 1 else 0) + (if (result.hasComment) 1 else 0) + (if (result.hasShare) 1 else 0)
            if (foundCount >= 2) {
                result.isReel = true
            }

            if (isLike || isComment || isRepost) {
                result.rightSideClickablesList.add(Rect(rect))
            }
        }
    }
    
    override fun shouldBlock(result: MindLockAccessibilityService.UIAnalysisResult): Boolean {
        // Reels block takes precedence for Instagram!
        if (result.isReel || result.isYouTubeShorts) return true
        
        // Otherwise, allow typing in normal non-Reels sections
        if (result.isCommentInputActive || result.isCommentSectionActive) return false
        
        return false
    }
}

// ==========================================
// SECTION: TIKTOK
// ==========================================
class TikTokAnalyzer : IReelsAnalyzer {
    override fun shouldInstantBlock(): Boolean = true
    override fun isAggressiveBlock(): Boolean = true
}

// ==========================================
// SECTION: YOUTUBE
// ==========================================
class YouTubeAnalyzer : IReelsAnalyzer {
    override fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {
        if (desc.contains("Shorts player", true) || text.contains("Remix", true) || desc.contains("Remix", true)) {
            result.isYouTubeShorts = true
        }

        if (rect.left > screenWidth * 0.8 && rect.top > screenHeight * 0.2) {
            if (desc.contains("Like", true) || desc.contains("Dislike", true) || desc.contains("Comments", true)) {
                result.rightSideClickablesList.add(Rect(rect))
            }
        }
    }
}



// ==========================================
// SECTION: CHROME
// ==========================================
class ChromeAnalyzer : IReelsAnalyzer {
    override fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {
        val content = if (text.isNotEmpty()) text else desc
        if (content.contains("youtube.com/shorts", true) || 
            content.contains("instagram.com/reels", true) || 
            content.contains("facebook.com/reels", true)) {
            result.isReel = true
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
