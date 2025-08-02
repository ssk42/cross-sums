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
    
    // MARK: - Daily Puzzle Properties
    
    public var dailyPuzzleCompletions: [String: TimeInterval]
    public var dailyBestStreak: Int
    public var totalDailyPuzzlesCompleted: Int
    
    // MARK: - Initializers
    
    public init(hints: Int = 5, soundEnabled: Bool = true) {
        self.highestLevelCompleted = [:]
        self.totalHints = hints
        self.soundEnabled = soundEnabled
        self.dailyPuzzleCompletions = [:]
        self.dailyBestStreak = 0
        self.totalDailyPuzzlesCompleted = 0
    }
    
    public init(highestLevelCompleted: [String: Int], totalHints: Int, soundEnabled: Bool, 
                dailyPuzzleCompletions: [String: TimeInterval] = [:], dailyBestStreak: Int = 0, 
                totalDailyPuzzlesCompleted: Int = 0) {
        self.highestLevelCompleted = highestLevelCompleted
        self.totalHints = totalHints
        self.soundEnabled = soundEnabled
        self.dailyPuzzleCompletions = dailyPuzzleCompletions
        self.dailyBestStreak = dailyBestStreak
        self.totalDailyPuzzlesCompleted = totalDailyPuzzlesCompleted
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
        dailyPuzzleCompletions.removeAll()
        dailyBestStreak = 0
        totalDailyPuzzlesCompleted = 0
    }
    
    // MARK: - Daily Puzzle Methods
    
    /// Records completion of a daily puzzle
    /// - Parameters:
    ///   - date: Date string in "yyyy-MM-dd" format
    ///   - timeInSeconds: Time taken to complete the puzzle
    public mutating func completeDailyPuzzle(date: String, timeInSeconds: TimeInterval) {
        // Only record if not already completed for this date
        if dailyPuzzleCompletions[date] == nil {
            dailyPuzzleCompletions[date] = timeInSeconds
            totalDailyPuzzlesCompleted += 1
            
            // Update best streak if applicable
            let currentStreak = calculateDailyStreak()
            if currentStreak > dailyBestStreak {
                dailyBestStreak = currentStreak
            }
        }
    }
    
    /// Records completion of a daily puzzle with full performance data
    /// - Parameters:
    ///   - date: Date string in "yyyy-MM-dd" format
    ///   - completion: Complete puzzle performance data
    public mutating func completeDailyPuzzle(date: String, completion: DailyPuzzleCompletion) {
        // Use the time-based method for backward compatibility
        // The detailed performance data is stored separately in DailyPuzzleService
        completeDailyPuzzle(date: date, timeInSeconds: completion.timeInSeconds)
    }
    
    /// Gets completion time for a specific date
    /// - Parameter date: Date string in "yyyy-MM-dd" format
    /// - Returns: Completion time in seconds, or nil if not completed
    public func getDailyCompletion(for date: String) -> TimeInterval? {
        return dailyPuzzleCompletions[date]
    }
    
    /// Checks if daily puzzle is completed for a specific date
    /// - Parameter date: Date string in "yyyy-MM-dd" format
    /// - Returns: Whether the daily puzzle was completed
    public func isDailyPuzzleCompleted(for date: String) -> Bool {
        return dailyPuzzleCompletions[date] != nil
    }
    
    /// Calculates current daily puzzle streak
    /// - Returns: Number of consecutive days completed
    public func calculateDailyStreak() -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let calendar = Calendar(identifier: .gregorian)
        var currentStreak = 0
        var checkDate = Date()
        
        // Check consecutive days working backwards from today
        while true {
            let dateString = dateFormatter.string(from: checkDate)
            
            if isDailyPuzzleCompleted(for: dateString) {
                currentStreak += 1
                
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                    break
                }
                checkDate = previousDay
            } else {
                // Streak broken
                break
            }
        }
        
        return currentStreak
    }
    
    /// Gets the best completion time across all daily puzzles
    /// - Returns: Best completion time in seconds, or nil if no puzzles completed
    public func getBestDailyTime() -> TimeInterval? {
        return dailyPuzzleCompletions.values.min()
    }
    
    /// Gets the average completion time for daily puzzles
    /// - Returns: Average completion time in seconds, or nil if no puzzles completed
    public func getAverageDailyTime() -> TimeInterval? {
        guard !dailyPuzzleCompletions.isEmpty else { return nil }
        let total = dailyPuzzleCompletions.values.reduce(0, +)
        return total / Double(dailyPuzzleCompletions.count)
    }
}