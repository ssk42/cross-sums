import Foundation

/// Represents complete performance data for a daily puzzle completion
public struct DailyPuzzleCompletion: Codable {
    public let timeInSeconds: TimeInterval
    public let movesUsed: Int
    public let livesLeft: Int
    public let completedAt: Date
    
    public init(timeInSeconds: TimeInterval, movesUsed: Int, livesLeft: Int, completedAt: Date = Date()) {
        self.timeInSeconds = timeInSeconds
        self.movesUsed = movesUsed
        self.livesLeft = livesLeft
        self.completedAt = completedAt
    }
}

/// Service responsible for managing daily puzzles
/// 
/// Provides date-based puzzle generation with consistent seeding to ensure
/// all players get the same daily puzzle. Tracks daily completion status
/// and manages the daily puzzle state.
@MainActor
public class DailyPuzzleService: ObservableObject {
    
    // MARK: - Constants
    
    private static let dailyPuzzleDifficulty = "Medium"
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    // MARK: - Properties
    
    private let puzzleService: PuzzleServiceProtocol
    private let persistenceService: PersistenceService
    private var cachedDailyPuzzle: (date: String, puzzle: Puzzle)?
    
    // MARK: - Published Properties
    
    @Published public var currentDailyPuzzle: Puzzle?
    @Published public var isCompleted: Bool = false
    @Published public var completionTime: TimeInterval?
    @Published public var streak: Int = 0
    
    // MARK: - Singleton
    
    public static let shared = DailyPuzzleService()
    
    private init(puzzleService: PuzzleServiceProtocol = PuzzleService.shared,
                persistenceService: PersistenceService = PersistenceService.shared) {
        self.puzzleService = puzzleService
        self.persistenceService = persistenceService
        loadDailyPuzzleState()
    }
    
    // MARK: - Public Methods
    
    /// Gets today's daily puzzle
    /// - Returns: Today's daily puzzle
    public func getTodaysPuzzle() -> Puzzle {
        let todayString = getTodayDateString()
        
        // Check if we have cached today's puzzle
        if let cached = cachedDailyPuzzle,
           cached.date == todayString {
            return cached.puzzle
        }
        
        // Generate today's puzzle with date-based seed
        let puzzle = generateDailyPuzzle(for: todayString)
        cachedDailyPuzzle = (date: todayString, puzzle: puzzle)
        currentDailyPuzzle = puzzle
        
        return puzzle
    }
    
    /// Completes today's daily puzzle
    /// - Parameters:
    ///   - timeInSeconds: Time taken to complete the puzzle
    ///   - movesUsed: Number of moves made during completion
    ///   - livesLeft: Number of lives remaining after completion
    public func completeTodaysPuzzle(timeInSeconds: TimeInterval, movesUsed: Int, livesLeft: Int) {
        let todayString = getTodayDateString()
        let completion = DailyPuzzleCompletion(
            timeInSeconds: timeInSeconds,
            movesUsed: movesUsed,
            livesLeft: livesLeft
        )
        
        // Update completion state
        isCompleted = true
        completionTime = timeInSeconds
        
        // Update streak
        updateStreak()
        
        // Save completion state
        saveDailyCompletion(date: todayString, completion: completion)
        
        print("✅ Daily puzzle completed - Time: \(timeInSeconds)s, Moves: \(movesUsed), Lives: \(livesLeft)")
    }
    
    /// Checks if today's puzzle has been completed
    /// - Returns: Whether today's puzzle is completed
    public func isTodayCompleted() -> Bool {
        let todayString = getTodayDateString()
        return getDailyCompletion(for: todayString) != nil
    }
    
    /// Gets the completion time for today's puzzle if completed
    /// - Returns: Completion time in seconds, or nil if not completed
    public func getTodayCompletionTime() -> TimeInterval? {
        let todayString = getTodayDateString()
        return getDailyCompletion(for: todayString)?.timeInSeconds
    }
    
    /// Gets the complete completion data for today's puzzle if completed
    /// - Returns: Complete daily puzzle completion data, or nil if not completed
    public func getTodayCompletionData() -> DailyPuzzleCompletion? {
        let todayString = getTodayDateString()
        return getDailyCompletion(for: todayString)
    }
    
    /// Gets the current daily streak
    /// - Returns: Number of consecutive days completed
    public func getCurrentStreak() -> Int {
        return calculateCurrentStreak()
    }
    
    /// Gets the best daily streak
    /// - Returns: Longest consecutive days completed
    public func getBestStreak() -> Int {
        return getBestStreakFromStorage()
    }
    
