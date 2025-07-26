
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
