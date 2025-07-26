import Foundation

/// Represents the player's active state within a single puzzle. This is ephemeral and not saved.
/// 
/// GameState tracks the current progress and status of a puzzle being played, including
/// the player's cell selections, remaining lives, and game status. This state is reset
/// when starting a new puzzle or restarting the current one.
public struct GameState {
    /// 2D boolean array representing the player's current cell selections
    /// true = cell is marked as kept, false = cell is marked as removed
    /// nil values can represent unmarked cells during initial state
    public var playerGridMask: [[Bool?]]
    
    /// Number of lives/mistakes remaining before game over
    public var livesRemaining: Int
    
    /// Whether the puzzle has been completed successfully
    public var isCompleted: Bool
    
    /// Whether the game is over (no lives remaining)
    public var isGameOver: Bool
    
    /// Total number of moves made by the player
    public var moveCount: Int
    
    /// Time when the game started (for tracking completion time)
    public var startTime: Date
    
    // MARK: - Initializers
    
    /// Creates a new game state for the given puzzle
    /// - Parameters:
    ///   - puzzle: The puzzle to create state for
    ///   - lives: Starting number of lives (default: 3)
    public init(for puzzle: Puzzle, lives: Int = 3) {
        // Initialize grid mask with nil values (unmarked)
        self.playerGridMask = Array(repeating: Array(repeating: nil, count: puzzle.columnCount), count: puzzle.rowCount)
        self.livesRemaining = lives
        self.isCompleted = false
        self.isGameOver = false
        self.moveCount = 0
        self.startTime = Date()
    }
    
    /// Creates a game state with specific values (for restoration or testing)
    /// - Parameters:
    ///   - playerGridMask: Current grid state
    ///   - livesRemaining: Remaining lives
    ///   - isCompleted: Whether puzzle is completed
    ///   - isGameOver: Whether game is over
    ///   - moveCount: Number of moves made
    ///   - startTime: When the game started
    public init(playerGridMask: [[Bool?]], livesRemaining: Int, isCompleted: Bool = false, isGameOver: Bool = false, moveCount: Int = 0, startTime: Date = Date()) {
        self.playerGridMask = playerGridMask
        self.livesRemaining = livesRemaining
        self.isCompleted = isCompleted
        self.isGameOver = isGameOver
        self.moveCount = moveCount
        self.startTime = startTime
    }
    
    // MARK: - Computed Properties
    
    /// Returns the number of rows in the grid
    public var rowCount: Int {
        return playerGridMask.count
    }
    
    /// Returns the number of columns in the grid
    public var columnCount: Int {
        return playerGridMask.first?.count ?? 0
    }
    
    /// Returns true if the game is still active (not completed and not game over)
    public var isActive: Bool {
        return !isCompleted && !isGameOver
    }
    
    /// Returns the elapsed time since game start
    public var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    /// Returns the percentage of cells that have been marked (not nil)
    public var completionPercentage: Double {
        let totalCells = rowCount * columnCount
        guard totalCells > 0 else { return 0.0 }
        
        let markedCells = playerGridMask.flatMap { $0 }.compactMap { $0 }.count
        return Double(markedCells) / Double(totalCells)
    }
    
    // MARK: - Cell State Management
    
    /// Gets the current state of a cell
    /// - Parameters:
    ///   - row: Row index
    ///   - column: Column index
    /// - Returns: The cell state (true=kept, false=removed, nil=unmarked), or nil if out of bounds
    public func getCellState(row: Int, column: Int) -> Bool?? {
        guard isValidPosition(row: row, column: column) else { return nil }
        return playerGridMask[row][column]
    }
    
    /// Sets the state of a cell
    /// - Parameters:
    ///   - row: Row index
    ///   - column: Column index
    ///   - state: New cell state (true=kept, false=removed, nil=unmarked)
    /// - Returns: true if the cell was successfully updated, false if out of bounds
    public mutating func setCellState(row: Int, column: Int, state: Bool?) -> Bool {
        guard isValidPosition(row: row, column: column) else { return false }
        
        let oldState = playerGridMask[row][column]
        playerGridMask[row][column] = state
        
        // Increment move count if this was a meaningful change
        if oldState != state {
            moveCount += 1
        }
        
        return true
    }
    
