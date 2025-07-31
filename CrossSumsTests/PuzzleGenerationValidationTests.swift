import XCTest
@testable import Simple_Cross_Sums

/// Comprehensive tests for puzzle generation and validation, specifically targeting
/// the issue where Extra Hard puzzles may have multiple valid solutions
class PuzzleGenerationValidationTests: XCTestCase {
    
    var puzzleGenerator: PuzzleGenerator!
    
    override func setUpWithError() throws {
        puzzleGenerator = PuzzleGenerator()
    }
    
    override func tearDownWithError() throws {
        puzzleGenerator = nil
    }
    
    // MARK: - Solution Uniqueness Tests
    
    func testExtraHardPuzzlesHaveUniqueSolutions() throws {
        let testCount = 10
        var multiSolutionPuzzles: [(Puzzle, Int)] = []
        
        print("🔍 Testing \(testCount) Extra Hard puzzles for solution uniqueness...")
        
        for level in 1...testCount {
            guard let puzzle = puzzleGenerator.generatePuzzle(difficulty: "Extra Hard", level: level) else {
                XCTFail("Failed to generate Extra Hard puzzle for level \(level)")
                continue
            }
            
            // Use the private findAllSolutions method through validation
            let solutionCount = countAllSolutions(for: puzzle)
            
            if solutionCount != 1 {
                multiSolutionPuzzles.append((puzzle, solutionCount))
                print("❌ Puzzle \(puzzle.id) has \(solutionCount) solutions (expected 1)")
                print("   Grid: \(puzzle.grid)")
                print("   Solution: \(puzzle.solution)")
                print("   Row sums: \(puzzle.rowSums)")
                print("   Column sums: \(puzzle.columnSums)")
            } else {
                print("✅ Puzzle \(puzzle.id) has exactly 1 solution")
            }
        }
        
        if !multiSolutionPuzzles.isEmpty {
            let summary = multiSolutionPuzzles.map { "Puzzle \($0.0.id): \($0.1) solutions" }.joined(separator: ", ")
            XCTFail("Found \(multiSolutionPuzzles.count) Extra Hard puzzles with multiple solutions: \(summary)")
        }
    }
    
    func testAllDifficultiesUniqueSolutions() throws {
        let difficulties = ["Easy", "Medium", "Hard", "Extra Hard"]
        var issues: [String] = []
        
        for difficulty in difficulties {
            for level in 1...3 { // Test fewer levels per difficulty for performance
                guard let puzzle = puzzleGenerator.generatePuzzle(difficulty: difficulty, level: level) else {
                    issues.append("\(difficulty) level \(level): Generation failed")
                    continue
                }
                
                let solutionCount = countAllSolutions(for: puzzle)
                if solutionCount != 1 {
                    issues.append("\(difficulty) level \(level): \(solutionCount) solutions")
                    print("❌ \(difficulty) puzzle \(puzzle.id) has \(solutionCount) solutions")
                }
            }
        }
        
        if !issues.isEmpty {
            XCTFail("Solution uniqueness issues found: \(issues.joined(separator: "; "))")
        }
    }
    
    // MARK: - findAllSolutions Method Testing
    
