import Foundation
import GameKit

/// Tracks and manages achievement progress for CrossSums game
/// 
/// This service monitors gameplay events and automatically updates Game Center achievements
/// based on player actions and accomplishments.
@MainActor
class AchievementTracker: ObservableObject {
    
    // MARK: - Properties
    
    private let gameCenterManager: GameCenterManager
    private var consecutiveLevelsCompleted: Int = 0
    private var puzzlesCompletedWithoutHints: Int = 0
    private var puzzlesCompletedWithoutMistakes: Int = 0
    
    // MARK: - Initialization
    
    init(gameCenterManager: GameCenterManager = .shared) {
        self.gameCenterManager = gameCenterManager
    }
    
    // MARK: - Achievement Tracking Methods
    
    /// Called when a level is completed
    /// - Parameters:
    ///   - level: The level number completed
    ///   - difficulty: The difficulty level
    ///   - completionTime: Time taken to complete in seconds
    ///   - movesUsed: Number of moves made
    ///   - hintsUsed: Number of hints used
    ///   - mistakesMade: Number of mistakes made
    ///   - playerProfile: Current player profile
    func trackLevelCompletion(
        level: Int,
        difficulty: String,
        completionTime: TimeInterval,
        movesUsed: Int,
        hintsUsed: Int,
        mistakesMade: Int,
        playerProfile: PlayerProfile
    ) {
        // Track consecutive completions
        consecutiveLevelsCompleted += 1
        
        // Track hint-free and mistake-free streaks
        if hintsUsed == 0 {
            puzzlesCompletedWithoutHints += 1
        } else {
            puzzlesCompletedWithoutHints = 0
        }
        
        if mistakesMade == 0 {
            puzzlesCompletedWithoutMistakes += 1
        } else {
            puzzlesCompletedWithoutMistakes = 0
        }
        
        // Check progression achievements
        checkProgressionAchievements(playerProfile: playerProfile)
        
        // Check speed achievements
        checkSpeedAchievements(completionTime: completionTime)
        
        // Check difficulty-specific achievements
        checkDifficultyAchievements(level: level, difficulty: difficulty, playerProfile: playerProfile)
        
        // Check efficiency achievements
        checkEfficiencyAchievements(hintsUsed: hintsUsed, mistakesMade: mistakesMade)
        
        // Check streak achievements
        checkStreakAchievements()
    }
    
    /// Called when a level is failed or restarted
    func trackLevelReset() {
        consecutiveLevelsCompleted = 0
        puzzlesCompletedWithoutHints = 0
        puzzlesCompletedWithoutMistakes = 0
    }
    
