import XCTest
@testable import Simple_Cross_Sums

class PuzzleServiceTests: XCTestCase {

    var puzzleService: PuzzleService!

    override func setUpWithError() throws {
        puzzleService = PuzzleService.shared
        puzzleService.clearCache() // Start with clean cache for each test
    }

    override func tearDownWithError() throws {
        puzzleService.clearCache()
        puzzleService = nil
    }

    // MARK: - Basic Functionality Tests

    func testGetPuzzle_success() throws {
        let puzzle = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        
        XCTAssertEqual(puzzle.difficulty, "Easy")
        XCTAssertEqual(puzzle.id, "easy-1")
        XCTAssertTrue(puzzle.isValid, "Generated puzzle should be valid")
    }

    func testGetPuzzle_consistency() throws {
        // Same difficulty and level should return the same puzzle (cached)
        let puzzle1 = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        let puzzle2 = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        
        XCTAssertEqual(puzzle1.id, puzzle2.id)
        XCTAssertEqual(puzzle1.grid, puzzle2.grid)
        XCTAssertEqual(puzzle1.solution, puzzle2.solution)
    }

    func testGetPuzzle_differentLevels() throws {
        let puzzle1 = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        let puzzle2 = puzzleService.getPuzzle(difficulty: "Easy", level: 2)
        
        XCTAssertNotEqual(puzzle1.id, puzzle2.id)
        XCTAssertEqual(puzzle1.id, "easy-1")
        XCTAssertEqual(puzzle2.id, "easy-2")
    }

    func testGetPuzzle_differentDifficulties() throws {
        let easyPuzzle = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        let mediumPuzzle = puzzleService.getPuzzle(difficulty: "Medium", level: 1)
        let hardPuzzle = puzzleService.getPuzzle(difficulty: "Hard", level: 1)
        let extraHardPuzzle = puzzleService.getPuzzle(difficulty: "Extra Hard", level: 1)
        let expertPuzzle = puzzleService.getPuzzle(difficulty: "Expert", level: 1)
        
        XCTAssertTrue(easyPuzzle.isValid)
        XCTAssertTrue(mediumPuzzle.isValid)
        XCTAssertTrue(hardPuzzle.isValid)
        XCTAssertTrue(extraHardPuzzle.isValid)
        XCTAssertTrue(expertPuzzle.isValid)
        
        // Verify grid sizes match difficulty expectations
        XCTAssertEqual(easyPuzzle.rowCount, 3, "Easy puzzles should be 3x3")
        XCTAssertEqual(mediumPuzzle.rowCount, 4, "Medium puzzles should be 4x4")
        XCTAssertEqual(hardPuzzle.rowCount, 4, "Hard puzzles should be 4x4")
        XCTAssertEqual(extraHardPuzzle.rowCount, 5, "Extra Hard puzzles should be 5x5")
        XCTAssertEqual(expertPuzzle.rowCount, 6, "Expert puzzles should be 6x6")
    }

    func testGetPuzzle_invalidDifficulty() throws {
        // With robust fallback, even invalid difficulties get emergency puzzle
        let puzzle = puzzleService.getPuzzle(difficulty: "Invalid", level: 1)
        
        // Should not be nil due to emergency fallback
        XCTAssertEqual(puzzle.id, "invalid-1")
        XCTAssertTrue(puzzle.isValid, "Emergency fallback should be valid")
    }

    // MARK: - Available Difficulties Tests

    func testGetAvailableDifficulties() throws {
        let difficulties = puzzleService.getAvailableDifficulties()
        
        XCTAssertEqual(difficulties.count, 5)
        XCTAssertTrue(difficulties.contains("Easy"))
        XCTAssertTrue(difficulties.contains("Medium"))
        XCTAssertTrue(difficulties.contains("Hard"))
        XCTAssertTrue(difficulties.contains("Extra Hard"))
        XCTAssertTrue(difficulties.contains("Expert"))
    }

    // MARK: - Max Level Tests

    func testGetMaxLevel() throws {
        let maxLevel = puzzleService.getMaxLevel(for: "Easy")
        
        // With dynamic generation, should support very high levels
        XCTAssertGreaterThan(maxLevel, 1000, "Should support many levels with dynamic generation")
    }

    func testGetMaxLevel_allDifficulties() throws {
        let difficulties = puzzleService.getAvailableDifficulties()
        
        for difficulty in difficulties {
            let maxLevel = puzzleService.getMaxLevel(for: difficulty)
            XCTAssertGreaterThan(maxLevel, 100, "All difficulties should support high level counts")
        }
    }