    func testFindAllSolutionsAccuracy() throws {
        print("🔍 Testing findAllSolutions method accuracy with known test cases...")
        
        // Test case 1: Simple 3x3 grid with known unique solution
        let grid1 = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9]
        ]
        let knownSolution1 = [
            [true, false, true],
            [false, true, false],
            [true, false, true]
        ]
        let rowSums1 = [4, 5, 16] // 1+3, 5, 7+9
        let columnSums1 = [8, 5, 12] // 1+7, 5, 3+9
        
        let puzzle1 = Puzzle(id: "test-1", difficulty: "Test", grid: grid1, solution: knownSolution1, rowSums: rowSums1, columnSums: columnSums1)
        let solutions1 = findAllSolutionsForPuzzle(puzzle: puzzle1)
        
        print("Test case 1: Found \(solutions1.count) solutions")
        XCTAssertEqual(solutions1.count, 1, "Simple test case should have exactly 1 solution")
        
        if solutions1.count == 1 {
            XCTAssertEqual(solutions1[0], knownSolution1, "Found solution should match known solution")
        }
    }
    
    func testFindAllSolutionsWithMultipleSolutions() throws {
        print("🔍 Testing findAllSolutions with a grid that has multiple solutions...")
        
        // Create a simple grid where multiple solutions exist
        let grid = [
            [2, 2, 2],
            [2, 2, 2],
            [2, 2, 2]
        ]
        // Target sums that could have multiple valid solutions
        let rowSums = [4, 4, 4] // Each row needs sum of 4 (2 cells)
        let columnSums = [4, 4, 4] // Each column needs sum of 4 (2 cells)
        
        // This should have multiple solutions since many patterns can achieve these sums
        let puzzle = Puzzle(id: "multi-test", difficulty: "Test", grid: grid, solution: [], rowSums: rowSums, columnSums: columnSums)
        let solutions = findAllSolutionsForGrid(grid: grid, targetRowSums: rowSums, targetColumnSums: columnSums)
        
        print("Multiple solution test: Found \(solutions.count) solutions")
        XCTAssertGreaterThan(solutions.count, 1, "This test case should have multiple solutions")
        
        // Verify each solution is actually valid
        for (index, solution) in solutions.enumerated() {
            let actualRowSums = calculateRowSums(grid: grid, solution: solution)
            let actualColumnSums = calculateColumnSums(grid: grid, solution: solution)
            
            XCTAssertEqual(actualRowSums, rowSums, "Solution \(index) should have correct row sums")
            XCTAssertEqual(actualColumnSums, columnSums, "Solution \(index) should have correct column sums")
        }
    }
    
    // MARK: - Complexity Scoring Tests
    
    func testComplexityScoring() throws {
        print("🔍 Testing complexity scoring for different difficulties...")
        
        let difficulties = ["Easy", "Medium", "Hard", "Extra Hard"]
        
        for difficulty in difficulties {
            guard let puzzle = puzzleGenerator.generatePuzzle(difficulty: difficulty, level: 1) else {
                XCTFail("Failed to generate \(difficulty) puzzle")
                continue
            }
            
            let complexityScore = calculateComplexityScore(grid: puzzle.grid, solution: puzzle.solution)
            print("\(difficulty) puzzle complexity score: \(complexityScore)")
            
            // Verify complexity scores increase with difficulty
            switch difficulty {
            case "Easy":
                XCTAssertGreaterThanOrEqual(complexityScore, 5, "Easy puzzles should have minimum complexity")
                XCTAssertLessThanOrEqual(complexityScore, 50, "Easy puzzles should not be too complex")
            case "Medium":
                XCTAssertGreaterThanOrEqual(complexityScore, 10, "Medium puzzles should have higher complexity")
                XCTAssertLessThanOrEqual(complexityScore, 80, "Medium puzzles should have reasonable complexity")
            case "Hard":
                XCTAssertGreaterThanOrEqual(complexityScore, 20, "Hard puzzles should have significant complexity")
                XCTAssertLessThanOrEqual(complexityScore, 120, "Hard puzzles should have bounded complexity")
            case "Extra Hard":
                XCTAssertGreaterThanOrEqual(complexityScore, 30, "Extra Hard puzzles should have high complexity")
                XCTAssertLessThanOrEqual(complexityScore, 200, "Extra Hard puzzles should have very high complexity")
            default:
                break
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testSolutionValidationEdgeCases() throws {
        print("🔍 Testing solution validation edge cases...")
        
        // Test case: All cells kept (should be invalid)
        let gridAllKept = [[1, 2], [3, 4]]
        let solutionAllKept = [[true, true], [true, true]]
        XCTAssertFalse(isValidSolution(grid: gridAllKept, solution: solutionAllKept, numberRange: 1...10), "All cells kept should be invalid")
        
        // Test case: No cells kept (should be invalid)
        let solutionNoneKept = [[false, false], [false, false]]
        XCTAssertFalse(isValidSolution(grid: gridAllKept, solution: solutionNoneKept, numberRange: 1...10), "No cells kept should be invalid")
        
        // Test case: Valid solution
        let validSolution = [[true, false], [false, true]]
        XCTAssertTrue(isValidSolution(grid: gridAllKept, solution: validSolution, numberRange: 1...10), "Valid solution should pass validation")
    }
    
    func testLargePuzzlePerformance() throws {
        print("🔍 Testing large puzzle generation performance...")
        
        measure {
            // Test generation time for Extra Hard puzzles (largest size)
            _ = puzzleGenerator.generatePuzzle(difficulty: "Extra Hard", level: 1)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Counts all possible solutions for a puzzle using brute force validation
    private func countAllSolutions(for puzzle: Puzzle) -> Int {
        return findAllSolutionsForPuzzle(puzzle: puzzle).count
    }
    
    /// Finds all solutions for a puzzle by testing all possible combinations
    private func findAllSolutionsForPuzzle(puzzle: Puzzle) -> [[[Bool]]] {
        return findAllSolutionsForGrid(grid: puzzle.grid, targetRowSums: puzzle.rowSums, targetColumnSums: puzzle.columnSums)
    }
    
    /// Brute force solution finder for validation purposes
    private func findAllSolutionsForGrid(grid: [[Int]], targetRowSums: [Int], targetColumnSums: [Int]) -> [[[Bool]]] {
        let size = grid.count
        var solutions: [[[Bool]]] = []
        
        // Generate all possible combinations (2^(size*size) possibilities)
        let totalCells = size * size
        let totalCombinations = 1 << totalCells // 2^totalCells
        
        for combination in 0..<totalCombinations {
            var solution: [[Bool]] = Array(repeating: Array(repeating: false, count: size), count: size)
            
            // Convert combination number to grid pattern
            for cellIndex in 0..<totalCells {
                let row = cellIndex / size
                let col = cellIndex % size
                let isKept = (combination >> cellIndex) & 1 == 1
                solution[row][col] = isKept
            }
            
            // Check if this solution produces the target sums
            let actualRowSums = calculateRowSums(grid: grid, solution: solution)
            let actualColumnSums = calculateColumnSums(grid: grid, solution: solution)
            
            if actualRowSums == targetRowSums && actualColumnSums == targetColumnSums {
                // Additional validation to ensure it's a reasonable solution
                let keptCells = solution.flatMap { $0 }.filter { $0 }.count
                if keptCells > 0 && keptCells < totalCells {
                    solutions.append(solution)
                }
            }
        }
        
        return solutions
    }
    
    /// Calculate row sums for a given solution
    private func calculateRowSums(grid: [[Int]], solution: [[Bool]]) -> [Int] {
        let size = grid.count
        var rowSums: [Int] = []
        
        for row in 0..<size {
            var sum = 0
            for col in 0..<size {
                if solution[row][col] {
                    sum += grid[row][col]
                }
            }
            rowSums.append(sum)
        }
        
        return rowSums
    }
    
    /// Calculate column sums for a given solution
    private func calculateColumnSums(grid: [[Int]], solution: [[Bool]]) -> [Int] {
        let size = grid.count
        var columnSums: [Int] = []
        
        for col in 0..<size {
            var sum = 0
            for row in 0..<size {
                if solution[row][col] {
                    sum += grid[row][col]
                }
            }
            columnSums.append(sum)
        }
        
        return columnSums
    }
    
    /// Calculate complexity score using the same algorithm as PuzzleGenerator
    private func calculateComplexityScore(grid: [[Int]], solution: [[Bool]]) -> Int {
        let size = grid.count
        var score = 0
        
        // Base score for grid size
        score += size * size
        
        // Calculate row and column sums for analysis
        let rowSums = calculateRowSums(grid: grid, solution: solution)
        let columnSums = calculateColumnSums(grid: grid, solution: solution)
        
        // Score based on sum distribution complexity
        let allSums = rowSums + columnSums
        let uniqueSums = Set(allSums)
        score += uniqueSums.count * 2 // More unique sums = more complex
        
        // Score based on number of cells kept vs removed (balanced is more complex)
        let keptCells = solution.flatMap { $0 }.filter { $0 }.count
        let totalCells = size * size
        let balance = abs(keptCells - (totalCells - keptCells))
        score += max(0, 10 - balance) // More balanced = higher score
        
        // Score based on sum variance (more varied sums = more complex)
        if !allSums.isEmpty {
            let sumMean = Double(allSums.reduce(0, +)) / Double(allSums.count)
            let variance = allSums.map { pow(Double($0) - sumMean, 2) }.reduce(0, +) / Double(allSums.count)
            score += Int(variance / 10) // Scale variance to reasonable range
        }
        
        // Score based on alternating pattern complexity
        var alternatingPatterns = 0
        for row in 0..<size {
            for col in 0..<(size-1) {
                if solution[row][col] != solution[row][col+1] {
                    alternatingPatterns += 1
                }
            }
        }
        for col in 0..<size {
            for row in 0..<(size-1) {
                if solution[row][col] != solution[row+1][col] {
                    alternatingPatterns += 1
                }
            }
        }
        score += alternatingPatterns // More alternations = more complex
        
        return score
    }
    
    /// Validate solution using the same logic as PuzzleGenerator
    private func isValidSolution(grid: [[Int]], solution: [[Bool]], numberRange: ClosedRange<Int>) -> Bool {
        let size = grid.count
        
        // Calculate row sums
        var rowSums: [Int] = []
        for row in 0..<size {
            var sum = 0
            for col in 0..<size {
                if solution[row][col] {
                    sum += grid[row][col]
                }
            }
            rowSums.append(sum)
        }
        
        // Calculate column sums
        var columnSums: [Int] = []
        for col in 0..<size {
            var sum = 0
            for row in 0..<size {
                if solution[row][col] {
                    sum += grid[row][col]
                }
            }
            columnSums.append(sum)
        }
        
        // Validate sums are reasonable (not too low, not too high)
        let minReasonableSum = numberRange.lowerBound
        let maxReasonableSum = numberRange.upperBound * size
        
        for sum in rowSums + columnSums {
            if sum < minReasonableSum || sum > maxReasonableSum {
                return false
            }
        }
        
        // Ensure at least some cells are kept and some are removed
        let keptCells = solution.flatMap { $0 }.filter { $0 }.count
        let totalCells = size * size
        
        if keptCells < 1 || keptCells >= totalCells {
            return false
        }
        
        return true
    }
}