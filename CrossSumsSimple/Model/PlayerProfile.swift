import Foundation

/// US9: Holds the player's persistent data.
/// 
/// This struct manages all persistent player information including progress,
/// available hints, and game preferences. Data is automatically saved and
/// restored between game sessions.
public struct PlayerProfile: Codable {
    public var highestLevelCompleted: [String: Int]
    
    public var totalHints: Int
    
    public var soundEnabled: Bool
    
    // MARK: - Initializers
    
    public init(hints: Int = 5, soundEnabled: Bool = true) {
        self.highestLevelCompleted = [:]
        self.totalHints = hints
        self.soundEnabled = soundEnabled
    }
    
    public init(highestLevelCompleted: [String: Int], totalHints: Int, soundEnabled: Bool) {
        self.highestLevelCompleted = highestLevelCompleted
        self.totalHints = totalHints
        self.soundEnabled = soundEnabled
    }
    
    // MARK: - Computed Properties
    
    public var totalLevelsCompleted: Int {
        return highestLevelCompleted.values.reduce(0, +)
    }
    
    public var playedDifficulties: Set<String> {
        return Set(highestLevelCompleted.keys)
    }
    
    public var hasPlayedBefore: Bool {
        return !highestLevelCompleted.isEmpty
    }
    
    public var hasHintsAvailable: Bool {
        return totalHints > 0
    }
    
    // MARK: - Level Management Methods
    
    public func getHighestLevel(for difficulty: String) -> Int {
        return highestLevelCompleted[difficulty] ?? 0
    }
    
    public func getNextLevel(for difficulty: String) -> Int {
        return getHighestLevel(for: difficulty) + 1
    }
    
    public mutating func updateHighestLevel(_ level: Int, for difficulty: String) -> Bool {
        let currentHighest = getHighestLevel(for: difficulty)
        
        if level > currentHighest {
            highestLevelCompleted[difficulty] = level
            return true
        }
        
        return false
    }
    
    public mutating func completeLevel(_ level: Int, for difficulty: String) -> Bool {
        return updateHighestLevel(level, for: difficulty)
    }
    
    // MARK: - Hint Management Methods
    
    public mutating func useHint() -> Bool {
        guard totalHints > 0 else { return false }
        
        totalHints -= 1
        return true
    }
    
    public mutating func addHints(_ count: Int) {
        totalHints += max(0, count) // Ensure we don't add negative hints
    }
    
    public mutating func awardHintsForCompletion(level: Int, difficulty: String) {
        // Award bonus hints based on difficulty and milestones
        let baseHints: Int
        switch difficulty.lowercased() {
        case "easy":
            baseHints = level % 10 == 0 ? 1 : 0 // 1 hint every 10 levels
        case "medium":
            baseHints = level % 8 == 0 ? 2 : 0  // 2 hints every 8 levels
        case "hard":
            baseHints = level % 5 == 0 ? 3 : 0  // 3 hints every 5 levels
        case "extra hard":
            baseHints = level % 3 == 0 ? 5 : 0  // 5 hints every 3 levels
        default:
            baseHints = 0
        }
        
        if baseHints > 0 {
            addHints(baseHints)
        }
    }
    
    // MARK: - Settings Methods
    
    public mutating func toggleSound() {
        soundEnabled.toggle()
    }
    
    public mutating func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
    }
    
    // MARK: - Reset Methods
    
    public mutating func resetProgress(for difficulty: String) {
        highestLevelCompleted.removeValue(forKey: difficulty)
    }
    
    public mutating func resetAllProgress() {
        highestLevelCompleted.removeAll()
    }
    
    public mutating func resetToDefaults() {
        highestLevelCompleted.removeAll()
        totalHints = 5
        soundEnabled = true
    }
}