    /// Refreshes the daily puzzle state (call when app becomes active)
    public func refreshDailyState() {
        loadDailyPuzzleState()
        _ = getTodaysPuzzle() // Ensure today's puzzle is loaded
    }
    
    // MARK: - Private Methods
    
    private func getTodayDateString() -> String {
        return Self.dateFormatter.string(from: Date())
    }
    
    private func generateDailyPuzzle(for dateString: String) -> Puzzle {
        // Create a deterministic seed based on the date
        let seed = dateString.hash
        
        // Use a custom puzzle generator with the date seed
        // For now, we'll use the existing puzzle service with a deterministic level
        let dayOfYear = calculateDayOfYear(from: dateString)
        let level = (dayOfYear % 100) + 1 // Cycle through levels 1-100
        
        print("🗓️ Generating daily puzzle for \(dateString), seed: \(seed), level: \(level)")
        
        let puzzle = puzzleService.getPuzzle(difficulty: Self.dailyPuzzleDifficulty, level: level)
        
        // Create a new puzzle with daily-specific ID
        let dailyPuzzle = Puzzle(
            id: "daily-\(dateString)",
            difficulty: "Daily",
            grid: puzzle.grid,
            solution: puzzle.solution,
            rowSums: puzzle.rowSums,
            columnSums: puzzle.columnSums
        )
        
        return dailyPuzzle
    }
    
    private func calculateDayOfYear(from dateString: String) -> Int {
        guard let date = Self.dateFormatter.date(from: dateString) else {
            return 1
        }
        
        let calendar = Calendar(identifier: .gregorian)
        return calendar.ordinality(of: .day, in: .year, for: date) ?? 1
    }
    
    private func loadDailyPuzzleState() {
        let todayString = getTodayDateString()
        
        // Check if today is completed
        if let completion = getDailyCompletion(for: todayString) {
            isCompleted = true
            completionTime = completion.timeInSeconds
        } else {
            isCompleted = false
            completionTime = nil
        }
        
        // Update streak
        streak = calculateCurrentStreak()
    }
    
    private func updateStreak() {
        streak = calculateCurrentStreak()
        
        // Update best streak if current streak is better
        let bestStreak = getBestStreakFromStorage()
        if streak > bestStreak {
            setBestStreakInStorage(streak)
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        var currentStreak = 0
        
        // Start from today and work backwards
        var checkDate = today
        
        while true {
            let dateString = Self.dateFormatter.string(from: checkDate)
            
            if getDailyCompletion(for: dateString) != nil {
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
    
    // MARK: - Storage Methods
    
    private func getDailyCompletion(for date: String) -> DailyPuzzleCompletion? {
        let newKey = "daily_completion_v2_\(date)"
        
        // First try to get new format data
        if let data = UserDefaults.standard.data(forKey: newKey),
           let completion = try? JSONDecoder().decode(DailyPuzzleCompletion.self, from: data) {
            return completion
        }
        
        // Fall back to legacy format for backward compatibility
        let legacyKey = "daily_completion_\(date)"
        let time = UserDefaults.standard.double(forKey: legacyKey)
        if time > 0 {
            // Convert legacy data to new format with estimated values
            return DailyPuzzleCompletion(
                timeInSeconds: time,
                movesUsed: 15, // Estimated value for legacy data
                livesLeft: 2,  // Estimated value for legacy data
                completedAt: Date()
            )
        }
        
        return nil
    }
    
    private func saveDailyCompletion(date: String, completion: DailyPuzzleCompletion) {
        let newKey = "daily_completion_v2_\(date)"
        
        if let data = try? JSONEncoder().encode(completion) {
            UserDefaults.standard.set(data, forKey: newKey)
        }
        
        // Also save in legacy format for backward compatibility
        let legacyKey = "daily_completion_\(date)"
        UserDefaults.standard.set(completion.timeInSeconds, forKey: legacyKey)
    }
    
    private func getBestStreakFromStorage() -> Int {
        return UserDefaults.standard.integer(forKey: "daily_best_streak")
    }
    
    private func setBestStreakInStorage(_ streak: Int) {
        UserDefaults.standard.set(streak, forKey: "daily_best_streak")
    }
}

// MARK: - Daily Puzzle State Model

/// Represents the state of daily puzzle progress
public struct DailyPuzzleState: Codable {
    public let date: String
    public let isCompleted: Bool
    public let completionTime: TimeInterval?
    public let streak: Int
    
    public init(date: String, isCompleted: Bool, completionTime: TimeInterval? = nil, streak: Int = 0) {
        self.date = date
        self.isCompleted = isCompleted
        self.completionTime = completionTime
        self.streak = streak
    }
}