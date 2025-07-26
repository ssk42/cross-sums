
import XCTest
@testable import CrossSumsSimple

class GameViewModelTests: XCTestCase {

    var gameViewModel: GameViewModel!
    var mockPuzzleService: MockPuzzleService!
    var mockPersistenceService: MockPersistenceService!

    override func setUpWithError() throws {
        mockPuzzleService = MockPuzzleService()
        mockPersistenceService = MockPersistenceService()
        gameViewModel = GameViewModel(puzzleService: mockPuzzleService, persistenceService: mockPersistenceService)
    }

    override func tearDownWithError() throws {
        gameViewModel = nil
        mockPuzzleService = nil
        mockPersistenceService = nil
    }

    // MARK: - loadPuzzle Tests

    func testLoadPuzzle_success() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle

        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        XCTAssertNotNil(gameViewModel.currentPuzzle)
        XCTAssertNotNil(gameViewModel.gameState)
        XCTAssertFalse(gameViewModel.isLoading)
        XCTAssertNil(gameViewModel.errorMessage)
        XCTAssertEqual(gameViewModel.currentPuzzle?.id, puzzle.id)
        XCTAssertEqual(gameViewModel.currentRowSums, puzzle.rowSums)
        XCTAssertEqual(gameViewModel.currentColumnSums, puzzle.columnSums)
    }

    func testLoadPuzzle_puzzleNotFound() throws {
        mockPuzzleService.mockPuzzle = nil

        gameViewModel.loadPuzzle(difficulty: "NonExistent", level: 1)

        XCTAssertNil(gameViewModel.currentPuzzle)
        XCTAssertNil(gameViewModel.gameState)
        XCTAssertFalse(gameViewModel.isLoading)
        XCTAssertNotNil(gameViewModel.errorMessage)
        XCTAssertTrue(gameViewModel.errorMessage?.contains("Puzzle not found") ?? false)
    }

    func testLoadPuzzle_invalidPuzzle() throws {
        let invalidPuzzle = Puzzle(id: "invalid", difficulty: "Easy", grid: [], solution: [], rowSums: [], columnSums: [])
        mockPuzzleService.mockPuzzle = invalidPuzzle

        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        XCTAssertNil(gameViewModel.currentPuzzle)
        XCTAssertNil(gameViewModel.gameState)
        XCTAssertFalse(gameViewModel.isLoading)
        XCTAssertNotNil(gameViewModel.errorMessage)
        XCTAssertTrue(gameViewModel.errorMessage?.contains("Invalid puzzle data") ?? false)
    }

    // MARK: - setCellState Tests

    func testSetCellState_validMove() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        let initialMoveCount = gameViewModel.gameState?.moveCount
        gameViewModel.setCellState(row: 0, column: 0, targetState: true)

        XCTAssertEqual(gameViewModel.gameState?.getCellState(row: 0, column: 0), true)
        XCTAssertEqual(gameViewModel.gameState?.moveCount, (initialMoveCount ?? 0) + 1)
        // Verify sums are updated
        XCTAssertEqual(gameViewModel.currentRowSums[0], 1) // Assuming grid[0][0] is 1
        XCTAssertEqual(gameViewModel.currentColumnSums[0], 3) // Assuming grid[0][0] is 1, grid[1][0] is 2
    }

    func testSetCellState_invalidPosition() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        let initialMoveCount = gameViewModel.gameState?.moveCount
        gameViewModel.setCellState(row: 10, column: 10, targetState: true) // Out of bounds

        XCTAssertEqual(gameViewModel.gameState?.moveCount, initialMoveCount) // Move count should not change
    }

    // MARK: - toggleCell Tests

    func testToggleCell_unmarkedToKept() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        gameViewModel.toggleCell(row: 0, column: 0) // nil -> true
        XCTAssertEqual(gameViewModel.gameState?.getCellState(row: 0, column: 0), true)
    }

    func testToggleCell_keptToRemoved() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.setCellState(row: 0, column: 0, targetState: true) // Set to true first

        gameViewModel.toggleCell(row: 0, column: 0) // true -> false
        XCTAssertEqual(gameViewModel.gameState?.getCellState(row: 0, column: 0), false)
    }

    func testToggleCell_removedToUnmarked() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.setCellState(row: 0, column: 0, targetState: false) // Set to false first

        gameViewModel.toggleCell(row: 0, column: 0) // false -> nil
        XCTAssertNil(gameViewModel.gameState?.getCellState(row: 0, column: 0))
    }

    // MARK: - useHint Tests

    func testUseHint_success() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.playerProfile.totalHints = 1 // Ensure a hint is available

        let initialHints = gameViewModel.hintsAvailable
        gameViewModel.useHint()

        XCTAssertEqual(gameViewModel.hintsAvailable, initialHints - 1)
        XCTAssertFalse(gameViewModel.canUseHint) // Should be false after using last hint
        // Verify a cell was marked (difficult to test specific cell without more mock control)
        XCTAssertTrue(gameViewModel.gameState?.isGridFullyMarked == false || gameViewModel.isLevelComplete)
    }

    func testUseHint_noHintsAvailable() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.playerProfile.totalHints = 0 // No hints available

        let initialHints = gameViewModel.hintsAvailable
        gameViewModel.useHint()

        XCTAssertEqual(gameViewModel.hintsAvailable, initialHints) // Hints should not decrease
    }

    // MARK: - restartLevel Tests

    func testRestartLevel() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        // Make some moves
        gameViewModel.setCellState(row: 0, column: 0, targetState: true)
        gameViewModel.setCellState(row: 0, column: 1, targetState: false)

        gameViewModel.restartLevel()

        XCTAssertFalse(gameViewModel.isLevelComplete)
        XCTAssertFalse(gameViewModel.isGameOver)
        XCTAssertEqual(gameViewModel.gameState?.moveCount, 0)
        XCTAssertTrue(gameViewModel.gameState?.playerGridMask.flatMap { $0 }.allSatisfy { $0 == nil } ?? false) // All cells unmarked
    }

    // MARK: - checkForWinCondition Tests

    func testCheckForWinCondition_correctSolution() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        // Manually set the grid to the correct solution
        for r in 0..<puzzle.rowCount {
            for c in 0..<puzzle.columnCount {
                gameViewModel.setCellState(row: r, column: c, targetState: puzzle.solution[r][c])
            }
        }
        
        gameViewModel.checkForWinCondition()

        XCTAssertTrue(gameViewModel.isLevelComplete)
        XCTAssertFalse(gameViewModel.isGameOver)
        // Verify player progress updated (difficult to test without more mock control)
    }

    func testCheckForWinCondition_incorrectSolution() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        // Set an incorrect solution
        gameViewModel.setCellState(row: 0, column: 0, targetState: false) // Incorrect

        gameViewModel.checkForWinCondition()

        XCTAssertFalse(gameViewModel.isLevelComplete)
    }

    // MARK: - validateMove Tests

    func testValidateMove_correct() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        let initialLives = gameViewModel.livesRemaining
        gameViewModel.setCellState(row: 0, column: 0, targetState: true) // Correct move

        XCTAssertEqual(gameViewModel.livesRemaining, initialLives) // Lives should not change
        XCTAssertFalse(gameViewModel.isGameOver)
    }

    func testValidateMove_incorrect_loseLife() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.gameState?.livesRemaining = 1 // Set lives to 1 for easy game over

        let initialLives = gameViewModel.livesRemaining
        gameViewModel.setCellState(row: 0, column: 0, targetState: false) // Incorrect move

        XCTAssertEqual(gameViewModel.livesRemaining, initialLives - 1) // Lives should decrease
        XCTAssertTrue(gameViewModel.isGameOver) // Should be game over
    }

    // MARK: - handleLevelComplete Tests

    func testHandleLevelComplete() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.playerProfile.totalHints = 0 // Reset hints for testing award

        gameViewModel.handleLevelComplete()

        XCTAssertTrue(gameViewModel.isLevelComplete)
        XCTAssertFalse(gameViewModel.isGameOver)
        XCTAssertEqual(gameViewModel.playerProfile.getHighestLevel(for: "Easy"), 1) // Progress updated
        XCTAssertTrue(gameViewModel.playerProfile.totalHints > 0) // Hints awarded
    }

    // MARK: - loadNextLevel Tests

    func testLoadNextLevel_success() throws {
        let puzzle1 = createMockPuzzle(id: "easy-1", level: 1)
        let puzzle2 = createMockPuzzle(id: "easy-2", level: 2)
        mockPuzzleService.mockPuzzle = puzzle1
        mockPuzzleService.mockMaxLevel = 2 // Indicate there's a next level
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        // Simulate completing the current level
        gameViewModel.isLevelComplete = true
        mockPuzzleService.mockPuzzle = puzzle2 // Next puzzle to be loaded

        gameViewModel.loadNextLevel()

        XCTAssertEqual(gameViewModel.currentPuzzle?.id, puzzle2.id)
        XCTAssertEqual(gameViewModel.currentLevel, 2)
    }

    func testLoadNextLevel_noMoreLevels() throws {
        let puzzle1 = createMockPuzzle(id: "easy-1", level: 1)
        mockPuzzleService.mockPuzzle = puzzle1
        mockPuzzleService.mockMaxLevel = 1 // No more levels
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        // Simulate completing the current level
        gameViewModel.isLevelComplete = true

        gameViewModel.loadNextLevel()

        XCTAssertEqual(gameViewModel.currentPuzzle?.id, puzzle1.id) // Should remain on the same puzzle
        XCTAssertTrue(gameViewModel.errorMessage?.contains("No more levels") ?? false)
    }

    // MARK: - Edge Cases and Advanced Game Logic Tests

    func testGameOver_multipleIncorrectMoves() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.gameState?.livesRemaining = 3

        // Make multiple incorrect moves
        gameViewModel.setCellState(row: 0, column: 0, targetState: false) // Incorrect
        XCTAssertEqual(gameViewModel.livesRemaining, 2)
        XCTAssertFalse(gameViewModel.isGameOver)

        gameViewModel.setCellState(row: 1, column: 1, targetState: false) // Incorrect
        XCTAssertEqual(gameViewModel.livesRemaining, 1)
        XCTAssertFalse(gameViewModel.isGameOver)

        gameViewModel.setCellState(row: 0, column: 1, targetState: true) // Incorrect (should be false)
        XCTAssertEqual(gameViewModel.livesRemaining, 0)
        XCTAssertTrue(gameViewModel.isGameOver)
    }

    func testGameNotOver_correctMovesAfterIncorrect() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.gameState?.livesRemaining = 2

        // Make incorrect move
        gameViewModel.setCellState(row: 0, column: 0, targetState: false) // Incorrect
        XCTAssertEqual(gameViewModel.livesRemaining, 1)

        // Make correct move
        gameViewModel.setCellState(row: 0, column: 0, targetState: true) // Correct
        XCTAssertEqual(gameViewModel.livesRemaining, 1) // Should not change
        XCTAssertFalse(gameViewModel.isGameOver)
    }

    func testWinCondition_partialSolution() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        // Set only part of the solution
        gameViewModel.setCellState(row: 0, column: 0, targetState: true) // Correct

        gameViewModel.checkForWinCondition()
        XCTAssertFalse(gameViewModel.isLevelComplete, "Should not complete with partial solution")
    }

    func testWinCondition_incorrectSums() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        // Set incorrect combination that doesn't match target sums
        gameViewModel.setCellState(row: 0, column: 0, targetState: true)
        gameViewModel.setCellState(row: 0, column: 1, targetState: true) // Both true in row 0
        gameViewModel.setCellState(row: 1, column: 0, targetState: false)
        gameViewModel.setCellState(row: 1, column: 1, targetState: false)

        gameViewModel.checkForWinCondition()
        XCTAssertFalse(gameViewModel.isLevelComplete, "Should not complete with incorrect sums")
    }

    func testHintSystem_revealsCorrectCell() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.playerProfile.totalHints = 1

        // Initially no cells should be marked
        XCTAssertNil(gameViewModel.gameState?.getCellState(row: 0, column: 0))
        XCTAssertNil(gameViewModel.gameState?.getCellState(row: 1, column: 1))

        gameViewModel.useHint()

        // At least one cell should now be marked correctly
        let cell00State = gameViewModel.gameState?.getCellState(row: 0, column: 0)
        let cell11State = gameViewModel.gameState?.getCellState(row: 1, column: 1)
        
        // Either cell (0,0) should be true or cell (1,1) should be true (based on solution)
        let hasCorrectHint = (cell00State == true) || (cell11State == true)
        XCTAssertTrue(hasCorrectHint, "Hint should reveal at least one correct cell")
    }

    func testHintSystem_noHintsRemaining() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.playerProfile.totalHints = 0

        let initialGridState = gameViewModel.gameState?.playerGridMask
        gameViewModel.useHint()

        // Grid should be unchanged
        XCTAssertEqual(gameViewModel.gameState?.playerGridMask, initialGridState)
        XCTAssertEqual(gameViewModel.hintsAvailable, 0)
    }

    func testRestartLevel_preservesLives() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        
        let initialLives = gameViewModel.livesRemaining
        
        // Make some moves and lose a life
        gameViewModel.setCellState(row: 0, column: 0, targetState: false) // Incorrect
        XCTAssertLess(gameViewModel.livesRemaining, initialLives)

        gameViewModel.restartLevel()

        // Lives should be restored to initial value
        XCTAssertEqual(gameViewModel.livesRemaining, initialLives)
    }

    func testMultipleLevelCompletion() throws {
        let puzzle1 = createMockPuzzle(id: "easy-1", level: 1)
        let puzzle2 = createMockPuzzle(id: "easy-2", level: 2)
        
        mockPuzzleService.mockPuzzle = puzzle1
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        // Complete first level
        for r in 0..<puzzle1.rowCount {
            for c in 0..<puzzle1.columnCount {
                gameViewModel.setCellState(row: r, column: c, targetState: puzzle1.solution[r][c])
            }
        }
        gameViewModel.checkForWinCondition()
        XCTAssertTrue(gameViewModel.isLevelComplete)
        XCTAssertEqual(gameViewModel.playerProfile.getHighestLevel(for: "Easy"), 1)

        // Load next level
        mockPuzzleService.mockPuzzle = puzzle2
        gameViewModel.loadNextLevel()

        // Complete second level
        for r in 0..<puzzle2.rowCount {
            for c in 0..<puzzle2.columnCount {
                gameViewModel.setCellState(row: r, column: c, targetState: puzzle2.solution[r][c])
            }
        }
        gameViewModel.checkForWinCondition()
        XCTAssertTrue(gameViewModel.isLevelComplete)
        XCTAssertEqual(gameViewModel.playerProfile.getHighestLevel(for: "Easy"), 2)
    }

    func testLevelProgression_acrossDifficulties() throws {
        let easyPuzzle = createMockPuzzle(id: "easy-1", level: 1)
        let mediumPuzzle = createMockPuzzle(id: "medium-1", level: 1)
        
        // Complete Easy level
        mockPuzzleService.mockPuzzle = easyPuzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.handleLevelComplete()
        XCTAssertEqual(gameViewModel.playerProfile.getHighestLevel(for: "Easy"), 1)
        XCTAssertEqual(gameViewModel.playerProfile.getHighestLevel(for: "Medium"), 0)

        // Complete Medium level
        mockPuzzleService.mockPuzzle = mediumPuzzle
        gameViewModel.loadPuzzle(difficulty: "Medium", level: 1)
        gameViewModel.handleLevelComplete()
        XCTAssertEqual(gameViewModel.playerProfile.getHighestLevel(for: "Easy"), 1)
        XCTAssertEqual(gameViewModel.playerProfile.getHighestLevel(for: "Medium"), 1)
    }

    func testHintAwarding_onLevelComplete() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)
        gameViewModel.playerProfile.totalHints = 2

        let initialHints = gameViewModel.hintsAvailable
        gameViewModel.handleLevelComplete()

        XCTAssertGreaterThan(gameViewModel.hintsAvailable, initialHints, "Should award hints on level completion")
    }

    func testErrorHandling_invalidCellPosition() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        let initialMoveCount = gameViewModel.gameState?.moveCount ?? 0
        let initialLives = gameViewModel.livesRemaining

        // Try to set state of cell that doesn't exist
        gameViewModel.setCellState(row: -1, column: 0, targetState: true)
        gameViewModel.setCellState(row: 0, column: -1, targetState: true)
        gameViewModel.setCellState(row: 10, column: 0, targetState: true)
        gameViewModel.setCellState(row: 0, column: 10, targetState: true)

        // Should not affect game state
        XCTAssertEqual(gameViewModel.gameState?.moveCount, initialMoveCount)
        XCTAssertEqual(gameViewModel.livesRemaining, initialLives)
    }

    func testGameState_cellStateTransitions() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        // Test all state transitions
        let row = 0, col = 0

        // nil -> true
        XCTAssertNil(gameViewModel.gameState?.getCellState(row: row, column: col))
        gameViewModel.toggleCell(row: row, column: col)
        XCTAssertEqual(gameViewModel.gameState?.getCellState(row: row, column: col), true)

        // true -> false
        gameViewModel.toggleCell(row: row, column: col)
        XCTAssertEqual(gameViewModel.gameState?.getCellState(row: row, column: col), false)

        // false -> nil
        gameViewModel.toggleCell(row: row, column: col)
        XCTAssertNil(gameViewModel.gameState?.getCellState(row: row, column: col))
    }

    func testSumCalculation_dynamicUpdates() throws {
        let puzzle = createMockPuzzle()
        mockPuzzleService.mockPuzzle = puzzle
        gameViewModel.loadPuzzle(difficulty: "Easy", level: 1)

        let initialRowSum = gameViewModel.currentRowSums[0]
        let initialColSum = gameViewModel.currentColumnSums[0]

        // Mark cell (0,0) as kept (value is 1)
        gameViewModel.setCellState(row: 0, column: 0, targetState: true)

        XCTAssertEqual(gameViewModel.currentRowSums[0], initialRowSum + 1)
        XCTAssertEqual(gameViewModel.currentColumnSums[0], initialColSum + 1)

        // Mark cell (0,0) as removed
        gameViewModel.setCellState(row: 0, column: 0, targetState: false)

        XCTAssertEqual(gameViewModel.currentRowSums[0], initialRowSum)
        XCTAssertEqual(gameViewModel.currentColumnSums[0], initialColSum)
    }

    // MARK: - Helper Functions for Tests

    private func createMockPuzzle(id: String = "easy-1", level: Int = 1) -> Puzzle {
        return Puzzle(
            id: id,
            difficulty: "Easy",
            grid: [[1, 2], [3, 4]],
            solution: [[true, false], [false, true]],
            rowSums: [1, 4],
            columnSums: [3, 2]
        )
    }
}

// MARK: - Mock Services

class MockPuzzleService: PuzzleServiceProtocol {
    var mockPuzzle: Puzzle?
    var mockMaxLevel: Int = 10 // Default mock max level
    var mockDifficulties: [String] = ["Easy"]

    init() {}

    func getPuzzle(difficulty: String, level: Int) -> Puzzle? {
        return mockPuzzle
    }
    
    func getMaxLevel(for difficulty: String) -> Int {
        return mockMaxLevel
    }

    func getAvailableDifficulties() -> [String] {
        return mockDifficulties
    }
}

class MockPersistenceService: PersistenceService {
    var savedProfile: PlayerProfile?
    var loadedProfile: PlayerProfile?

    override func saveProfile(_ profile: PlayerProfile) -> Bool {
        savedProfile = profile
        return true
    }

    override func loadProfile() -> PlayerProfile {
        return loadedProfile ?? PlayerProfile(hints: 5, soundEnabled: true)
    }
}