    /// Called when a daily puzzle is completed
    /// - Parameters:
    ///   - completionTime: Time taken to complete in seconds
    ///   - streak: Current daily streak
    ///   - totalDailyCompleted: Total daily puzzles completed
    func trackDailyPuzzleCompletion(
        completionTime: TimeInterval,
        streak: Int,
        totalDailyCompleted: Int
    ) {
        // Daily Player - Complete your first daily puzzle
        if totalDailyCompleted >= 1 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.dailyPlayer)
        }
        
        // Daily Streak Week - Complete 7 consecutive daily puzzles
        if streak >= 7 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.dailyStreakWeek)
        }
        
        // Daily Streak Month - Complete 30 consecutive daily puzzles
        if streak >= 30 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.dailyStreakMonth)
        }
        
        // Daily Speedster - Complete a daily puzzle in under 60 seconds
        if completionTime < 60 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.dailySpeedster)
        }
    }
    
    // MARK: - Private Achievement Checking Methods
    
    private func checkProgressionAchievements(playerProfile: PlayerProfile) {
        let totalCompleted = playerProfile.totalLevelsCompleted
        
        // First Steps - Complete your first level
        if totalCompleted >= 1 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.firstSteps)
        }
        
        // Getting Serious - Complete 10 levels
        if totalCompleted >= 10 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.gettingSerious)
        }
        
        // Expert - Complete 50 levels
        if totalCompleted >= 50 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.expert)
        }
        
        // Master - Complete 100 levels
        if totalCompleted >= 100 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.master)
        }
    }
    
    private func checkSpeedAchievements(completionTime: TimeInterval) {
        // Lightning Fast - Complete a puzzle in under 30 seconds
        if completionTime < 30.0 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.lightningFast)
        }
        
        // Speed Demon - Complete 10 puzzles under 1 minute (tracked separately)
        // This would need additional tracking in a real implementation
    }
    
    private func checkDifficultyAchievements(level: Int, difficulty: String, playerProfile: PlayerProfile) {
        let highestLevel = playerProfile.getHighestLevel(for: difficulty)
        
        switch difficulty.lowercased() {
        case "easy":
            // Easy Master - Complete 25 Easy levels
            if highestLevel >= 25 {
                gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.easyMaster)
            }
            
        case "medium":
            // Medium Master - Complete 15 Medium levels
            if highestLevel >= 15 {
                gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.mediumMaster)
            }
            
        case "hard":
            // Hard Core - Complete 10 Hard levels
            if highestLevel >= 10 {
                gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.hardCore)
            }
            
        case "extra hard":
            // Extra Hard Elite - Complete 5 Extra Hard levels
            if highestLevel >= 5 {
                gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.extraHardElite)
            }
            
        default:
            break
        }
    }
    
    private func checkEfficiencyAchievements(hintsUsed: Int, mistakesMade: Int) {
        // Perfectionist - Complete a puzzle without mistakes
        if mistakesMade == 0 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.perfectionist)
        }
        
        // Hint Free - Complete 10 puzzles without using hints
        if puzzlesCompletedWithoutHints >= 10 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.hintFree)
        }
        
        // No Mistakes - Complete 5 puzzles in a row without mistakes
        if puzzlesCompletedWithoutMistakes >= 5 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.noMistakes)
        }
    }
    
    private func checkStreakAchievements() {
        // On Fire - Complete 5 levels in a row
        if consecutiveLevelsCompleted >= 5 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.onFire)
        }
        
        // Unstoppable - Complete 25 levels in a row
        if consecutiveLevelsCompleted >= 25 {
            gameCenterManager.unlockAchievement(GameCenterManager.AchievementIDs.unstoppable)
        }
    }
    
    // MARK: - Progress Tracking Methods
    
    /// Updates incremental achievements with current progress
    /// - Parameter playerProfile: Current player profile
    func updateIncrementalAchievements(playerProfile: PlayerProfile) {
        let totalCompleted = playerProfile.totalLevelsCompleted
        
        // Update progression achievements with incremental progress
        updateProgressionProgress(totalCompleted: totalCompleted)
        
        // Update difficulty-specific achievements
        updateDifficultyProgress(playerProfile: playerProfile)
    }
    
    private func updateProgressionProgress(totalCompleted: Int) {
        // Getting Serious (10 levels) - show progress
        if totalCompleted < 10 {
            let progress = Double(totalCompleted) / 10.0 * 100.0
            gameCenterManager.reportAchievementProgress(
                GameCenterManager.AchievementIDs.gettingSerious,
                percentComplete: progress,
                showsBanner: false
            )
        }
        
        // Expert (50 levels) - show progress
        if totalCompleted < 50 {
            let progress = Double(totalCompleted) / 50.0 * 100.0
            gameCenterManager.reportAchievementProgress(
                GameCenterManager.AchievementIDs.expert,
                percentComplete: progress,
                showsBanner: false
            )
        }
        
        // Master (100 levels) - show progress
        if totalCompleted < 100 {
            let progress = Double(totalCompleted) / 100.0 * 100.0
            gameCenterManager.reportAchievementProgress(
                GameCenterManager.AchievementIDs.master,
                percentComplete: progress,
                showsBanner: false
            )
        }
    }
    
    private func updateDifficultyProgress(playerProfile: PlayerProfile) {
        // Easy Master progress
        let easyProgress = Double(playerProfile.getHighestLevel(for: "Easy")) / 25.0 * 100.0
        if easyProgress < 100.0 {
            gameCenterManager.reportAchievementProgress(
                GameCenterManager.AchievementIDs.easyMaster,
                percentComplete: easyProgress,
                showsBanner: false
            )
        }
        
        // Medium Master progress
        let mediumProgress = Double(playerProfile.getHighestLevel(for: "Medium")) / 15.0 * 100.0
        if mediumProgress < 100.0 {
            gameCenterManager.reportAchievementProgress(
                GameCenterManager.AchievementIDs.mediumMaster,
                percentComplete: mediumProgress,
                showsBanner: false
            )
        }
        
        // Hard Core progress
        let hardProgress = Double(playerProfile.getHighestLevel(for: "Hard")) / 10.0 * 100.0
        if hardProgress < 100.0 {
            gameCenterManager.reportAchievementProgress(
                GameCenterManager.AchievementIDs.hardCore,
                percentComplete: hardProgress,
                showsBanner: false
            )
        }
        
        // Extra Hard Elite progress
        let extraHardProgress = Double(playerProfile.getHighestLevel(for: "Extra Hard")) / 5.0 * 100.0
        if extraHardProgress < 100.0 {
            gameCenterManager.reportAchievementProgress(
                GameCenterManager.AchievementIDs.extraHardElite,
                percentComplete: extraHardProgress,
                showsBanner: false
            )
        }
    }
}