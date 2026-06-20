package com.example.mindlock

import android.view.accessibility.AccessibilityNodeInfo
import android.graphics.Rect

/**
 * Interface for specialized app analyzers.
 * Each implementation represents a "Separate Section" for a specific app's Reels blocking formula.
 */
interface IReelsAnalyzer {
    fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int)
}

// ==========================================
// SECTION: FACEBOOK MAIN
// ==========================================
class FacebookMainAnalyzer : IReelsAnalyzer {
    override fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {
        
        // NEW FORMULA: Detect Like, Comment, and Share buttons on the far right
        // At least 2 out of these 3 must be true and vertical to trigger a block.
        if (rect.left > screenWidth * 0.7 && rect.top > screenHeight * 0.1 && rect.bottom < screenHeight * 0.9) {
            
            val isLike = text.contains("Like", true) || desc.contains("Like", true) || 
                         text.contains("পছন্দ", true) || desc.contains("পছন্দ", true) ||
                         desc.contains("Double tap to like", true)
                         
            val isComment = text.contains("Comment", true) || desc.contains("Comment", true) || 
                            text.contains("মন্তব্য", true) || desc.contains("মন্তব্য", true)
                            
            val isShare = text.contains("Share", true) || desc.contains("Share", true) || 
                          text.contains("শেয়ার", true) || desc.contains("শেয়ার", true) ||
                          desc.contains("Send this", true)
            
            if (isLike) result.hasLike = true
            if (isComment) result.hasComment = true
            if (isShare) result.hasShare = true
            
            // If any of these 3 buttons or a clickable icon with a number is found on the right
            if (isLike || isComment || isShare || (node.isClickable && text.matches(Regex(".*\\d+.*")))) {
                if (rect.width() < screenWidth * 0.4) {
                    result.rightSideClickablesList.add(Rect(rect))
                }
            }
        }
    }
}

// ==========================================
// SECTION: FACEBOOK LITE
// ==========================================
class FacebookLiteAnalyzer : IReelsAnalyzer {
    override fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {
        val cleanText = text.trim()
        val cleanDesc = desc.trim()

        // 1. Detect Selected "Reels" Tab in the Top Navigation
        if (rect.top < screenHeight * 0.15) {
            val isReelsTab = (cleanText.equals("Reels", true) || cleanDesc.contains("Reels", true)) && 
                             (cleanDesc.contains("Selected", true) || node.isSelected || node.isFocused)
            
            if (isReelsTab) {
                result.isReel = true 
            }

            val isOtherTab = cleanDesc.contains("Home", true) || cleanDesc.contains("Friends", true) || 
                            cleanDesc.contains("Notifications", true) || cleanDesc.contains("Marketplace", true) ||
                            cleanText.contains("Home", true)
            
            if (isOtherTab) result.hasMainNavigation = true
        }

        // 2. Detect Big "Reels" Header
        if (cleanText.equals("Reels", true) || cleanText.equals("রিলস", true)) {
            if (rect.top > screenHeight * 0.05 && rect.top < screenHeight * 0.25 && rect.left < screenWidth * 0.5) {
                result.isReel = true 
            }
        }

        // 3. Collect Interaction Buttons and Counts on the Far Right
        if (rect.left > screenWidth * 0.75 && rect.top > screenHeight * 0.15 && rect.bottom < screenHeight * 0.95) {
            val containsNumber = cleanText.matches(Regex("\\d+.*"))
            val isInteractionIcon = node.isClickable && rect.width() < screenWidth * 0.3
            
            if (containsNumber || isInteractionIcon) {
                result.rightSideClickablesList.add(Rect(rect))
            }
        }
    }
}

// ==========================================
// SECTION: INSTAGRAM
// ==========================================
class InstagramAnalyzer : IReelsAnalyzer {
    override fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {
        if (text.equals("Reels", true) || desc.contains("Reels", true)) {
            if (rect.top < screenHeight * 0.15) result.isReel = true
        }

        if (rect.left > screenWidth * 0.8 && rect.top > screenHeight * 0.3) {
            if (node.isClickable || desc.contains("button", true)) {
                result.rightSideClickablesList.add(Rect(rect))
            }
        }
    }
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
// SECTION: TIKTOK
// ==========================================
class TikTokAnalyzer : IReelsAnalyzer {
    override fun analyze(node: AccessibilityNodeInfo, rect: Rect, text: String, desc: String, result: MindLockAccessibilityService.UIAnalysisResult, screenWidth: Int, screenHeight: Int) {
        if (text.contains("For You", true) || text.contains("Following", true)) {
            if (rect.top < screenHeight * 0.15) result.isReel = true
        }

        if (rect.left > screenWidth * 0.8 && rect.top > screenHeight * 0.2) {
            if (node.isClickable || desc.contains("Like", true) || desc.contains("Comment", true)) {
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