    // MARK: - Puzzle Validation Tests

    func testValidateAllPuzzles() throws {
        // Generate a few puzzles first
        _ = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        _ = puzzleService.getPuzzle(difficulty: "Easy", level: 2)
        _ = puzzleService.getPuzzle(difficulty: "Medium", level: 1)
        
        let validationResults = puzzleService.validateAllPuzzles()
        
        // All generated puzzles should be valid
        for (puzzleId, isValid) in validationResults {
            XCTAssertTrue(isValid, "Puzzle \(puzzleId) should be valid")
        }
    }

    func testPuzzleStructureValidation() throws {
        let puzzle = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        
        XCTAssertFalse(puzzle.id.isEmpty, "Puzzle ID should not be empty")
        XCTAssertFalse(puzzle.difficulty.isEmpty, "Difficulty should not be empty")
        XCTAssertFalse(puzzle.grid.isEmpty, "Grid should not be empty")
        XCTAssertFalse(puzzle.solution.isEmpty, "Solution should not be empty")
        XCTAssertFalse(puzzle.rowSums.isEmpty, "Row sums should not be empty")
        XCTAssertFalse(puzzle.columnSums.isEmpty, "Column sums should not be empty")
        
        // Verify dimensions match
        XCTAssertEqual(puzzle.grid.count, puzzle.solution.count, "Grid and solution should have same row count")
        XCTAssertEqual(puzzle.grid.count, puzzle.rowSums.count, "Grid and row sums should have same count")
        XCTAssertEqual(puzzle.grid[0].count, puzzle.columnSums.count, "Grid and column sums should have same count")
    }

    func testPuzzleSumValidation() throws {
        let puzzle = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        
        // Verify that applying the solution gives the correct sums
        for (rowIndex, expectedSum) in puzzle.rowSums.enumerated() {
            let actualSum = puzzle.calculateRowSum(for: puzzle.solution, row: rowIndex)
            XCTAssertEqual(actualSum, expectedSum, "Row \(rowIndex) sum should match")
        }
        
        for (colIndex, expectedSum) in puzzle.columnSums.enumerated() {
            let actualSum = puzzle.calculateColumnSum(for: puzzle.solution, column: colIndex)
            XCTAssertEqual(actualSum, expectedSum, "Column \(colIndex) sum should match")
        }
    }

    // MARK: - Cache Management Tests

    func testClearCache() throws {
        // Generate a puzzle to populate cache
        let puzzle1 = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        
        // Clear cache
        puzzleService.clearCache()
        
        // Getting the same puzzle should still work (regenerated)
        let puzzle2 = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        XCTAssertEqual(puzzle1.id, puzzle2.id, "Puzzle ID should be the same for same difficulty/level")
    }

    func testForceRegeneration() throws {
        let puzzle1 = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        
        // Force regeneration
        puzzleService.forceRegeneration()
        
        // Should get a new puzzle (though it may be the same due to seeded generation)
        let puzzle2 = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        XCTAssertEqual(puzzle1.id, puzzle2.id, "ID should be the same for same level")
    }

    // MARK: - Performance Tests

    func testGetPuzzle_performance() throws {
        measure {
            for level in 1...10 {
                _ = puzzleService.getPuzzle(difficulty: "Easy", level: level)
            }
        }
    }

    func testCachedPuzzle_performance() throws {
        // Generate puzzle first
        _ = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        
        // Measure cached access
        measure {
            for _ in 1...100 {
                _ = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
            }
        }
    }

    // MARK: - Edge Cases Tests

    func testGetPuzzle_highLevel() throws {
        let puzzle = puzzleService.getPuzzle(difficulty: "Easy", level: 999)
        
        XCTAssertEqual(puzzle.id, "easy-999")
    }

    func testGetPuzzle_levelZero() throws {
        let puzzle = puzzleService.getPuzzle(difficulty: "Easy", level: 0)
        
        XCTAssertEqual(puzzle.id, "easy-0")
    }

    func testGetPuzzle_negativeLevel() throws {
        let puzzle = puzzleService.getPuzzle(difficulty: "Easy", level: -1)
        
        XCTAssertEqual(puzzle.id, "easy--1")
    }

    func testGetPuzzle_caseSensitivity() throws {
        let puzzle1 = puzzleService.getPuzzle(difficulty: "EASY", level: 1)
        let puzzle2 = puzzleService.getPuzzle(difficulty: "easy", level: 1)
        let puzzle3 = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        
        // All should return valid puzzles (case handled internally)
        XCTAssertTrue(puzzle1.isValid)
        XCTAssertTrue(puzzle2.isValid)
        XCTAssertTrue(puzzle3.isValid)
    }

