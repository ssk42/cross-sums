import Foundation

/// Service responsible for loading and managing puzzle data
/// 
/// Loads puzzles from JSON files, provides caching for performance,
/// and validates puzzle integrity to ensure a good game experience.
public protocol PuzzleServiceProtocol {
    func getPuzzle(difficulty: String, level: Int) -> Puzzle?
    func getMaxLevel(for difficulty: String) -> Int
    func getAvailableDifficulties() -> [String]
}

public class PuzzleService: PuzzleServiceProtocol {
    
    // MARK: - Constants
    
    private static let puzzleFileName = "puzzles.json"
    
    // MARK: - Properties
    
    private var puzzleCache: [String: [Puzzle]] = [:]
    private var isLoaded = false
    private var generatedPuzzleCache: [String: Puzzle] = [:]
    private let puzzleGenerator = EmbeddedPuzzleGenerator.shared
    private let cacheQueue = DispatchQueue(label: "com.crosssums.puzzlecache", attributes: .concurrent)
    
    // MARK: - Singleton
    
    static let shared = PuzzleService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Gets a specific puzzle by difficulty and level
    /// - Parameters:
    ///   - difficulty: The difficulty level (e.g., "Easy", "Medium", "Hard", "Extra Hard")
    ///   - level: The level number within that difficulty
    /// - Returns: The requested Puzzle, or nil if not found
    public func getPuzzle(difficulty: String, level: Int) -> Puzzle? {
        let puzzleKey = "\(difficulty.lowercased())-\(level)"
        
        // Thread-safe cache check
        let existingPuzzle = cacheQueue.sync {
            return generatedPuzzleCache[puzzleKey]
        }
        
        if let cachedGeneratedPuzzle = existingPuzzle {
            print("✅ Returning cached generated puzzle: \(puzzleKey)")
            return cachedGeneratedPuzzle
        }
        
        // Generate puzzle (this is the expensive operation)
        print("🎲 Generating new puzzle for \(difficulty) level \(level)")
        if let generatedPuzzle = puzzleGenerator.generatePuzzle(difficulty: difficulty, level: level) {
            // Thread-safe cache write
            cacheQueue.async(flags: .barrier) {
                self.generatedPuzzleCache[puzzleKey] = generatedPuzzle
            }
            print("✅ Generated and cached new puzzle: \(puzzleKey)")
            return generatedPuzzle
        }
        
        // Only fall back to static puzzles if generation fails
        loadPuzzlesIfNeeded()
        
        if let puzzlesForDifficulty = puzzleCache[difficulty] {
            if let staticPuzzle = puzzlesForDifficulty.first(where: { $0.id.contains("-\(level)") }) {
                print("⚠️ Falling back to static puzzle: \(puzzleKey)")
                return staticPuzzle
            }
        }
        
        print("❌ Failed to find or generate puzzle for \(difficulty) level \(level)")
        return nil
    }
    
    /// Gets all puzzles for a specific difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Array of puzzles for that difficulty, or empty array if none found
    public func getPuzzles(for difficulty: String) -> [Puzzle] {
        loadPuzzlesIfNeeded()
        return puzzleCache[difficulty] ?? []
    }
    
    /// Gets all available difficulties
    /// - Returns: Array of difficulty strings
    public func getAvailableDifficulties() -> [String] {
        // With dynamic generation, all difficulties are always available
        return ["Easy", "Medium", "Hard", "Extra Hard"]
    }
    
    /// Gets the number of levels available for a difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Number of levels available
    public func getLevelCount(for difficulty: String) -> Int {
        loadPuzzlesIfNeeded()
        return puzzleCache[difficulty]?.count ?? 0
    }
    
    /// Gets the highest available level for a difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: The highest level number, or Int.max for infinite generation
    public func getMaxLevel(for difficulty: String) -> Int {
        // With dynamic generation, we support infinite levels
        // Return a very high number to represent "unlimited"
        return 999999
    }
    
    /// Validates that all puzzles have correct solutions
    /// - Returns: Dictionary mapping puzzle IDs to validation results
    public func validateAllPuzzles() -> [String: Bool] {
        loadPuzzlesIfNeeded()
        
        var results: [String: Bool] = [:]
        
        for (difficulty, puzzles) in puzzleCache {
            for puzzle in puzzles {
                let isValid = validatePuzzle(puzzle)
                results[puzzle.id] = isValid
                
                if !isValid {
                    print("⚠️ Invalid puzzle found: \(puzzle.id) in \(difficulty)")
                }
            }
        }
        
        return results
    }
    
    /// Clears the puzzle cache and forces reload on next access
    public func clearCache() {
        puzzleCache.removeAll()
        generatedPuzzleCache.removeAll()
        isLoaded = false
        print("🗑️ Puzzle cache cleared - will use dynamic generation")
    }
    
    /// Forces regeneration of all puzzles (clears generated cache)
    public func forceRegeneration() {
        generatedPuzzleCache.removeAll()
        print("🎲 Forced regeneration - all puzzles will be dynamically generated")
    }
    
