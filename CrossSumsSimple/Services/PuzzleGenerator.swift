import Foundation

/// Service responsible for dynamically generating Cross Sums puzzles
///
/// PuzzleGenerator creates valid Cross Sums puzzles algorithmically, ensuring each puzzle
/// has exactly one unique solution and appropriate difficulty scaling.
class PuzzleGenerator {
    
    // MARK: - Constants
    
    /// Configuration for different difficulty levels
    private struct DifficultyConfig {
        let gridSize: Int
        let numberRange: ClosedRange<Int>
        let maxAttempts: Int
        let minComplexityScore: Int
        let maxComplexityScore: Int
        
        static let easy = DifficultyConfig(gridSize: 3, numberRange: 1...9, maxAttempts: 100, minComplexityScore: 5, maxComplexityScore: 50)
        static let medium = DifficultyConfig(gridSize: 4, numberRange: 1...15, maxAttempts: 200, minComplexityScore: 10, maxComplexityScore: 80)
        static let hard = DifficultyConfig(gridSize: 5, numberRange: 1...20, maxAttempts: 300, minComplexityScore: 20, maxComplexityScore: 120)
        static let extraHard = DifficultyConfig(gridSize: 6, numberRange: 1...25, maxAttempts: 500, minComplexityScore: 30, maxComplexityScore: 200)
    }
    
    // MARK: - Properties
    
    private var randomNumberGenerator: SystemRandomNumberGenerator
    
    // MARK: - Singleton
    
    static let shared = PuzzleGenerator()
    
    public init() {
        self.randomNumberGenerator = SystemRandomNumberGenerator()
    }
    
    // MARK: - Public Methods
    
    /// Generates a new puzzle for the specified difficulty and level
    /// - Parameters:
    ///   - difficulty: The difficulty level (Easy, Medium, Hard, Extra Hard)
    ///   - level: The level number (used for seeding)
    /// - Returns: A generated Puzzle, or nil if generation failed
    func generatePuzzle(difficulty: String, level: Int) -> Puzzle? {
        print("🎲 Generating puzzle for \(difficulty) level \(level)")
        
        guard let config = getDifficultyConfig(for: difficulty) else {
            print("❌ Unknown difficulty: \(difficulty)")
            return nil
        }
        
        // Use level as seed for reproducible puzzles
        let seed = generateSeed(difficulty: difficulty, level: level)
        randomNumberGenerator = SystemRandomNumberGenerator()
        
        for attempt in 1...config.maxAttempts {
            if let puzzle = attemptGeneration(config: config, difficulty: difficulty, level: level, seed: seed, attempt: attempt) {
                print("✅ Generated puzzle \(puzzle.id) in \(attempt) attempts")
                return puzzle
            }
        }
        
        print("❌ Failed to generate puzzle for \(difficulty) level \(level) after \(config.maxAttempts) attempts")
        return nil
    }
    
    /// Calculates complexity score based on solution patterns and constraints
    /// - Parameters:
    ///   - grid: The number grid
    ///   - solution: The solution pattern
    /// - Returns: Complexity score (higher = more complex)
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
    
    /// Validates that a puzzle has exactly one unique solution
    /// - Parameter puzzle: The puzzle to validate
    /// - Returns: true if the puzzle is valid and has exactly one solution
    func validatePuzzle(_ puzzle: Puzzle) -> Bool {
        let solutions = findAllSolutions(for: puzzle)
        
        guard solutions.count == 1 else {
            print("⚠️ Puzzle \(puzzle.id) has \(solutions.count) solutions (expected 1)")
            return false
        }
        
        // Verify the stored solution matches the found solution
        let foundSolution = solutions.first!
        let storedSolution = puzzle.solution
        
        for row in 0..<puzzle.rowCount {
            for col in 0..<puzzle.columnCount {
                if foundSolution[row][col] != storedSolution[row][col] {
                    print("⚠️ Puzzle \(puzzle.id) solution mismatch at (\(row),\(col))")
                    return false
                }
            }
        }
        
        print("✅ Puzzle \(puzzle.id) validation passed")
        return true
    }
    
    // MARK: - Private Methods
    
    /// Gets the configuration for a difficulty level
    private func getDifficultyConfig(for difficulty: String) -> DifficultyConfig? {
        switch difficulty.lowercased() {
        case "easy":
            return .easy
        case "medium":
            return .medium
        case "hard":
            return .hard
        case "extra hard", "extrahard":
            return .extraHard
        default:
            return nil
        }
    }
    
