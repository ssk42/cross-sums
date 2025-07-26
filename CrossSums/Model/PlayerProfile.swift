import Foundation

/// US9: Holds the player's persistent data.
/// 
/// This struct manages all persistent player information including progress,
/// available hints, and game preferences. Data is automatically saved and
/// restored between game sessions.
struct PlayerProfile: Codable {
    /// Dictionary mapping difficulty levels to highest completed level numbers
    /// Key: difficulty (e.g., "Easy", "Medium", "Hard", "Extra Hard")
    /// Value: highest level completed for that difficulty
    var highestLevelCompleted: [String: Int]
    
    /// Total number of hints available to the player
    var totalHints: Int
    
    /// Whether sound effects are enabled
    var soundEnabled: Bool
    
    // MARK: - Initializers
    
    /// Creates a new player profile with default values
    /// - Parameters:
    ///   - hints: Starting number of hints (default: 5)
    ///   - soundEnabled: Whether sound is enabled (default: true)
    init(hints: Int = 5, soundEnabled: Bool = true) {
        self.highestLevelCompleted = [:]
        self.totalHints = hints
        self.soundEnabled = soundEnabled
    }
    
    /// Creates a player profile with existing progress
    /// - Parameters:
    ///   - highestLevelCompleted: Dictionary of completed levels by difficulty
    ///   - totalHints: Number of available hints
    ///   - soundEnabled: Whether sound is enabled
    init(highestLevelCompleted: [String: Int], totalHints: Int, soundEnabled: Bool) {
        self.highestLevelCompleted = highestLevelCompleted
        self.totalHints = totalHints
        self.soundEnabled = soundEnabled
    }
    
    // MARK: - Computed Properties
    
    /// Returns the total number of levels completed across all difficulties
    var totalLevelsCompleted: Int {
        return highestLevelCompleted.values.reduce(0, +)
    }
    
    /// Returns all difficulty levels that have been played
    var playedDifficulties: Set<String> {
        return Set(highestLevelCompleted.keys)
    }
    
    /// Returns true if the player has any completed levels
    var hasPlayedBefore: Bool {
        return !highestLevelCompleted.isEmpty
    }
    
    /// Returns true if the player has hints available
    var hasHintsAvailable: Bool {
        return totalHints > 0
    }
    
    // MARK: - Level Management Methods
    
    /// Gets the highest completed level for a specific difficulty
    /// - Parameter difficulty: The difficulty level to check
    /// - Returns: The highest completed level, or 0 if no levels completed
    func getHighestLevel(for difficulty: String) -> Int {
        return highestLevelCompleted[difficulty] ?? 0
    }
    
    /// Gets the next level to play for a specific difficulty
    /// - Parameter difficulty: The difficulty level to check
    /// - Returns: The next level number to play (highest + 1)
    func getNextLevel(for difficulty: String) -> Int {
        return getHighestLevel(for: difficulty) + 1
    }
    
    /// Updates the highest completed level for a difficulty if the new level is higher
    /// - Parameters:
    ///   - level: The level that was completed
    ///   - difficulty: The difficulty of the completed level
    /// - Returns: true if the record was updated, false if the level was already completed or lower
    mutating func updateHighestLevel(_ level: Int, for difficulty: String) -> Bool {
        let currentHighest = getHighestLevel(for: difficulty)
        
        if level > currentHighest {
            highestLevelCompleted[difficulty] = level
            return true
        }
        
        return false
    }
    
    /// Marks a level as completed and updates progress
    /// - Parameters:
    ///   - level: The level that was completed
    ///   - difficulty: The difficulty of the completed level
    /// - Returns: true if this was a new record, false if already completed
    mutating func completeLevel(_ level: Int, for difficulty: String) -> Bool {
        return updateHighestLevel(level, for: difficulty)
    }
    
    // MARK: - Hint Management Methods
    
    /// Uses a hint if available
    /// - Returns: true if a hint was used, false if no hints available
    mutating func useHint() -> Bool {
        guard totalHints > 0 else { return false }
        
        totalHints -= 1
        return true
    }
    
    /// Adds hints to the player's total
    /// - Parameter count: Number of hints to add
    mutating func addHints(_ count: Int) {
        totalHints += max(0, count) // Ensure we don't add negative hints
    }
    
    /// Awards hints for completing a level (bonus system)
    /// - Parameters:
    ///   - level: The completed level
    ///   - difficulty: The difficulty of the completed level
    mutating func awardHintsForCompletion(level: Int, difficulty: String) {
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
    
    /// Toggles sound on/off
    mutating func toggleSound() {
        soundEnabled.toggle()
    }
    
    /// Sets sound preference
    /// - Parameter enabled: Whether sound should be enabled
    mutating func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
    }
    
    // MARK: - Reset Methods
    
    /// Resets all progress for a specific difficulty
    /// - Parameter difficulty: The difficulty to reset
    mutating func resetProgress(for difficulty: String) {
        highestLevelCompleted.removeValue(forKey: difficulty)
    }
    
    /// Resets all game progress but keeps settings
    mutating func resetAllProgress() {
        highestLevelCompleted.removeAll()
    }
    
    /// Completely resets the profile to default values
    mutating func resetToDefaults() {
        highestLevelCompleted.removeAll()
        totalHints = 5
        soundEnabled = true
    }
}