    /// Toggles a cell between kept and removed states
    /// - Parameters:
    ///   - row: Row index
    ///   - column: Column index
    /// - Returns: The new cell state, or nil if out of bounds
    public mutating func toggleCell(row: Int, column: Int) -> Bool? {
        guard isValidPosition(row: row, column: column) else { return nil }
        
        let currentState = playerGridMask[row][column]
        let newState: Bool?
        
        switch currentState {
        case nil:
            newState = true  // unmarked -> kept
        case .some(true):
            newState = false // kept -> removed
        case .some(false):
            newState = nil   // removed -> unmarked
        }
        
        _ = setCellState(row: row, column: column, state: newState)
        return newState
    }
    
    /// Clears a cell back to unmarked state
    /// - Parameters:
    ///   - row: Row index
    ///   - column: Column index
    /// - Returns: true if successful, false if out of bounds
    public mutating func clearCell(row: Int, column: Int) -> Bool {
        return setCellState(row: row, column: column, state: nil)
    }
    
    // MARK: - Game Logic
    
    /// Checks if a position is valid within the grid bounds
    /// - Parameters:
    ///   - row: Row index
    ///   - column: Column index
    /// - Returns: true if the position is valid
    public func isValidPosition(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rowCount && column >= 0 && column < columnCount
    }
    
    /// Returns the current grid mask with nil values converted to false (for validation)
    /// This is useful for checking against puzzle solutions
    public var solidGridMask: [[Bool]] {
        return playerGridMask.map { row in
            row.map { cellState in
                cellState ?? false
            }
        }
    }
    
    /// Checks if all cells have been marked (no nil values)
    public var isGridFullyMarked: Bool {
        return playerGridMask.allSatisfy { row in
            row.allSatisfy { cellState in
                cellState != nil
            }
        }
    }
    
    /// Gets all unmarked cell positions
    /// - Returns: Array of (row, column) tuples for unmarked cells
    public func getUnmarkedCells() -> [(row: Int, column: Int)] {
        var unmarkedCells: [(row: Int, column: Int)] = []
        
        for (rowIndex, row) in playerGridMask.enumerated() {
            for (colIndex, cellState) in row.enumerated() {
                if cellState == nil {
                    unmarkedCells.append((row: rowIndex, column: colIndex))
                }
            }
        }
        
        return unmarkedCells
    }
    
    // MARK: - Life Management
    
    /// Decreases lives by one
    /// - Returns: true if lives were decreased, false if already at 0
    public mutating func loseLife() -> Bool {
        guard livesRemaining > 0 else { return false }
        
        livesRemaining -= 1
        
        if livesRemaining <= 0 {
            isGameOver = true
        }
        
        return true
    }
    
    /// Adds lives (for power-ups or bonuses)
    /// - Parameter count: Number of lives to add
    public mutating func addLives(_ count: Int) {
        livesRemaining += max(0, count)
        
        // If lives were added and game was over, reactivate game
        if livesRemaining > 0 && isGameOver {
            isGameOver = false
        }
    }
    
    // MARK: - Game State Control
    
    /// Marks the game as completed
    public mutating func markCompleted() {
        isCompleted = true
    }
    
    /// Marks the game as over
    public mutating func markGameOver() {
        isGameOver = true
    }
    
    /// Resets the game state for a restart (keeps the same puzzle)
    /// - Parameter lives: Number of lives to start with (default: 3)
    public mutating func restart(lives: Int = 3) {
        // Clear all cell states
        for rowIndex in 0..<rowCount {
            for colIndex in 0..<columnCount {
                playerGridMask[rowIndex][colIndex] = nil
            }
        }
        
        livesRemaining = lives
        isCompleted = false
        isGameOver = false
        moveCount = 0
        startTime = Date()
    }
}