    // MARK: - Private Methods
    
    /// Loads puzzles from JSON file if not already loaded
    private func loadPuzzlesIfNeeded() {
        guard !isLoaded else { return }
        loadAllPuzzles()
    }
    
    /// Loads all puzzles from the JSON file
    private func loadAllPuzzles() {
        print("🔍 PuzzleService: Attempting to load \(Self.puzzleFileName)")
        
        let resourceName = Self.puzzleFileName.replacingOccurrences(of: ".json", with: "")
        print("🔍 Looking for resource: '\(resourceName)' with extension: 'json'")
        
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            print("❌ Failed to find puzzle file in bundle: \(Self.puzzleFileName)")
            print("❌ Searched for: '\(resourceName).json'")
            
            // Debug: List all files in bundle
            if let bundlePath = Bundle.main.resourcePath {
                print("📂 Bundle path: \(bundlePath)")
                let fileManager = FileManager.default
                do {
                    let files = try fileManager.contentsOfDirectory(atPath: bundlePath)
                    print("📂 Files in bundle: \(files.filter { $0.contains("puzzle") || $0.contains("json") })")
                } catch {
                    print("❌ Could not list bundle contents: \(error)")
                }
            }
            return
        }
        
        print("✅ Found puzzle file at: \(url.path)")
        
        guard let data = try? Data(contentsOf: url) else {
            print("❌ Failed to read data from puzzle file: \(url.path)")
            return
        }
        
        print("✅ Loaded \(data.count) bytes from puzzle file")
        
        do {
            let decoder = JSONDecoder()
            let puzzleData = try decoder.decode(PuzzleData.self, from: data)
            
            // Organize puzzles by difficulty
            puzzleCache.removeAll()
            
            for puzzle in puzzleData.puzzles {
                if puzzleCache[puzzle.difficulty] == nil {
                    puzzleCache[puzzle.difficulty] = []
                }
                puzzleCache[puzzle.difficulty]?.append(puzzle)
            }
            
            // Sort puzzles by level within each difficulty
            for difficulty in puzzleCache.keys {
                puzzleCache[difficulty]?.sort { puzzle1, puzzle2 in
                    let level1 = extractLevelNumber(from: puzzle1.id) ?? 0
                    let level2 = extractLevelNumber(from: puzzle2.id) ?? 0
                    return level1 < level2
                }
            }
            
            isLoaded = true
            
            let totalPuzzles = puzzleCache.values.map { $0.count }.reduce(0, +)
            print("✅ Loaded \(totalPuzzles) puzzles across \(puzzleCache.count) difficulties")
            
            // Print summary
            for (difficulty, puzzles) in puzzleCache {
                print("  - \(difficulty): \(puzzles.count) puzzles")
            }
            
        } catch {
            print("❌ Failed to decode puzzle data: \(error.localizedDescription)")
        }
    }
    
    /// Validates a single puzzle for correctness
    /// - Parameter puzzle: The puzzle to validate
    /// - Returns: true if the puzzle is valid, false otherwise
    private func validatePuzzle(_ puzzle: Puzzle) -> Bool {
        // Check basic structure
        guard puzzle.isValid else {
            print("❌ Puzzle \(puzzle.id) has invalid structure")
            return false
        }
        
        // Validate that the solution produces the correct sums
        for (rowIndex, targetSum) in puzzle.rowSums.enumerated() {
            let actualSum = puzzle.calculateRowSum(for: puzzle.solution, row: rowIndex)
            if actualSum != targetSum {
                print("❌ Puzzle \(puzzle.id) row \(rowIndex): expected \(targetSum), got \(actualSum ?? -1)")
                return false
            }
        }
        
        for (colIndex, targetSum) in puzzle.columnSums.enumerated() {
            let actualSum = puzzle.calculateColumnSum(for: puzzle.solution, column: colIndex)
            if actualSum != targetSum {
                print("❌ Puzzle \(puzzle.id) column \(colIndex): expected \(targetSum), got \(actualSum ?? -1)")
                return false
            }
        }
        
        return true
    }
    
    /// Extracts the level number from a puzzle ID
    /// - Parameter puzzleId: The puzzle ID (format: "difficulty-level")
    /// - Returns: The level number, or nil if not found
    private func extractLevelNumber(from puzzleId: String) -> Int? {
        let components = puzzleId.split(separator: "-")
        return components.last.flatMap { Int($0) }
    }
    
    // MARK: - Debug Methods
    
    /// Prints debug information about loaded puzzles
    public func debugPrintPuzzles() {
        loadPuzzlesIfNeeded()
        
        print("🐛 Debug Puzzle Info:")
        print("  - Is Loaded: \(isLoaded)")
        print("  - Difficulties: \(puzzleCache.keys.sorted())")
        
        for (difficulty, puzzles) in puzzleCache {
            print("  - \(difficulty):")
            for puzzle in puzzles.prefix(3) { // Show first 3 puzzles
                print("    - \(puzzle.id): \(puzzle.rowCount)x\(puzzle.columnCount)")
            }
            if puzzles.count > 3 {
                print("    - ... and \(puzzles.count - 3) more")
            }
        }
    }
    
    /// Gets memory usage information
    /// - Returns: Estimated memory usage in bytes
    public func getMemoryUsage() -> Int {
        let puzzleCount = puzzleCache.values.map { $0.count }.reduce(0, +)
        return puzzleCount * 1024 // Rough estimate
    }
}