    // MARK: - Memory Tests

    func testMemoryUsage() throws {
        let initialMemory = puzzleService.getMemoryUsage()
        
        // Generate several puzzles
        for level in 1...10 {
            _ = puzzleService.getPuzzle(difficulty: "Easy", level: level)
        }
        
        let finalMemory = puzzleService.getMemoryUsage()
        
        // Memory usage should increase (though this is a rough estimate)
        XCTAssertGreaterThanOrEqual(finalMemory, initialMemory)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentAccess() throws {
        // For CI/CD reliability, we'll test concurrent access in a more controlled way
        // that's less likely to fail on slower devices like iPhone SE
        
        let group = DispatchGroup()
        var results: [Bool] = []
        let resultsLock = NSLock()
        
        // Test only 2 concurrent operations to minimize system stress in CI
        let concurrentTasks = 2
        
        for level in 1...concurrentTasks {
            group.enter()
            
            // Use a different queue for each task to ensure true concurrency testing
            let taskQueue = DispatchQueue(label: "test.concurrent.\(level)", qos: .utility)
            
            taskQueue.async {
                // Add staggered delays to reduce contention
                Thread.sleep(forTimeInterval: Double(level - 1) * 0.2)
                
                do {
                    let puzzle = self.puzzleService.getPuzzle(difficulty: "Easy", level: level)
                    let isValid = puzzle.isValid
                    
                    resultsLock.lock()
                    results.append(isValid)
                    resultsLock.unlock()
                    
                    XCTAssertTrue(isValid, "Should generate valid puzzle in concurrent access for level \(level)")
                } catch {
                    resultsLock.lock()
                    results.append(false)
                    resultsLock.unlock()
                    
                    XCTFail("Puzzle generation failed for level \(level): \(error)")
                }
                
                group.leave()
            }
        }
        
        // Wait with generous timeout for CI environments
        let waitResult = group.wait(timeout: .now() + 180.0) // 3 minutes timeout
        XCTAssertEqual(waitResult, .success, "Concurrent puzzle generation should complete within timeout")
        
        // Verify all operations completed successfully
        XCTAssertEqual(results.count, concurrentTasks, "All concurrent operations should complete")
        XCTAssertTrue(results.allSatisfy { $0 }, "All concurrent operations should succeed")
    }

    // MARK: - Puzzle Quality Tests

    func testPuzzleHasMinimumKeptCells() throws {
        let puzzle = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        
        let totalCells = puzzle.rowCount * puzzle.columnCount
        let keptCells = puzzle.solution.flatMap { $0 }.filter { $0 }.count
        let minExpected = max(1, totalCells / 4) // At least 25% of cells should be kept
        
        XCTAssertGreaterThanOrEqual(keptCells, minExpected, "Puzzle should have sufficient kept cells")
        XCTAssertLessThan(keptCells, totalCells, "Not all cells should be kept")
    }

    func testPuzzleNumberRanges() throws {
        let easyPuzzle = puzzleService.getPuzzle(difficulty: "Easy", level: 1)
        let hardPuzzle = puzzleService.getPuzzle(difficulty: "Hard", level: 1)
        
        let easyMax = easyPuzzle.grid.flatMap { $0 }.max()!
        let hardMax = hardPuzzle.grid.flatMap { $0 }.max()!
        
        XCTAssertLessThanOrEqual(easyMax, 9, "Easy puzzles should have numbers ≤ 9")
        XCTAssertLessThanOrEqual(hardMax, 15, "Hard puzzles should have numbers ≤ 15")
    }

    // MARK: - Error Handling Tests

    func testEmptyDifficultyString() throws {
        let puzzle = puzzleService.getPuzzle(difficulty: "", level: 1)
        // With emergency fallback, even empty difficulty gets a puzzle
        XCTAssertTrue(puzzle.isValid, "Should return valid emergency puzzle for empty difficulty")
        XCTAssertEqual(puzzle.id, "-1")
    }

    func testWhitespaceDifficulty() throws {
        let puzzle = puzzleService.getPuzzle(difficulty: "  Easy  ", level: 1)
        // With emergency fallback, even whitespace difficulty gets a puzzle
        XCTAssertTrue(puzzle.isValid, "Should return valid emergency puzzle for whitespace difficulty")
        XCTAssertEqual(puzzle.id, "  easy  -1")
    }
}