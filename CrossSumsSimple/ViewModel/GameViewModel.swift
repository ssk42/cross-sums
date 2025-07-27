import Foundation
import SwiftUI
import GameKit

/// The main ViewModel for game logic and state management
/// 
/// GameViewModel handles all game interactions, integrates with services,
/// and manages the complete game flow from puzzle loading to completion.
/// Conforms to ObservableObject for SwiftUI data binding.
@MainActor
class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The currently active puzzle being played
    @Published var currentPuzzle: Puzzle?
    
    /// The current game state (lives, moves, cell states)
    @Published var gameState: GameState?
    
    /// The player's persistent profile data
    @Published var playerProfile: PlayerProfile
    
    /// Whether the current level has been completed successfully
    @Published var isLevelComplete: Bool = false
    
    /// Whether the game is over (no lives remaining)
    @Published var isGameOver: Bool = false
    
    /// Whether data is currently being loaded
    @Published var isLoading: Bool = false
    
    /// Error message to display to user, if any
    @Published var errorMessage: String?
    
    /// The current sums of the rows, based on the player's moves
    @Published var currentRowSums: [Int] = []
    
    /// The current sums of the columns, based on the player's moves
    @Published var currentColumnSums: [Int] = []
    
    /// Whether hint usage is currently available
    @Published var canUseHint: Bool = false
    
    // MARK: - Private Properties
    
    private let puzzleService: PuzzleServiceProtocol
    private let persistenceService: PersistenceService
    private let gameCenterManager: GameCenterManager
    private let achievementTracker: AchievementTracker
    
    // MARK: - Computed Properties
    
    /// Whether the game is currently active (not completed, not game over)
    var isGameActive: Bool {
        return gameState?.isActive ?? false
    }
    
    /// Current lives remaining (for UI display)
    var livesRemaining: Int {
        return gameState?.livesRemaining ?? 0
    }
    
    /// Total hints available (for UI display)
    var hintsAvailable: Int {
        return playerProfile.totalHints
    }
    
    /// Current level number being played
    var currentLevel: Int {
        guard let puzzle = currentPuzzle else { return 0 }
        return extractLevelNumber(from: puzzle.id) ?? 0
    }
    
    /// Current difficulty being played
    var currentDifficulty: String {
        return currentPuzzle?.difficulty ?? ""
    }
    
    // MARK: - Initialization
    
    /// Initializes the GameViewModel with service dependencies
    /// - Parameters:
    ///   - puzzleService: Service for loading puzzles (default: shared instance)
    ///   - persistenceService: Service for saving/loading data (default: shared instance)
    ///   - gameCenterManager: Game Center manager (default: shared instance)
    init(puzzleService: PuzzleServiceProtocol = PuzzleService.shared, 
         persistenceService: PersistenceService = .shared,
         gameCenterManager: GameCenterManager = .shared) {
        self.puzzleService = puzzleService
        self.persistenceService = persistenceService
        self.gameCenterManager = gameCenterManager
        self.achievementTracker = AchievementTracker(gameCenterManager: gameCenterManager)
        
        // Load player profile
        self.playerProfile = persistenceService.loadProfile()
        
        // Update hint availability
        updateHintAvailability()
        
        // Initialize Game Center
        Task {
            await initializeGameCenter()
        }
    }
    
    // MARK: - Public Game Methods
    
    /// Loads and starts a new puzzle with robust fallback strategies
    /// - Parameters:
    ///   - difficulty: The difficulty level (e.g., "Easy", "Medium", "Hard", "Extra Hard", "Expert")
    ///   - level: The level number within that difficulty
    func loadPuzzle(difficulty: String, level: Int) {
        isLoading = true
        errorMessage = nil
        
        // Get puzzle from service (now guaranteed to return a puzzle via fallback strategies)
        let puzzle = puzzleService.getPuzzle(difficulty: difficulty, level: level)
        
        // Validate puzzle integrity  
        guard puzzle.isValid else {
            errorMessage = "Invalid puzzle data for: \(difficulty) Level \(level)"
            isLoading = false
            print("❌ Generated puzzle failed validation: \(puzzle.id)")
            return
        }
        
        // Set up new game
        currentPuzzle = puzzle
        gameState = GameState(for: puzzle)
        isLevelComplete = false
        isGameOver = false
        updateHintAvailability()
        updateCurrentSums()
        
        isLoading = false
        
        print("✅ Loaded puzzle: \(puzzle.id) (\(puzzle.rowCount)x\(puzzle.columnCount))")
    }
    
    /// Sets a cell to a specific state directly (US4, US5, US6)
    /// - Parameters:
    ///   - row: Row index of the cell
    ///   - column: Column index of the cell
    ///   - targetState: The desired state (true=kept, false=removed, nil=unmarked)
    func setCellState(row: Int, column: Int, targetState: Bool?) {
        guard isGameActive,
              var state = gameState else {
            return
        }
        
        // Set the cell to the target state directly
        let success = state.setCellState(row: row, column: column, state: targetState)
        guard success else {
            print("❌ Invalid cell position: (\(row), \(column))")
            return
        }
        
        // Update game state
        gameState = state
        updateCurrentSums()
        
        // Check if this was a mistake (only for non-nil states)
        if let cellState = targetState {
            validateMove(row: row, column: column, expectedState: cellState)
        }
        
        // Check for win condition after each move
        checkForWinCondition()
        
        print("🔄 Cell (\(row), \(column)) set to: \(String(describing: targetState))")
    }
    
    /// Toggles a cell state when tapped by the player (US4, US5, US6)
    /// - Parameters:
    ///   - row: Row index of the cell
    ///   - column: Column index of the cell
    func toggleCell(row: Int, column: Int) {
        guard isGameActive,
              var state = gameState else {
            return
        }
        
        // Check if position is valid first
        guard state.isValidPosition(row: row, column: column) else {
            print("❌ Invalid cell position: (\(row), \(column))")
            return
        }
        
        // Toggle the cell state
        let newState = state.toggleCell(row: row, column: column)
        
        // Update game state
        gameState = state
        updateCurrentSums()
        
        // Check if this was a mistake (only for non-nil states)
        if let cellState = newState {
            validateMove(row: row, column: column, expectedState: cellState)
        }
        
        // Check for win condition after each move
        checkForWinCondition()
        
        print("🔄 Cell (\(row), \(column)) toggled to: \(String(describing: newState))")
    }
    
    /// Uses a hint to reveal a correct cell (US7)
    func useHint() {
        guard playerProfile.hasHintsAvailable,
              let puzzle = currentPuzzle,
              var state = gameState else {
            print("❌ Cannot use hint: no hints available or game not active")
            return
        }
        
        // Find an unmarked cell that should be in the correct state
        let unmarkedCells = state.getUnmarkedCells()
        guard !unmarkedCells.isEmpty else {
            print("ℹ️ No more cells to hint - puzzle is fully marked")
            return
        }
        
        // Pick a random unmarked cell
        let randomCell = unmarkedCells.randomElement()!
        let correctState = puzzle.solutionState(at: randomCell.row, column: randomCell.column)!
        
        // Set the cell to its correct state
        _ = state.setCellState(row: randomCell.row, column: randomCell.column, state: correctState)
        gameState = state
        updateCurrentSums()
        
        // Consume the hint
        _ = playerProfile.useHint()
        updateHintAvailability()
        saveProgress()
        
        // Check for win condition
        checkForWinCondition()
        
        print("💡 Hint used: Cell (\(randomCell.row), \(randomCell.column)) = \(correctState)")
    }
    
    /// Restarts the current level (US10)
    func restartLevel() {
        guard let puzzle = currentPuzzle else { return }
        
        // Reset game state
        gameState = GameState(for: puzzle)
        isLevelComplete = false
        isGameOver = false
        updateHintAvailability()
        updateCurrentSums()
        
        // Reset Game Center achievement tracking
        handleLevelReset()
        
        print("🔄 Level restarted: \(puzzle.id)")
    }
    
    /// Checks if the current puzzle solution is complete and correct (US8)
    func checkForWinCondition() {
        guard let puzzle = currentPuzzle,
              let state = gameState,
              !isLevelComplete && !isGameOver else {
            return
        }
        
        // Check if all cells are marked
        guard state.isGridFullyMarked else {
            return // Still cells to fill
        }
        
        // Check if solution is correct
        let solidMask = state.solidGridMask
        if puzzle.isValidSolution(solidMask) {
            // Level completed!
            handleLevelComplete()
        } else {
            print("❌ Solution is complete but incorrect")
            // Could optionally trigger game over or let player continue
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func updateCurrentSums() {
        guard let puzzle = currentPuzzle, let state = gameState else {
            currentRowSums = []
            currentColumnSums = []
            return
        }
        
        // Check if grid is valid
        guard !puzzle.grid.isEmpty && !puzzle.grid[0].isEmpty else {
            currentRowSums = []
            currentColumnSums = []
            return
        }
        
        currentRowSums = puzzle.grid.indices.map { row in
            puzzle.grid[row].indices.reduce(0) { sum, col in
                if let cellState = state.getCellState(row: row, column: col), cellState == true {
                    return sum + puzzle.grid[row][col]
                }
                return sum
            }
        }
        
        currentColumnSums = puzzle.grid[0].indices.map { col in
            puzzle.grid.indices.reduce(0) { sum, row in
                if let cellState = state.getCellState(row: row, column: col), cellState == true {
                    return sum + puzzle.grid[row][col]
                }
                return sum
            }
        }
    }
    
    /// Validates if a move was correct and handles mistakes
    /// - Parameters:
    ///   - row: Row of the move
    ///   - column: Column of the move
    ///   - expectedState: The state the player set
    private func validateMove(row: Int, column: Int, expectedState: Bool) {
        guard let puzzle = currentPuzzle,
              var state = gameState else { return }
        
        let correctState = puzzle.solutionState(at: row, column: column)!
        
        if expectedState != correctState {
            // Mistake made - lose a life
            if state.loseLife() {
                gameState = state
                print("💔 Mistake! Lives remaining: \(state.livesRemaining)")
                
                // Check for game over
                if state.isGameOver {
                    isGameOver = true
                    print("💀 Game Over!")
                }
            }
        }
    }
    
    /// Handles successful level completion
    internal func handleLevelComplete() {
        guard let puzzle = currentPuzzle,
              let state = gameState else { return }
        
        isLevelComplete = true
        
        let levelNumber = currentLevel
        let difficulty = puzzle.difficulty
        let completionTime = state.elapsedTime
        let movesUsed = state.moveCount
        let livesLost = 3 - state.livesRemaining // Assuming starting lives is 3
        
        // Update player progress
        let wasNewRecord = playerProfile.completeLevel(levelNumber, for: difficulty)
        
        // Award hints for completion
        playerProfile.awardHintsForCompletion(level: levelNumber, difficulty: difficulty)
        
        // Save progress
        saveProgress()
        updateHintAvailability()
        
        // Game Center integration
        Task {
            await handleGameCenterSubmissions(
                level: levelNumber,
                difficulty: difficulty,
                completionTime: completionTime,
                movesUsed: movesUsed,
                mistakesMade: livesLost,
                wasNewRecord: wasNewRecord
            )
        }
        
        print("🎉 Level \(levelNumber) (\(difficulty)) completed!")
        if wasNewRecord {
            print("🏆 New personal best!")
        }
    }
    
    /// Loads the next level in the current difficulty
    func loadNextLevel() {
        guard let currentPuzzle = currentPuzzle else { return }
        
        let difficulty = currentPuzzle.difficulty
        let nextLevel = currentLevel + 1
        
        // Check if next level exists
        let maxLevel = puzzleService.getMaxLevel(for: difficulty)
        if nextLevel <= maxLevel {
            loadPuzzle(difficulty: difficulty, level: nextLevel)
        } else {
            errorMessage = "No more levels available for \(difficulty) difficulty"
            print("🏁 No more levels in \(difficulty) difficulty!")
            // Could trigger difficulty completion celebration
        }
    }
    
    /// Saves current progress to persistence
    private func saveProgress() {
        persistenceService.saveProfile(playerProfile)
    }
    
    /// Updates whether hints can be used
    internal func updateHintAvailability() {
        canUseHint = playerProfile.hasHintsAvailable && isGameActive
    }
    
    /// Extracts level number from puzzle ID
    /// - Parameter puzzleId: The puzzle ID (format: "difficulty-level")
    /// - Returns: Level number or nil if not found
    private func extractLevelNumber(from puzzleId: String) -> Int? {
        let components = puzzleId.split(separator: "-")
        return components.last.flatMap { Int($0) }
    }
    
    // MARK: - Public Utility Methods
    
    /// Gets the highest completed level for a difficulty
    /// - Parameter difficulty: The difficulty to check
    /// - Returns: Highest completed level
    func getHighestLevel(for difficulty: String) -> Int {
        return playerProfile.getHighestLevel(for: difficulty)
    }
    
    /// Gets the next level to play for a difficulty
    /// - Parameter difficulty: The difficulty to check
    /// - Returns: Next level to play
    func getNextLevel(for difficulty: String) -> Int {
        return playerProfile.getNextLevel(for: difficulty)
    }
    
    /// Gets all available difficulties
    /// - Returns: Array of difficulty strings
    func getAvailableDifficulties() -> [String] {
        return puzzleService.getAvailableDifficulties()
    }
    
    /// Clears any error messages
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Debug Methods
    
    /// Prints debug information about current game state
    func debugPrintGameState() {
        print("🐛 GameViewModel Debug Info:")
        print("  - Current Puzzle: \(currentPuzzle?.id ?? "none")")
        print("  - Lives: \(livesRemaining)")
        print("  - Hints: \(hintsAvailable)")
        print("  - Level Complete: \(isLevelComplete)")
        print("  - Game Over: \(isGameOver)")
        print("  - Is Loading: \(isLoading)")
        
        if let state = gameState {
            print("  - Move Count: \(state.moveCount)")
            print("  - Completion: \(state.completionPercentage * 100)%")
        }
    }
    
    // MARK: - Game Center Methods
    
    /// Initializes Game Center authentication
    private func initializeGameCenter() async {
        gameCenterManager.authenticatePlayer()
        
        // Update achievement progress for existing player data
        achievementTracker.updateIncrementalAchievements(playerProfile: playerProfile)
    }
    
    /// Handles Game Center submissions when a level is completed
    private func handleGameCenterSubmissions(
        level: Int,
        difficulty: String,
        completionTime: TimeInterval,
        movesUsed: Int,
        mistakesMade: Int,
        wasNewRecord: Bool
    ) async {
        // Submit leaderboard scores
        if wasNewRecord {
            // Submit highest level reached
            await gameCenterManager.submitHighestLevel(level, difficulty: difficulty)
        }
        
        // Always submit completion time for potential best time
        await gameCenterManager.submitCompletionTime(completionTime, difficulty: difficulty)
        
        // Track achievements
        await achievementTracker.trackLevelCompletion(
            level: level,
            difficulty: difficulty,
            completionTime: completionTime,
            movesUsed: movesUsed,
            hintsUsed: 0, // Would need to track this during gameplay
            mistakesMade: mistakesMade,
            playerProfile: playerProfile
        )
    }
    
    /// Called when a level is restarted or failed
    func handleLevelReset() {
        achievementTracker.trackLevelReset()
    }
    
    /// Shows Game Center leaderboards
    func showLeaderboards() {
        gameCenterManager.showLeaderboards()
    }
    
    /// Shows Game Center achievements
    func showAchievements() {
        gameCenterManager.showAchievements()
    }
    
    /// Shows Game Center dashboard
    func showGameCenter() {
        gameCenterManager.showGameCenter()
    }
    
    /// Gets Game Center authentication status
    var isGameCenterAuthenticated: Bool {
        return gameCenterManager.isAuthenticated
    }
    
    /// Gets Game Center availability status
    var isGameCenterAvailable: Bool {
        return gameCenterManager.isAvailable
    }
}