// MARK: - Supporting Types

/// Root structure for puzzle JSON data
private struct PuzzleData: Codable {
    let puzzles: [Puzzle]
}

// MARK: - Embedded Puzzle Generator

/// Embedded puzzle generator for dynamic puzzle creation
class EmbeddedPuzzleGenerator {
    
    static let shared = EmbeddedPuzzleGenerator()
     public init() {}
    
    /// Configuration for different difficulty levels
    private struct DifficultyConfig {
        let gridSize: Int
        let numberRange: ClosedRange<Int>
        let maxAttempts: Int
        
        static let easy = DifficultyConfig(gridSize: 3, numberRange: 1...9, maxAttempts: 5)
        static let medium = DifficultyConfig(gridSize: 4, numberRange: 1...12, maxAttempts: 5)
        static let hard = DifficultyConfig(gridSize: 4, numberRange: 1...15, maxAttempts: 5)
        static let extraHard = DifficultyConfig(gridSize: 5, numberRange: 1...18, maxAttempts: 5)
    }
    
    /// Generates a new puzzle for the specified difficulty and level
    func generatePuzzle(difficulty: String, level: Int) -> Puzzle? {
        print("🎲 Generating puzzle for \(difficulty) level \(level)")
        
        guard let config = getDifficultyConfig(for: difficulty) else {
            print("❌ Unknown difficulty: \(difficulty)")
            return nil
        }
        
        // Use level as seed for reproducible puzzles  
        // Handle negative levels by using absolute value
        let baseSeed = UInt64(abs(difficulty.hashValue)) &+ UInt64(abs(level)) &+ 1000
        
        for attempt in 1...config.maxAttempts {
            // Use different seed for each attempt to avoid getting stuck
            var rng = SeededRandomNumberGenerator(seed: baseSeed &+ UInt64(attempt))
            
            if let puzzle = attemptGeneration(config: config, difficulty: difficulty, level: level, rng: &rng) {
                print("✅ Generated puzzle \(puzzle.id) in \(attempt) attempts")
                return puzzle
            }
        }
        
        print("❌ Failed to generate puzzle for \(difficulty) level \(level)")
        return nil
    }
    
    private func getDifficultyConfig(for difficulty: String) -> DifficultyConfig? {
        switch difficulty.lowercased() {
        case "easy": return .easy
        case "medium": return .medium
        case "hard": return .hard
        case "extra hard", "extrahard": return .extraHard
        default: return nil
        }
    }
    
    private func attemptGeneration(config: DifficultyConfig, difficulty: String, level: Int, rng: inout SeededRandomNumberGenerator) -> Puzzle? {
        // Generate simple grid patterns for testing
        let size = config.gridSize
        var grid: [[Int]] = []
        
        for _ in 0..<size {
            var row: [Int] = []
            for _ in 0..<size {
                let number = Int.random(in: config.numberRange, using: &rng)
                row.append(number)
            }
            grid.append(row)
        }
        
        // Create a simple solution pattern (checkerboard-like)
        var solution: [[Bool]] = []
        for row in 0..<size {
            var solutionRow: [Bool] = []
            for col in 0..<size {
                // Checkerboard pattern with some randomness
                let isKept = (row + col) % 2 == 0 ? Bool.random(using: &rng) : !Bool.random(using: &rng)
                solutionRow.append(isKept)
            }
            solution.append(solutionRow)
        }
        
        // Ensure at least 1/3 of cells are kept
        let totalCells = size * size
        let minKeptCells = max(1, totalCells / 3)
        var keptCount = solution.flatMap { $0 }.filter { $0 }.count
        
        if keptCount < minKeptCells {
            // Flip some false values to true, but limit attempts to prevent infinite loops
            var attempts = 0
            let maxFlipAttempts = totalCells * 2
            
            outerLoop: for row in 0..<size {
                for col in 0..<size {
                    attempts += 1
                    if attempts > maxFlipAttempts { break outerLoop }
                    
                    if !solution[row][col] && Bool.random(using: &rng) {
                        solution[row][col] = true
                        keptCount += 1
                        
                        if keptCount >= minKeptCells {
                            break outerLoop
                        }
                    }
                }
            }
        }
        
        // Calculate sums
        let rowSums = calculateRowSums(grid: grid, solution: solution)
        let columnSums = calculateColumnSums(grid: grid, solution: solution)
        
        let puzzleId = "\(difficulty.lowercased())-\(level)"
        
        return Puzzle(
            id: puzzleId,
            difficulty: difficulty,
            grid: grid,
            solution: solution,
            rowSums: rowSums,
            columnSums: columnSums
        )
    }
    
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

/// A simple seeded random number generator
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 1103515245 &+ 12345
        return state
    }
}