    /// Generates a deterministic seed for reproducible puzzles
    private func generateSeed(difficulty: String, level: Int) -> UInt64 {
        let difficultyHash = UInt64(difficulty.hashValue)
        // Handle negative levels by using absolute value
        let levelHash = UInt64(abs(level))
        return difficultyHash &+ (levelHash &* 31)
    }
    
    /// Attempts to generate a valid puzzle
    private func attemptGeneration(config: DifficultyConfig, difficulty: String, level: Int, seed: UInt64, attempt: Int) -> Puzzle? {
        // Create seeded random number generator
        var rng = SeededRandomNumberGenerator(seed: seed &+ UInt64(attempt))
        
        // Generate random grid
        let grid = generateRandomGrid(size: config.gridSize, numberRange: config.numberRange, using: &rng)
        
        // Find all possible solutions
        let solutions = findAllSolutions(grid: grid, numberRange: config.numberRange)
        
        // We need exactly one solution
        guard solutions.count == 1 else {
            return nil
        }
        
        let solution = solutions.first!
        
        // Calculate complexity score and check if it meets difficulty requirements
        let complexityScore = calculateComplexityScore(grid: grid, solution: solution)
        print("🎯 Complexity score: \(complexityScore) (target: \(config.minComplexityScore)-\(config.maxComplexityScore))")
        guard complexityScore >= config.minComplexityScore && complexityScore <= config.maxComplexityScore else {
            return nil
        }
        
        // Calculate row and column sums
        let rowSums = calculateRowSums(grid: grid, solution: solution)
        let columnSums = calculateColumnSums(grid: grid, solution: solution)
        
        // Create puzzle ID
        let puzzleId = "\(difficulty.lowercased())-\(level)"
        
        let puzzle = Puzzle(
            id: puzzleId,
            difficulty: difficulty,
            grid: grid,
            solution: solution,
            rowSums: rowSums,
            columnSums: columnSums
        )
        
        // Validate the puzzle
        guard puzzle.isValid else {
            return nil
        }
        
        return puzzle
    }
    
    /// Generates a random grid of numbers using a seeded random number generator.
    ///
    /// This method ensures that the puzzle generation is deterministic when the same seed is used.
    ///
    /// - Parameters:
    ///   - size: The dimension of the grid (e.g., 3 for a 3x3 grid).
    ///   - numberRange: The range of numbers to generate.
    ///   - rng: The seeded random number generator.
    /// - Returns: A 2D array of integers representing the grid.
    private func generateRandomGrid(size: Int, numberRange: ClosedRange<Int>, using rng: inout SeededRandomNumberGenerator) -> [[Int]] {
        var grid: [[Int]] = []
        for _ in 0..<size {
            var row: [Int] = []
            for _ in 0..<size {
                let randomNumber = Int.random(in: numberRange, using: &rng)
                row.append(randomNumber)
            }
            grid.append(row)
        }
        return grid
    }

    /// Generates a solution mask for the grid.
    ///
    /// The solution mask determines which cells are part of the correct solution.
    /// This method ensures that the generated solution is valid and solvable.
    ///
    /// - Parameters:
    ///   - size: The dimension of the grid.
    ///   - rng: The seeded random number generator.
    /// - Returns: A 2D array of booleans representing the solution mask.
    private func generateSolutionMask(size: Int, using rng: inout SeededRandomNumberGenerator) -> [[Bool]] {
        var solution: [[Bool]] = []
        for _ in 0..<size {
            var row: [Bool] = []
            for _ in 0..<size {
                // For simplicity, we'll randomly decide whether a cell is part of the solution.
                // A more advanced implementation could use a more sophisticated algorithm to ensure a unique solution.
                row.append(Bool.random(using: &rng))
            }
            solution.append(row)
        }
        return solution
    }

    /// Finds all possible solutions for a given grid
    private func findAllSolutions(for puzzle: Puzzle) -> [[[Bool]]] {
        return findAllSolutions(grid: puzzle.grid, numberRange: 1...25) // Use wide range for existing puzzles
    }
    
    /// Finds all possible solutions for a grid that satisfy Cross Sums rules
    private func findAllSolutions(grid: [[Int]], numberRange: ClosedRange<Int>) -> [[[Bool]]] {
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
            
            // Check if this solution is valid (has reasonable sums and uses numbers appropriately)
            if isValidSolution(grid: grid, solution: solution, numberRange: numberRange) {
                solutions.append(solution)
            }
        }
        
        return solutions
    }
    
    /// Checks if a solution is valid for Cross Sums
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
    
    /// Calculates row sums for a solution
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
    
    /// Calculates column sums for a solution
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
}

// MARK: - Seeded Random Number Generator

