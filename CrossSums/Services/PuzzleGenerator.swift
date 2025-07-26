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
        
        static let easy = DifficultyConfig(gridSize: 3, numberRange: 1...9, maxAttempts: 100)
        static let medium = DifficultyConfig(gridSize: 4, numberRange: 1...15, maxAttempts: 200)
        static let hard = DifficultyConfig(gridSize: 5, numberRange: 1...20, maxAttempts: 300)
        static let extraHard = DifficultyConfig(gridSize: 6, numberRange: 1...25, maxAttempts: 500)
    }
    
    // MARK: - Properties
    
    private var randomNumberGenerator: SystemRandomNumberGenerator
    
    // MARK: - Singleton
    
    static let shared = PuzzleGenerator()
    
    private init() {
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
        let levelHash = UInt64(level)
        return difficultyHash &+ (levelHash &* 31)
    }
    
    /// Attempts to generate a valid puzzle
    private func attemptGeneration(config: DifficultyConfig, difficulty: String, level: Int, seed: UInt64, attempt: Int) -> Puzzle? {
        // Generate random grid
        let grid = generateRandomGrid(size: config.gridSize, numberRange: config.numberRange, seed: seed &+ UInt64(attempt))
        
        // Find all possible solutions
        let solutions = findAllSolutions(grid: grid, numberRange: config.numberRange)
        
        // We need exactly one solution
        guard solutions.count == 1 else {
            return nil
        }
        
        let solution = solutions.first!
        
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
    
    /// Generates a random grid of numbers
    private func generateRandomGrid(size: Int, numberRange: ClosedRange<Int>, seed: UInt64) -> [[Int]] {
        // Use seed for reproducible generation
        var rng = SeededRandomNumberGenerator(seed: seed)
        
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

/// A random number generator that uses a seed for reproducible results
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        // Linear congruential generator
        state = state &* 1103515245 &+ 12345
        return state
    }
}