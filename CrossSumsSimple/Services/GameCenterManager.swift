import Foundation
import GameKit

/// Manager for all Game Center functionality including authentication, leaderboards, and achievements
/// 
/// Provides a unified interface for Game Center services while handling authentication state,
/// network connectivity, and platform differences between iOS and Mac.
@MainActor
class GameCenterManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the player is authenticated with Game Center
    @Published var isAuthenticated: Bool = false
    
    /// Whether Game Center is available on this device
    @Published var isAvailable: Bool = false
    
    /// The authenticated player's information
    @Published var localPlayer: GKLocalPlayer?
    
    /// Current authentication error, if any
    @Published var authenticationError: String?
    
    // MARK: - Constants
    
    /// Leaderboard identifiers for completion times (fastest puzzle completion)
    struct LeaderboardIDs {
        static let easyFastest = "crosssums.easy.fastest"
        static let mediumFastest = "crosssums.medium.fastest"
        static let hardFastest = "crosssums.hard.fastest"
        static let extraHardFastest = "crosssums.extrahard.fastest"
        
        static let easyHighest = "crosssums.easy.highest"
        static let mediumHighest = "crosssums.medium.highest"
        static let hardHighest = "crosssums.hard.highest"
        static let extraHardHighest = "crosssums.extrahard.highest"
    }
    
    /// Achievement identifiers
    struct AchievementIDs {
        // Progression achievements
        static let firstSteps = "crosssums.achievement.first_steps"
        static let gettingSerious = "crosssums.achievement.getting_serious"
        static let expert = "crosssums.achievement.expert"
        static let master = "crosssums.achievement.master"
        
        // Speed achievements
        static let lightningFast = "crosssums.achievement.lightning_fast"
        static let speedDemon = "crosssums.achievement.speed_demon"
        
        // Difficulty achievements
        static let easyMaster = "crosssums.achievement.easy_master"
        static let mediumMaster = "crosssums.achievement.medium_master"
        static let hardCore = "crosssums.achievement.hard_core"
        static let extraHardElite = "crosssums.achievement.extrahard_elite"
        
        // Efficiency achievements
        static let perfectionist = "crosssums.achievement.perfectionist"
        static let hintFree = "crosssums.achievement.hint_free"
        static let noMistakes = "crosssums.achievement.no_mistakes"
        
        // Streak achievements
        static let onFire = "crosssums.achievement.on_fire"
        static let unstoppable = "crosssums.achievement.unstoppable"
    }
    
    // MARK: - Singleton
    
    static let shared = GameCenterManager()
    
    private override init() {
        super.init()
        checkGameCenterAvailability()
    }
    
    // MARK: - Authentication
    
    /// Authenticates the local player with Game Center
    func authenticatePlayer() {
        guard isAvailable else {
            print("⚠️ Game Center is not available")
            authenticationError = "Game Center is not available on this device"
            return
        }
        
        localPlayer = GKLocalPlayer.local
        localPlayer?.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                self?.handleAuthentication(viewController: viewController, error: error)
            }
        }
    }
    
    private func handleAuthentication(viewController: UIViewController?, error: Error?) {
        if let error = error {
            print("❌ Game Center authentication error: \(error.localizedDescription)")
            authenticationError = error.localizedDescription
            isAuthenticated = false
            return
        }
        
        if let viewController = viewController {
            // Present authentication view controller to the user
            presentAuthenticationViewController(viewController)
            print("🔐 Presenting Game Center authentication UI")
            return
        }
        
        // Authentication successful
        if localPlayer?.isAuthenticated == true {
            print("✅ Game Center authenticated: \(localPlayer?.displayName ?? "Unknown Player")")
            isAuthenticated = true
            authenticationError = nil
            configureAccessPoint(isAuthenticated: true)
        } else {
            print("⚠️ Game Center authentication status unclear")
            isAuthenticated = false
            authenticationError = "Authentication status unclear"
            configureAccessPoint(isAuthenticated: false)
        }
    }
    
    private func checkGameCenterAvailability() {
        #if os(iOS)
        isAvailable = true
        #elseif os(macOS)
        // Game Center is available on macOS 10.14+
        if #available(macOS 10.14, *) {
            isAvailable = true
        } else {
            isAvailable = false
        }
        #else
        isAvailable = false
        #endif
    }
    
    // MARK: - Access Point Configuration (iOS 14+)
    
    /// Configures the Game Center access point for iOS 14+
    /// - Parameter isAuthenticated: Whether the player is authenticated
    private func configureAccessPoint(isAuthenticated: Bool) {
        if #available(iOS 14.0, macOS 11.0, *) {
            GKAccessPoint.shared.location = .topLeading
            GKAccessPoint.shared.showHighlights = true
            GKAccessPoint.shared.isActive = isAuthenticated
            print("🎮 Game Center access point configured: \(isAuthenticated ? "active" : "inactive")")
        }
    }
    
    /// Shows the Game Center access point
    func showAccessPoint() {
        if #available(iOS 14.0, macOS 11.0, *) {
            GKAccessPoint.shared.isActive = isAuthenticated
            print("🎮 Game Center access point shown")
        }
    }
    
    /// Hides the Game Center access point
    func hideAccessPoint() {
        if #available(iOS 14.0, macOS 11.0, *) {
            GKAccessPoint.shared.isActive = false
            print("🎮 Game Center access point hidden")
        }
    }
    
    // MARK: - Leaderboards
    
    /// Submits a completion time score to the appropriate leaderboard
    /// - Parameters:
    ///   - timeInSeconds: The completion time in seconds
    ///   - difficulty: The difficulty level ("Easy", "Medium", "Hard", "Extra Hard")
    func submitCompletionTime(_ timeInSeconds: TimeInterval, difficulty: String) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit score - not authenticated")
            return
        }
        
        let leaderboardID = getCompletionTimeLeaderboardID(for: difficulty)
        guard !leaderboardID.isEmpty else {
            print("⚠️ Unknown difficulty for leaderboard: \(difficulty)")
            return
        }
        
        // Convert time to milliseconds for better precision in scores
        let scoreValue = Int64(timeInSeconds * 1000)
        
        if #available(iOS 14.0, macOS 11.0, *) {
            // Use modern API for iOS 14+
            GKLeaderboard.submitScore(
                Int(scoreValue),
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            ) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to submit completion time score: \(error.localizedDescription)")
                    } else {
                        print("✅ Submitted completion time: \(timeInSeconds)s for \(difficulty)")
                    }
                }
            }
        } else {
            // Fallback to legacy API for iOS 13 and earlier
            let score = GKScore(leaderboardIdentifier: leaderboardID)
            score.value = scoreValue
            score.context = 0
            
            GKScore.report([score]) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to submit completion time score: \(error.localizedDescription)")
                    } else {
                        print("✅ Submitted completion time: \(timeInSeconds)s for \(difficulty)")
                    }
                }
            }
        }
    }
    
    /// Submits a highest level reached score to the appropriate leaderboard
    /// - Parameters:
    ///   - level: The highest level reached
    ///   - difficulty: The difficulty level
    func submitHighestLevel(_ level: Int, difficulty: String) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit score - not authenticated")
            return
        }
        
        let leaderboardID = getHighestLevelLeaderboardID(for: difficulty)
        guard !leaderboardID.isEmpty else {
            print("⚠️ Unknown difficulty for leaderboard: \(difficulty)")
            return
        }
        
        if #available(iOS 14.0, macOS 11.0, *) {
            // Use modern API for iOS 14+
            GKLeaderboard.submitScore(
                level,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            ) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to submit highest level score: \(error.localizedDescription)")
                    } else {
                        print("✅ Submitted highest level: \(level) for \(difficulty)")
                    }
                }
            }
        } else {
            // Fallback to legacy API for iOS 13 and earlier
            let score = GKScore(leaderboardIdentifier: leaderboardID)
            score.value = Int64(level)
            score.context = 0
            
            GKScore.report([score]) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to submit highest level score: \(error.localizedDescription)")
                    } else {
                        print("✅ Submitted highest level: \(level) for \(difficulty)")
                    }
                }
            }
        }
    }
    
    private func getCompletionTimeLeaderboardID(for difficulty: String) -> String {
        switch difficulty.lowercased() {
        case "easy": return LeaderboardIDs.easyFastest
        case "medium": return LeaderboardIDs.mediumFastest
        case "hard": return LeaderboardIDs.hardFastest
        case "extra hard": return LeaderboardIDs.extraHardFastest
        default: return ""
        }
    }
    
    private func getHighestLevelLeaderboardID(for difficulty: String) -> String {
        switch difficulty.lowercased() {
        case "easy": return LeaderboardIDs.easyHighest
        case "medium": return LeaderboardIDs.mediumHighest
        case "hard": return LeaderboardIDs.hardHighest
        case "extra hard": return LeaderboardIDs.extraHardHighest
        default: return ""
        }
    }
    
    // MARK: - Achievements
    
    /// Reports progress for an achievement
    /// - Parameters:
    ///   - identifier: The achievement identifier
    ///   - percentComplete: Progress percentage (0.0 to 100.0)
    ///   - showsBanner: Whether to show completion banner
    func reportAchievementProgress(_ identifier: String, percentComplete: Double, showsBanner: Bool = true) {
        guard isAuthenticated else {
            print("⚠️ Cannot report achievement - not authenticated")
            return
        }
        
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = min(100.0, max(0.0, percentComplete))
        achievement.showsCompletionBanner = showsBanner
        
        GKAchievement.report([achievement]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to report achievement: \(error.localizedDescription)")
                } else {
                    print("✅ Reported achievement progress: \(identifier) - \(percentComplete)%")
                }
            }
        }
    }
    
    /// Unlocks an achievement (sets to 100% complete)
    /// - Parameter identifier: The achievement identifier
    func unlockAchievement(_ identifier: String) {
        reportAchievementProgress(identifier, percentComplete: 100.0, showsBanner: true)
    }
    
    // MARK: - UI Presentation
    
    /// Presents the Game Center leaderboards view
    func showLeaderboards() {
        guard isAuthenticated else {
            print("⚠️ Cannot show leaderboards - not authenticated")
            return
        }
        
        let viewController = GKGameCenterViewController(state: .leaderboards)
        viewController.gameCenterDelegate = self
        
        presentGameCenterViewController(viewController)
    }
    
    /// Presents the Game Center achievements view
    func showAchievements() {
        guard isAuthenticated else {
            print("⚠️ Cannot show achievements - not authenticated")
            return
        }
        
        let viewController = GKGameCenterViewController(state: .achievements)
        viewController.gameCenterDelegate = self
        
        presentGameCenterViewController(viewController)
    }
    
    /// Presents the Game Center dashboard
    func showGameCenter() {
        guard isAuthenticated else {
            print("⚠️ Cannot show Game Center - not authenticated")
            return
        }
        
        let viewController = GKGameCenterViewController(state: .dashboard)
        viewController.gameCenterDelegate = self
        
        presentGameCenterViewController(viewController)
    }
    
    /// Presents a Game Center authentication view controller
    /// - Parameter viewController: The authentication view controller to present
    private func presentAuthenticationViewController(_ viewController: UIViewController) {
        #if os(iOS)
        // On iOS, find the root view controller and present the authentication UI
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(viewController, animated: true)
            print("🔐 Presenting Game Center authentication on iOS")
        } else {
            print("❌ Could not find root view controller for authentication")
            authenticationError = "Could not present authentication UI"
        }
        #elseif os(macOS)
        // On macOS, present the authentication view controller
        print("🔐 Presenting Game Center authentication on macOS")
        // Note: macOS may handle authentication differently in some cases
        #endif
    }
    
    /// Presents a Game Center view controller (leaderboards, achievements, etc.)
    /// - Parameter viewController: The Game Center view controller to present
    private func presentGameCenterViewController(_ viewController: GKGameCenterViewController) {
        print("🎮 Presenting Game Center view controller")
        
        #if os(iOS)
        // On iOS, find the root view controller and present
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(viewController, animated: true)
        }
        #elseif os(macOS)
        // On macOS, Game Center uses different presentation methods
        print("📱 macOS Game Center presentation would be handled differently")
        #endif
    }
    
    // MARK: - Utility Methods
    
    /// Checks if a specific achievement has been completed
    /// - Parameter identifier: The achievement identifier
    /// - Returns: Whether the achievement is completed
    func isAchievementCompleted(_ identifier: String) async -> Bool {
        guard isAuthenticated else { return false }
        
        do {
            let achievements = try await GKAchievement.loadAchievements()
            return achievements.first { $0.identifier == identifier }?.isCompleted == true
        } catch {
            print("❌ Failed to load achievements: \(error)")
            return false
        }
    }
    
    /// Gets current progress for an achievement
    /// - Parameter identifier: The achievement identifier
    /// - Returns: Progress percentage (0.0 to 100.0)
    func getAchievementProgress(_ identifier: String) async -> Double {
        guard isAuthenticated else { return 0.0 }
        
        do {
            let achievements = try await GKAchievement.loadAchievements()
            return achievements.first { $0.identifier == identifier }?.percentComplete ?? 0.0
        } catch {
            print("❌ Failed to load achievements: \(error)")
            return 0.0
        }
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
        print("🎮 Game Center view controller dismissed")
    }
}