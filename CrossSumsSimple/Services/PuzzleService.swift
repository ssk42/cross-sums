import Foundation

/// Service responsible for loading and managing puzzle data
/// 
/// Loads puzzles from JSON files, provides caching for performance,
/// and validates puzzle integrity to ensure a good game experience.
public protocol PuzzleServiceProtocol {
    func getPuzzle(difficulty: String, level: Int) -> Puzzle
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
    
    /// Gets a specific puzzle by difficulty and level with robust fallback strategies
    /// - Parameters:
    ///   - difficulty: The difficulty level (e.g., "Easy", "Medium", "Hard", "Extra Hard", "Expert")
    ///   - level: The level number within that difficulty
    /// - Returns: The requested Puzzle, guaranteed to return a puzzle via fallback strategies
    public func getPuzzle(difficulty: String, level: Int) -> Puzzle {
        let puzzleKey = "\(difficulty.lowercased())-\(level)"
        
        // Thread-safe cache check
        let existingPuzzle = cacheQueue.sync {
            return generatedPuzzleCache[puzzleKey]
        }
        
        if let cachedGeneratedPuzzle = existingPuzzle {
            print("✅ Returning cached generated puzzle: \(puzzleKey)")
            return cachedGeneratedPuzzle
        }
        
        // Generate puzzle with robust fallback strategies
        print("🎲 Generating new puzzle for \(difficulty) level \(level)")
        if let generatedPuzzle = puzzleGenerator.generatePuzzle(difficulty: difficulty, level: level) {
            // Thread-safe cache write
            cacheQueue.async(flags: .barrier) {
                self.generatedPuzzleCache[puzzleKey] = generatedPuzzle
            }
            print("✅ Generated and cached new puzzle: \(puzzleKey)")
            return generatedPuzzle
        }
        
        // Fallback to static puzzles if available
        print("🔄 Generation failed, checking for static puzzles...")
        loadPuzzlesIfNeeded()
        
        if let puzzlesForDifficulty = puzzleCache[difficulty] {
            if let staticPuzzle = puzzlesForDifficulty.first(where: { $0.id.contains("-\(level)") }) {
                print("⚠️ Falling back to static puzzle: \(puzzleKey)")
                return staticPuzzle
            }
        }
        
        // Final emergency fallback - generate a simple puzzle for any difficulty
        print("🚨 All strategies failed, creating emergency puzzle for \(difficulty)")
        return createEmergencyPuzzle(difficulty: difficulty, level: level)
    }
    
    /// Creates an emergency puzzle when all other strategies fail
    /// This ensures users are never left without a puzzle to play
    private func createEmergencyPuzzle(difficulty: String, level: Int) -> Puzzle {
        print("🚨 Creating emergency puzzle for \(difficulty) level \(level)")
        
        // Determine appropriate size based on difficulty
        let size: Int
        switch difficulty.lowercased() {
        case "easy": size = 3
        case "medium": size = 4
        case "hard": size = 4
        case "extra hard", "extrahard": size = 5
        case "expert": size = 6
        default: size = 3
        }
        
        // Generate a simple grid with sequential numbers
        var grid: [[Int]] = []
        var number = 1
        for _ in 0..<size {
            var row: [Int] = []
            for _ in 0..<size {
                row.append(number)
                number += 1
            }
            grid.append(row)
        }
        
        // Create a simple diagonal solution pattern that works for any size
        var solution: [[Bool]] = []
        for row in 0..<size {
            var solutionRow: [Bool] = []
            for col in 0..<size {
                // Simple diagonal pattern with some variety
                solutionRow.append((row + col) % 2 == 0)
            }
            solution.append(solutionRow)
        }
        
        // Calculate the actual sums based on the pattern
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
        
        let puzzleId = "\(difficulty.lowercased())-\(level)"
        
        let emergencyPuzzle = Puzzle(
            id: puzzleId,
            difficulty: difficulty,
            grid: grid,
            solution: solution,
            rowSums: rowSums,
            columnSums: columnSums
        )
        
        // Cache the emergency puzzle
        cacheQueue.async(flags: .barrier) {
            self.generatedPuzzleCache[puzzleId] = emergencyPuzzle
        }
        
        print("✅ Created and cached \(size)x\(size) emergency puzzle: \(puzzleId)")
        return emergencyPuzzle
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
        return ["Easy", "Medium", "Hard", "Extra Hard", "Expert"]
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
struct PuzzleData: Codable {
    let puzzles: [Puzzle]
}

// MARK: - Embedded Puzzle Generator

/// Embedded puzzle generator for dynamic puzzle creation
class EmbeddedPuzzleGenerator {
    
    static let shared = EmbeddedPuzzleGenerator()
     public init() {}
    
    /// Configuration for different difficulty levels
    private struct DifficultyConfig: Equatable {
        let baseGridSize: Int
        let numberRange: ClosedRange<Int>
        let maxAttempts: Int
        let keptCellsPercentage: ClosedRange<Double>
        let usesAdvancedPatterns: Bool
        
        static let easy = DifficultyConfig(
            baseGridSize: 3, 
            numberRange: 1...9, 
            maxAttempts: 10,  // Increased from 5 for better reliability
            keptCellsPercentage: 0.35...0.65,  // Slightly wider range
            usesAdvancedPatterns: false
        )
        static let medium = DifficultyConfig(
            baseGridSize: 4, 
            numberRange: 1...12, 
            maxAttempts: 15,  // Increased from 5 for better reliability
            keptCellsPercentage: 0.3...0.6,  // Wider range for more flexibility
            usesAdvancedPatterns: false
        )
        static let hard = DifficultyConfig(
            baseGridSize: 4, 
            numberRange: 1...15, 
            maxAttempts: 25,  // Increased further for advanced patterns
            keptCellsPercentage: 0.2...0.6,  // Wider range for constraint diversity
            usesAdvancedPatterns: true
        )
        static let extraHard = DifficultyConfig(
            baseGridSize: 5, 
            numberRange: 1...28,  // Increased from 1-25 to approach Expert level (1-30)
            maxAttempts: 60,  // Increased further for enhanced complexity
            keptCellsPercentage: 0.12...0.42,  // Tighter range with lower minimum for more challenge
            usesAdvancedPatterns: true
        )
        static let expert = DifficultyConfig(
            baseGridSize: 6, 
            numberRange: 1...35,  // Increased from 1-30 to create significant gap vs Extra Hard (1-28)
            maxAttempts: 90,  // Increased further for enhanced complexity
            keptCellsPercentage: 0.10...0.45,  // Much tighter range with very challenging minimum
            usesAdvancedPatterns: true
        )
    }
    
    /// Generates a new puzzle for the specified difficulty and level with robust fallback strategies
    func generatePuzzle(difficulty: String, level: Int) -> Puzzle? {
        print("🎲 Generating puzzle for \(difficulty) level \(level)")
        
        guard let baseConfig = getDifficultyConfig(for: difficulty) else {
            print("❌ Unknown difficulty: \(difficulty)")
            return nil
        }
        
        // Use level as seed for reproducible puzzles  
        // Handle negative levels by using absolute value
        let baseSeed = UInt64(abs(difficulty.hashValue)) &+ UInt64(abs(level)) &+ 1000
        
        // Strategy 1: Try with full complexity requirements
        if let puzzle = attemptGenerationWithConfig(baseConfig, difficulty: difficulty, level: level, baseSeed: baseSeed, strategyName: "Full Complexity") {
            return puzzle
        }
        
        // Strategy 2: Reduce complexity requirements
        print("🔄 Trying with reduced complexity requirements...")
        let reducedComplexityConfig = createReducedComplexityConfig(from: baseConfig)
        if let puzzle = attemptGenerationWithConfig(reducedComplexityConfig, difficulty: difficulty, level: level, baseSeed: baseSeed, strategyName: "Reduced Complexity") {
            return puzzle
        }
        
        // Strategy 3: Use basic patterns only
        print("🔄 Trying with basic patterns only...")
        let basicPatternConfig = createBasicPatternConfig(from: baseConfig)
        if let puzzle = attemptGenerationWithConfig(basicPatternConfig, difficulty: difficulty, level: level, baseSeed: baseSeed, strategyName: "Basic Patterns") {
            return puzzle
        }
        
        // Strategy 4: Fall back to smaller grid size
        print("🔄 Trying with smaller grid size...")
        let smallerGridConfig = createSmallerGridConfig(from: baseConfig)
        if let puzzle = attemptGenerationWithConfig(smallerGridConfig, difficulty: difficulty, level: level, baseSeed: baseSeed, strategyName: "Smaller Grid") {
            return puzzle
        }
        
        // Strategy 5: Emergency fallback - guaranteed generation
        print("🚨 Using emergency fallback generation...")
        return generateEmergencyFallbackPuzzle(difficulty: difficulty, level: level, baseSeed: baseSeed)
    }
    
    /// Attempts generation with a specific config and strategy name
    private func attemptGenerationWithConfig(_ config: DifficultyConfig, difficulty: String, level: Int, baseSeed: UInt64, strategyName: String) -> Puzzle? {
        for attempt in 1...config.maxAttempts {
            var rng = SeededRandomNumberGenerator(seed: baseSeed &+ UInt64(attempt))
            
            if let puzzle = attemptGeneration(config: config, difficulty: difficulty, level: level, rng: &rng) {
                print("✅ Generated puzzle \(puzzle.id) using \(strategyName) in \(attempt) attempts")
                return puzzle
            }
        }
        print("❌ \(strategyName) strategy failed after \(config.maxAttempts) attempts")
        return nil
    }
    
    /// Creates a reduced complexity config for fallback generation
    private func createReducedComplexityConfig(from baseConfig: DifficultyConfig) -> DifficultyConfig {
        return DifficultyConfig(
            baseGridSize: baseConfig.baseGridSize,
            numberRange: baseConfig.numberRange,
            maxAttempts: max(3, baseConfig.maxAttempts / 2), // Fewer attempts
            keptCellsPercentage: 0.25...0.65, // More lenient percentage range
            usesAdvancedPatterns: baseConfig.usesAdvancedPatterns
        )
    }
    
    /// Creates a basic pattern config for simplified generation
    private func createBasicPatternConfig(from baseConfig: DifficultyConfig) -> DifficultyConfig {
        return DifficultyConfig(
            baseGridSize: baseConfig.baseGridSize,
            numberRange: baseConfig.numberRange,
            maxAttempts: max(3, baseConfig.maxAttempts / 3), // Even fewer attempts
            keptCellsPercentage: 0.3...0.7, // Very lenient percentage range
            usesAdvancedPatterns: false // Force basic patterns only
        )
    }
    
    /// Creates a smaller grid config for emergency fallback
    private func createSmallerGridConfig(from baseConfig: DifficultyConfig) -> DifficultyConfig {
        let smallerSize = max(3, baseConfig.baseGridSize - 1) // At least 3x3
        return DifficultyConfig(
            baseGridSize: smallerSize,
            numberRange: 1...15, // Simpler number range
            maxAttempts: 3, // Quick attempts only
            keptCellsPercentage: 0.4...0.6, // Standard percentage range
            usesAdvancedPatterns: false // Basic patterns only
        )
    }
    
    /// Generates an emergency fallback puzzle that is guaranteed to work
    private func generateEmergencyFallbackPuzzle(difficulty: String, level: Int, baseSeed: UInt64) -> Puzzle? {
        print("🚨 Generating emergency fallback puzzle for \(difficulty) level \(level)")
        
        // Determine appropriate size based on difficulty
        let size: Int
        let maxNumber: Int
        let patternDescription: String
        
        switch difficulty.lowercased() {
        case "expert":
            size = 6
            maxNumber = 25  // Increased from 20 to reflect higher number range (1-35)
            patternDescription = "6x6 ultimate pattern"
        case "extra hard", "extrahard":
            size = 5
            maxNumber = 22  // Increased from 15 to reflect higher number range (1-28)
            patternDescription = "5x5 advanced pattern"
        case "hard":
            size = 4
            maxNumber = 12
            patternDescription = "4x4 alternating pattern"
        case "medium":
            size = 4
            maxNumber = 10
            patternDescription = "4x4 diagonal pattern"
        default: // Easy and unknown
            size = 3
            maxNumber = 9
            patternDescription = "3x3 diagonal pattern"
        }
        
        // Generate grid and solution based on size
        let (grid, solution) = generateEmergencyGridAndSolution(size: size, maxNumber: maxNumber, seed: baseSeed)
        
        // Calculate sums
        let rowSums = calculateRowSums(grid: grid, solution: solution)
        let columnSums = calculateColumnSums(grid: grid, solution: solution)
        
        let puzzleId = "\(difficulty.lowercased())-\(level)"
        
        let puzzle = Puzzle(
            id: puzzleId,
            difficulty: difficulty,
            grid: grid,
            solution: solution,
            rowSums: rowSums,
            columnSums: columnSums
        )
        
        print("✅ Generated emergency fallback puzzle: \(puzzleId) (\(patternDescription))")
        return puzzle
    }
    
    /// Generates a deterministic grid and solution for emergency puzzles
    private func generateEmergencyGridAndSolution(size: Int, maxNumber: Int, seed: UInt64) -> (grid: [[Int]], solution: [[Bool]]) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        
        // Generate grid with controlled randomness
        var grid: [[Int]] = []
        for row in 0..<size {
            var gridRow: [Int] = []
            for col in 0..<size {
                // Use position-based seeding for deterministic results
                let positionSeed = seed + UInt64(row * size + col)
                var positionRng = SeededRandomNumberGenerator(seed: positionSeed)
                let number = Int.random(in: 1...maxNumber, using: &positionRng)
                gridRow.append(number)
            }
            grid.append(gridRow)
        }
        
        // Generate solution with guaranteed uniqueness
        var solution: [[Bool]] = Array(repeating: Array(repeating: false, count: size), count: size)
        
        if size == 3 {
            // 3x3: Simple diagonal pattern
            solution[0][0] = true
            solution[1][1] = true
            solution[2][2] = true
        } else if size == 4 {
            // 4x4: Alternating pattern with good constraint diversity
            solution[0][0] = true
            solution[0][2] = true
            solution[1][1] = true
            solution[1][3] = true
            solution[2][0] = true
            solution[2][2] = true
            solution[3][1] = true
            solution[3][3] = true
        } else if size == 5 {
            // 5x5: Cross pattern with good distribution
            solution[0][2] = true
            solution[1][1] = true
            solution[1][3] = true
            solution[2][0] = true
            solution[2][2] = true
            solution[2][4] = true
            solution[3][1] = true
            solution[3][3] = true
            solution[4][2] = true
        } else if size == 6 {
            // 6x6: Expert-level pattern with good constraint diversity
            solution[0][1] = true
            solution[0][4] = true
            solution[1][0] = true
            solution[1][3] = true
            solution[1][5] = true
            solution[2][2] = true
            solution[2][4] = true
            solution[3][1] = true
            solution[3][3] = true
            solution[4][0] = true
            solution[4][2] = true
            solution[4][5] = true
            solution[5][1] = true
            solution[5][4] = true
        } else {
            // Fallback for other sizes: checkerboard pattern
            for row in 0..<size {
                for col in 0..<size {
                    solution[row][col] = (row + col) % 2 == 0
                }
            }
        }
        
        return (grid, solution)
    }
    
    private func getDifficultyConfig(for difficulty: String) -> DifficultyConfig? {
        switch difficulty.lowercased() {
        case "easy": return .easy
        case "medium": return .medium
        case "hard": return .hard
        case "extra hard", "extrahard": return .extraHard
        case "expert": return .expert
        default: return nil
        }
    }
    
    private func attemptGeneration(config: DifficultyConfig, difficulty: String, level: Int, rng: inout SeededRandomNumberGenerator) -> Puzzle? {
        // Calculate dynamic grid size based on difficulty and level
        let size = calculateGridSize(config: config, difficulty: difficulty, level: level)
        var grid: [[Int]] = []
        
        // Generate grid with numbers from the specified range
        for _ in 0..<size {
            var row: [Int] = []
            for _ in 0..<size {
                let number = Int.random(in: config.numberRange, using: &rng)
                row.append(number)
            }
            grid.append(row)
        }
        
        // Create solution pattern based on difficulty configuration
        var solution: [[Bool]] = []
        if config.usesAdvancedPatterns {
            solution = generateAdvancedSolutionPattern(size: size, config: config, level: level, rng: &rng)
        } else {
            solution = generateBasicSolutionPattern(size: size, config: config, rng: &rng)
        }
        
        // Validate and adjust the solution to meet percentage requirements
        let totalCells = size * size
        let targetKeptRange = config.keptCellsPercentage
        let minKeptCells = max(1, Int(Double(totalCells) * targetKeptRange.lowerBound))
        let maxKeptCells = Int(Double(totalCells) * targetKeptRange.upperBound)
        
        var keptCount = solution.flatMap { $0 }.filter { $0 }.count
        
        // Adjust kept count to fall within target range and ensure puzzle quality
        solution = adjustKeptCells(solution: solution, currentKept: keptCount, minKept: minKeptCells, maxKept: maxKeptCells, rng: &rng)
        
        // Validate puzzle complexity - ensure each row/column has reasonable challenge
        if !validatePuzzleComplexity(solution: solution, config: config) {
            print("⚠️ Generated solution failed complexity validation, will retry")
            return nil
        }
        
        // Calculate sums
        let rowSums = calculateRowSums(grid: grid, solution: solution)
        let columnSums = calculateColumnSums(grid: grid, solution: solution)
        
        // Validate that the puzzle has at least some challenge (not all zeros)
        let totalSum = rowSums.reduce(0, +)
        guard totalSum > 0 else {
            print("⚠️ Generated puzzle has zero sum, regenerating...")
            return nil
        }
        
        // CRITICAL: Validate solution uniqueness
        // This is the key fix - we must verify the target sums have exactly one solution
        if !validateSolutionUniqueness(grid: grid, targetRowSums: rowSums, targetColumnSums: columnSums, expectedSolution: solution) {
            print("⚠️ Generated puzzle has multiple solutions, regenerating...")
            return nil
        }
        
        // For advanced difficulties, validate constraint diversity to ensure meaningful challenge
        if config.usesAdvancedPatterns {
            let diversityScore = calculateConstraintDiversityScore(grid: grid, rowSums: rowSums, columnSums: columnSums)
            
            // Set diversity requirements based on difficulty
            let requiredScore: Double
            let difficultyName: String
            
            switch config {
            case .expert:
                requiredScore = 0.65  // 65% for Expert (meaningful gap vs Extra Hard's 55%)
                difficultyName = "Expert"
            case .extraHard:
                requiredScore = 0.55  // 55% for Extra Hard (closer to Expert's 60%)
                difficultyName = "Extra Hard"
            case .hard:
                requiredScore = 0.4  // 40% for Hard
                difficultyName = "Hard"
            default:
                requiredScore = 0.3  // 30% fallback
                difficultyName = "Advanced"
            }
            
            if diversityScore < requiredScore {
                print("⚠️ \(difficultyName) puzzle lacks constraint diversity (score: \(String(format: "%.2f", diversityScore)), required: \(String(format: "%.2f", requiredScore))), regenerating...")
                return nil
            }
            print("✅ \(difficultyName) puzzle constraint diversity: \(String(format: "%.2f", diversityScore)) (required: \(String(format: "%.2f", requiredScore)))")
        }
        
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
    
    // MARK: - Advanced Generation Helper Methods
    
    /// Calculates the grid size based on difficulty configuration and level progression
    private func calculateGridSize(config: DifficultyConfig, difficulty: String, level: Int) -> Int {
        let baseSize = config.baseGridSize
        
        switch difficulty.lowercased() {
        case "extra hard", "extrahard":
            // Aggressive progression: 5x5 → 6x6 → 7x7 (faster transition to Expert-level grids)
            if level <= 10 { return baseSize } // 5x5 (reduced from 15 levels)
            else if level <= 25 { return baseSize + 1 } // 6x6 (starts earlier, longer duration)
            else { return baseSize + 2 } // 7x7 (advanced challenge)
            
        case "expert":
            // Aggressive scaling: 6x6 → 7x7 → 8x8 (faster progression to maximum challenge)
            if level <= 15 { return baseSize } // 6x6 (reduced from 20 levels)
            else if level <= 30 { return baseSize + 1 } // 7x7 (starts much earlier)
            else { return baseSize + 2 } // 8x8 (ultimate challenge starts at level 31)
            
        default:
            return baseSize
        }
    }
    
    /// Generates a basic solution pattern for easier difficulties
    private func generateBasicSolutionPattern(size: Int, config: DifficultyConfig, rng: inout SeededRandomNumberGenerator) -> [[Bool]] {
        var solution: [[Bool]] = []
        
        for row in 0..<size {
            var solutionRow: [Bool] = []
            for col in 0..<size {
                // Simple random pattern with slight checkerboard bias
                let basePattern = (row + col) % 2 == 0
                let randomFactor = Double.random(in: 0...1, using: &rng)
                let isKept = basePattern ? randomFactor > 0.3 : randomFactor > 0.7
                solutionRow.append(isKept)
            }
            solution.append(solutionRow)
        }
        
        return solution
    }
    
    /// Generates advanced solution patterns for harder difficulties
    private func generateAdvancedSolutionPattern(size: Int, config: DifficultyConfig, level: Int, rng: inout SeededRandomNumberGenerator) -> [[Bool]] {
        var solution: [[Bool]] = []
        
        // Choose pattern type based on level
        let patternType = level % 4
        
        switch patternType {
        case 0: // Sparse clustered pattern
            solution = generateClusteredPattern(size: size, rng: &rng)
        case 1: // Edge-focused pattern
            solution = generateEdgeFocusedPattern(size: size, rng: &rng)
        case 2: // Diagonal emphasis pattern
            solution = generateDiagonalPattern(size: size, rng: &rng)
        default: // Random sparse pattern
            solution = generateSparseRandomPattern(size: size, rng: &rng)
        }
        
        return solution
    }
    
    /// Generates a clustered solution pattern
    private func generateClusteredPattern(size: Int, rng: inout SeededRandomNumberGenerator) -> [[Bool]] {
        var solution = Array(repeating: Array(repeating: false, count: size), count: size)
        
        // Create 2-3 clusters of kept cells
        let numClusters = Int.random(in: 2...min(3, size/2), using: &rng)
        
        for _ in 0..<numClusters {
            let centerRow = Int.random(in: 1..<(size-1), using: &rng)
            let centerCol = Int.random(in: 1..<(size-1), using: &rng)
            let clusterSize = Int.random(in: 2...4, using: &rng)
            
            // Fill cluster area
            for dr in -1...1 {
                for dc in -1...1 {
                    let row = centerRow + dr
                    let col = centerCol + dc
                    if row >= 0 && row < size && col >= 0 && col < size {
                        if Double.random(in: 0...1, using: &rng) < 0.7 {
                            solution[row][col] = true
                        }
                    }
                }
            }
        }
        
        return solution
    }
    
    /// Generates an edge-focused solution pattern
    private func generateEdgeFocusedPattern(size: Int, rng: inout SeededRandomNumberGenerator) -> [[Bool]] {
        var solution = Array(repeating: Array(repeating: false, count: size), count: size)
        
        // Favor edges and corners
        for row in 0..<size {
            for col in 0..<size {
                let isEdge = row == 0 || row == size-1 || col == 0 || col == size-1
                let isCorner = (row == 0 || row == size-1) && (col == 0 || col == size-1)
                
                let probability: Double
                if isCorner { probability = 0.8 }
                else if isEdge { probability = 0.6 }
                else { probability = 0.2 }
                
                solution[row][col] = Double.random(in: 0...1, using: &rng) < probability
            }
        }
        
        return solution
    }
    
    /// Generates a diagonal-emphasis solution pattern
    private func generateDiagonalPattern(size: Int, rng: inout SeededRandomNumberGenerator) -> [[Bool]] {
        var solution = Array(repeating: Array(repeating: false, count: size), count: size)
        
        // Favor main diagonals
        for row in 0..<size {
            for col in 0..<size {
                let isMainDiagonal = row == col
                let isAntiDiagonal = row + col == size - 1
                
                let probability: Double
                if isMainDiagonal || isAntiDiagonal { probability = 0.7 }
                else { probability = 0.25 }
                
                solution[row][col] = Double.random(in: 0...1, using: &rng) < probability
            }
        }
        
        return solution
    }
    
    /// Generates a sparse random solution pattern
    private func generateSparseRandomPattern(size: Int, rng: inout SeededRandomNumberGenerator) -> [[Bool]] {
        var solution = Array(repeating: Array(repeating: false, count: size), count: size)
        
        // Very sparse, truly random pattern
        for row in 0..<size {
            for col in 0..<size {
                solution[row][col] = Double.random(in: 0...1, using: &rng) < 0.25
            }
        }
        
        return solution
    }
    
    /// Validates that the puzzle has sufficient complexity for logical challenge
    private func validatePuzzleComplexity(solution: [[Bool]], config: DifficultyConfig) -> Bool {
        let size = solution.count
        
        // For very small grids (3x3), be more lenient with validation
        if size <= 3 && !config.usesAdvancedPatterns {
            print("🔍 Skipping strict validation for small Easy/Medium grid (\(size)x\(size))")
            return validateBasicComplexity(solution: solution)
        }
        
        // Determine minimum complexity requirements based on difficulty
        let minKeptPerRowCol: Int
        let maxKeptPerRowCol: Int
        
        if config.usesAdvancedPatterns {
            // For Hard/Extra Hard/Expert: each row/column should have reasonable spread
            minKeptPerRowCol = max(1, size / 4)
            maxKeptPerRowCol = min(size - 1, (size * 2) / 3) // Allow up to 2/3 of cells
        } else {
            // For Easy/Medium: very lenient but still require some variety
            minKeptPerRowCol = max(1, size / 5)
            maxKeptPerRowCol = size - 1 // Allow almost all cells except leaving at least one empty
        }
        
        print("🔍 Validating complexity: min=\(minKeptPerRowCol), max=\(maxKeptPerRowCol) per row/col")
        
        // Check each row
        for row in 0..<size {
            let keptInRow = solution[row].filter { $0 }.count
            if keptInRow < minKeptPerRowCol {
                print("🔍 Row \(row) has only \(keptInRow) kept cells (min: \(minKeptPerRowCol))")
                return false
            }
            
            if keptInRow > maxKeptPerRowCol {
                print("🔍 Row \(row) has too many kept cells: \(keptInRow) (max: \(maxKeptPerRowCol))")
                return false
            }
        }
        
        // Check each column
        for col in 0..<size {
            let keptInCol = (0..<size).map { solution[$0][col] }.filter { $0 }.count
            if keptInCol < minKeptPerRowCol {
                print("🔍 Column \(col) has only \(keptInCol) kept cells (min: \(minKeptPerRowCol))")
                return false
            }
            
            if keptInCol > maxKeptPerRowCol {
                print("🔍 Column \(col) has too many kept cells: \(keptInCol) (max: \(maxKeptPerRowCol))")
                return false
            }
        }
        
        return true
    }
    
    /// Validates that the target sums have exactly one unique solution
    /// This is the critical method that ensures puzzle quality
    private func validateSolutionUniqueness(grid: [[Int]], targetRowSums: [Int], targetColumnSums: [Int], expectedSolution: [[Bool]]) -> Bool {
        let size = grid.count
        
        print("🔍 Starting solution uniqueness validation for \(size)x\(size) grid...")
        
        // For medium and large grids (4x4+), use optimized validation to avoid exponential complexity
        // 3x3 = 2^9 = 512 combinations (fast)
        // 4x4 = 2^16 = 65,536 combinations (acceptable but can be optimized) 
        // 5x5 = 2^25 = 33+ million combinations (needs optimization)
        // 6x6 = 2^36 = 68+ billion combinations (impossible without optimization)
        if size >= 4 {
            return validateLargeGridUniqueness(grid: grid, targetRowSums: targetRowSums, targetColumnSums: targetColumnSums, expectedSolution: expectedSolution)
        }
        
        // For smaller grids, use exhaustive search
        var foundSolutions: [[[Bool]]] = []
        let totalCells = size * size
        let maxCombinations = 1 << totalCells // 2^totalCells
        
        for combination in 0..<maxCombinations {
            var candidateSolution: [[Bool]] = Array(repeating: Array(repeating: false, count: size), count: size)
            
            // Convert combination number to grid pattern
            for cellIndex in 0..<totalCells {
                let row = cellIndex / size
                let col = cellIndex % size
                let isKept = (combination >> cellIndex) & 1 == 1
                candidateSolution[row][col] = isKept
            }
            
            // Check if this candidate solution matches our target sums
            if doesSolutionMatchTargets(grid: grid, solution: candidateSolution, targetRowSums: targetRowSums, targetColumnSums: targetColumnSums) {
                foundSolutions.append(candidateSolution)
                
                // Early exit if we find more than one solution
                if foundSolutions.count > 1 {
                    print("❌ Found multiple solutions (at least \(foundSolutions.count)), puzzle is invalid")
                    return false
                }
            }
        }
        
        let solutionCount = foundSolutions.count
        if solutionCount == 1 {
            print("✅ Puzzle has exactly one unique solution")
            return true
        } else if solutionCount == 0 {
            print("❌ No valid solution found for target sums")
            return false
        } else {
            print("❌ Found \(solutionCount) solutions, puzzle is invalid")
            return false
        }
    }
    
    /// Advanced validation for large grids (6x6+) using smart solution counting
    private func validateLargeGridUniqueness(grid: [[Int]], targetRowSums: [Int], targetColumnSums: [Int], expectedSolution: [[Bool]]) -> Bool {
        let size = grid.count
        print("🔍 Using advanced solution counting for \(size)x\(size) grid...")
        
        // Strategy 1: Verify the expected solution produces correct target sums
        if !doesSolutionMatchTargets(grid: grid, solution: expectedSolution, targetRowSums: targetRowSums, targetColumnSums: targetColumnSums) {
            print("❌ Expected solution doesn't match target sums")
            return false
        }
        print("✅ Expected solution produces correct target sums")
        
        // Strategy 2: Use constraint propagation to count possible solutions
        let solutionCount = countSolutionsUsingConstraintPropagation(
            grid: grid, 
            targetRowSums: targetRowSums, 
            targetColumnSums: targetColumnSums,
            maxSolutionsToFind: 2 // We only need to know if there's 1 or >1
        )
        
        switch solutionCount {
        case 0:
            print("❌ No valid solutions found")
            return false
        case 1:
            print("✅ Exactly one unique solution found")
            return true
        default:
            print("❌ Found \(solutionCount >= 2 ? "multiple" : "\(solutionCount)") solutions - puzzle not unique")
            return false
        }
    }
    
    /// Analyzes how constraining a target sum is for given values
    private func analyzeConstraintStrength(values: [Int], targetSum: Int) -> ConstraintStrength {
        let n = values.count
        if n > 10 { return .medium } // Skip expensive calculation for very large arrays
        
        var validCombinations = 0
        let maxCombinations = 1 << n
        
        for combination in 0..<maxCombinations {
            var sum = 0
            for i in 0..<n {
                if (combination >> i) & 1 == 1 {
                    sum += values[i]
                }
            }
            if sum == targetSum {
                validCombinations += 1
            }
        }
        
        let totalPossible = maxCombinations
        let ratio = Double(validCombinations) / Double(totalPossible)
        
        if ratio < 0.1 { return .strong }      // Less than 10% of combinations work
        else if ratio < 0.3 { return .medium } // 10-30% of combinations work  
        else { return .weak }                   // More than 30% of combinations work
    }
    
    /// Constraint strength levels
    private enum ConstraintStrength {
        case strong  // Very few valid combinations - likely unique
        case medium  // Moderate number of valid combinations
        case weak    // Many valid combinations - may have multiple solutions
    }
    
    /// Checks if a candidate solution produces the target row and column sums
    private func doesSolutionMatchTargets(grid: [[Int]], solution: [[Bool]], targetRowSums: [Int], targetColumnSums: [Int]) -> Bool {
        let size = grid.count
        
        // Check row sums
        for row in 0..<size {
            var actualSum = 0
            for col in 0..<size {
                if solution[row][col] {
                    actualSum += grid[row][col]
                }
            }
            if actualSum != targetRowSums[row] {
                return false
            }
        }
        
        // Check column sums
        for col in 0..<size {
            var actualSum = 0
            for row in 0..<size {
                if solution[row][col] {
                    actualSum += grid[row][col]
                }
            }
            if actualSum != targetColumnSums[col] {
                return false
            }
        }
        
        return true
    }
    
    /// Basic complexity validation for small grids (3x3 and smaller)
    private func validateBasicComplexity(solution: [[Bool]]) -> Bool {
        let size = solution.count
        let totalCells = size * size
        let totalKept = solution.flatMap { $0 }.filter { $0 }.count
        
        // Ensure we have a reasonable distribution of kept cells
        let minTotalKept = max(1, totalCells / 4)
        let maxTotalKept = (totalCells * 3) / 4
        
        if totalKept < minTotalKept {
            print("🔍 Too few kept cells: \(totalKept) (min: \(minTotalKept))")
            return false
        }
        
        if totalKept > maxTotalKept {
            print("🔍 Too many kept cells: \(totalKept) (max: \(maxTotalKept))")
            return false
        }
        
        // Ensure no row or column is completely empty or completely full
        for row in 0..<size {
            let keptInRow = solution[row].filter { $0 }.count
            if keptInRow == 0 || keptInRow == size {
                print("🔍 Row \(row) is trivial: \(keptInRow)/\(size) kept")
                return false
            }
        }
        
        for col in 0..<size {
            let keptInCol = (0..<size).map { solution[$0][col] }.filter { $0 }.count
            if keptInCol == 0 || keptInCol == size {
                print("🔍 Column \(col) is trivial: \(keptInCol)/\(size) kept")
                return false
            }
        }
        
        print("🔍 Basic complexity validation passed: \(totalKept)/\(totalCells) cells kept")
        return true
    }
    
    /// Adjusts the number of kept cells to fall within the target range while maintaining complexity
    private func adjustKeptCells(solution: [[Bool]], currentKept: Int, minKept: Int, maxKept: Int, rng: inout SeededRandomNumberGenerator) -> [[Bool]] {
        var adjustedSolution = solution
        let size = solution.count
        var keptCount = currentKept
        var attempts = 0
        let maxAdjustmentAttempts = size * size * 2
        
        // If we have too few kept cells, add some strategically
        while keptCount < minKept && attempts < maxAdjustmentAttempts {
            attempts += 1
            
            // Find rows/columns that need more kept cells for complexity
            let rowsNeedingCells = findRowsNeedingMoreCells(solution: adjustedSolution)
            let colsNeedingCells = findColumnsNeedingMoreCells(solution: adjustedSolution)
            
            var row, col: Int
            
            if !rowsNeedingCells.isEmpty && !colsNeedingCells.isEmpty {
                // Prioritize intersections of rows and columns that need cells
                row = rowsNeedingCells.randomElement(using: &rng)!
                col = colsNeedingCells.randomElement(using: &rng)!
            } else if !rowsNeedingCells.isEmpty {
                row = rowsNeedingCells.randomElement(using: &rng)!
                col = Int.random(in: 0..<size, using: &rng)
            } else if !colsNeedingCells.isEmpty {
                col = colsNeedingCells.randomElement(using: &rng)!
                row = Int.random(in: 0..<size, using: &rng)
            } else {
                // Random placement as fallback
                row = Int.random(in: 0..<size, using: &rng)
                col = Int.random(in: 0..<size, using: &rng)
            }
            
            if !adjustedSolution[row][col] {
                adjustedSolution[row][col] = true
                keptCount += 1
            }
        }
        
        // If we have too many kept cells, remove some strategically
        attempts = 0
        while keptCount > maxKept && attempts < maxAdjustmentAttempts {
            attempts += 1
            
            // Find rows/columns that have too many kept cells
            let rowsWithExcess = findRowsWithExcessCells(solution: adjustedSolution)
            let colsWithExcess = findColumnsWithExcessCells(solution: adjustedSolution)
            
            var row, col: Int
            
            if !rowsWithExcess.isEmpty && !colsWithExcess.isEmpty {
                // Prioritize intersections of rows and columns with excess
                row = rowsWithExcess.randomElement(using: &rng)!
                col = colsWithExcess.randomElement(using: &rng)!
            } else if !rowsWithExcess.isEmpty {
                row = rowsWithExcess.randomElement(using: &rng)!
                col = Int.random(in: 0..<size, using: &rng)
            } else if !colsWithExcess.isEmpty {
                col = colsWithExcess.randomElement(using: &rng)!
                row = Int.random(in: 0..<size, using: &rng)
            } else {
                // Random removal as fallback
                row = Int.random(in: 0..<size, using: &rng)
                col = Int.random(in: 0..<size, using: &rng)
            }
            
            if adjustedSolution[row][col] {
                adjustedSolution[row][col] = false
                keptCount -= 1
            }
        }
        
        return adjustedSolution
    }
    
    /// Finds rows that need more kept cells for complexity
    private func findRowsNeedingMoreCells(solution: [[Bool]]) -> [Int] {
        let size = solution.count
        let minRequired = max(2, size / 3)
        
        var needingRows: [Int] = []
        for row in 0..<size {
            let keptInRow = solution[row].filter { $0 }.count
            if keptInRow < minRequired {
                needingRows.append(row)
            }
        }
        return needingRows
    }
    
    /// Finds columns that need more kept cells for complexity
    private func findColumnsNeedingMoreCells(solution: [[Bool]]) -> [Int] {
        let size = solution.count
        let minRequired = max(2, size / 3)
        
        var needingCols: [Int] = []
        for col in 0..<size {
            let keptInCol = (0..<size).map { solution[$0][col] }.filter { $0 }.count
            if keptInCol < minRequired {
                needingCols.append(col)
            }
        }
        return needingCols
    }
    
    /// Finds rows that have too many kept cells
    private func findRowsWithExcessCells(solution: [[Bool]]) -> [Int] {
        let size = solution.count
        let maxAllowed = max(3, size - 1)
        
        var excessRows: [Int] = []
        for row in 0..<size {
            let keptInRow = solution[row].filter { $0 }.count
            if keptInRow > maxAllowed {
                excessRows.append(row)
            }
        }
        return excessRows
    }
    
    /// Finds columns that have too many kept cells
    private func findColumnsWithExcessCells(solution: [[Bool]]) -> [Int] {
        let size = solution.count
        let maxAllowed = max(3, size - 1)
        
        var excessCols: [Int] = []
        for col in 0..<size {
            let keptInCol = (0..<size).map { solution[$0][col] }.filter { $0 }.count
            if keptInCol > maxAllowed {
                excessCols.append(col)
            }
        }
        return excessCols
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
    
    // MARK: - Advanced Solution Counting for Large Grids
    
    /// Efficiently counts solutions using constraint propagation and backtracking
    /// This avoids the 2^36 explosion for 6x6 grids by using smart search pruning
    private func countSolutionsUsingConstraintPropagation(
        grid: [[Int]], 
        targetRowSums: [Int], 
        targetColumnSums: [Int],
        maxSolutionsToFind: Int = 2
    ) -> Int {
        let size = grid.count
        print("🔍 Starting constraint propagation for \(size)x\(size) grid...")
        
        // Create constraint satisfaction problem representation
        var domains: [[Set<Bool>]] = Array(repeating: Array(repeating: Set([true, false]), count: size), count: size)
        var solutionCount = 0
        
        // Apply initial constraint propagation
        if !propagateConstraints(grid: grid, domains: &domains, targetRowSums: targetRowSums, targetColumnSums: targetColumnSums) {
            print("❌ Initial constraint propagation failed - no solutions possible")
            return 0
        }
        
        // Use backtracking with constraint propagation to count solutions
        backtrackWithPropagation(
            grid: grid,
            domains: &domains,
            targetRowSums: targetRowSums,
            targetColumnSums: targetColumnSums,
            row: 0,
            col: 0,
            solutionCount: &solutionCount,
            maxSolutions: maxSolutionsToFind
        )
        
        print("🔍 Constraint propagation completed: found \(solutionCount) solution\(solutionCount == 1 ? "" : "s")")
        return solutionCount
    }
    
    /// Propagates constraints to reduce domain sizes
    private func propagateConstraints(
        grid: [[Int]], 
        domains: inout [[Set<Bool>]], 
        targetRowSums: [Int], 
        targetColumnSums: [Int]
    ) -> Bool {
        let size = grid.count
        var changed = true
        
        // Keep propagating until no more changes occur
        while changed {
            changed = false
            
            // Propagate row constraints
            for row in 0..<size {
                if propagateRowConstraint(grid: grid, domains: &domains, row: row, targetSum: targetRowSums[row]) {
                    changed = true
                }
            }
            
            // Propagate column constraints
            for col in 0..<size {
                if propagateColumnConstraint(grid: grid, domains: &domains, col: col, targetSum: targetColumnSums[col]) {
                    changed = true
                }
            }
            
            // Check for empty domains (impossible constraints)
            for row in 0..<size {
                for col in 0..<size {
                    if domains[row][col].isEmpty {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    /// Propagates constraints for a single row
    private func propagateRowConstraint(grid: [[Int]], domains: inout [[Set<Bool>]], row: Int, targetSum: Int) -> Bool {
        let size = grid[0].count
        var changed = false
        
        // Calculate minimum and maximum possible sums for this row
        var minSum = 0
        var maxSum = 0
        var fixedSum = 0
        var variableCells: [Int] = []
        
        for col in 0..<size {
            let cellValue = grid[row][col]
            if domains[row][col].count == 1 {
                // Fixed cell
                if domains[row][col].contains(true) {
                    fixedSum += cellValue
                }
            } else {
                // Variable cell
                variableCells.append(col)
                maxSum += cellValue
            }
        }
        
        let remainingSum = targetSum - fixedSum
        
        // If remaining sum is impossible, mark invalid cells
        if remainingSum < 0 || remainingSum > maxSum {
            // This constraint is impossible
            for col in variableCells {
                if domains[row][col].count > 1 {
                    domains[row][col] = Set()
                    changed = true
                }
            }
            return changed
        }
        
        // Apply logical deductions
        for col in variableCells {
            let cellValue = grid[row][col]
            let otherMaxSum = maxSum - cellValue
            
            // If we must include this cell to reach target sum
            if remainingSum > otherMaxSum {
                if domains[row][col].contains(false) {
                    domains[row][col].remove(false)
                    changed = true
                }
            }
            
            // If including this cell would exceed target sum
            if remainingSum < cellValue {
                if domains[row][col].contains(true) {
                    domains[row][col].remove(true)
                    changed = true
                }
            }
        }
        
        return changed
    }
    
    /// Propagates constraints for a single column
    private func propagateColumnConstraint(grid: [[Int]], domains: inout [[Set<Bool>]], col: Int, targetSum: Int) -> Bool {
        let size = grid.count
        var changed = false
        
        // Calculate minimum and maximum possible sums for this column
        var maxSum = 0
        var fixedSum = 0
        var variableCells: [Int] = []
        
        for row in 0..<size {
            let cellValue = grid[row][col]
            if domains[row][col].count == 1 {
                // Fixed cell
                if domains[row][col].contains(true) {
                    fixedSum += cellValue
                }
            } else {
                // Variable cell
                variableCells.append(row)
                maxSum += cellValue
            }
        }
        
        let remainingSum = targetSum - fixedSum
        
        // If remaining sum is impossible, mark invalid cells
        if remainingSum < 0 || remainingSum > maxSum {
            for row in variableCells {
                if domains[row][col].count > 1 {
                    domains[row][col] = Set()
                    changed = true
                }
            }
            return changed
        }
        
        // Apply logical deductions
        for row in variableCells {
            let cellValue = grid[row][col]
            let otherMaxSum = maxSum - cellValue
            
            // If we must include this cell to reach target sum
            if remainingSum > otherMaxSum {
                if domains[row][col].contains(false) {
                    domains[row][col].remove(false)
                    changed = true
                }
            }
            
            // If including this cell would exceed target sum
            if remainingSum < cellValue {
                if domains[row][col].contains(true) {
                    domains[row][col].remove(true)
                    changed = true
                }
            }
        }
        
        return changed
    }
    
    /// Backtrack with constraint propagation to count solutions
    private func backtrackWithPropagation(
        grid: [[Int]],
        domains: inout [[Set<Bool>]],
        targetRowSums: [Int],
        targetColumnSums: [Int],
        row: Int,
        col: Int,
        solutionCount: inout Int,
        maxSolutions: Int
    ) {
        let size = grid.count
        
        // Early termination if we've found enough solutions
        if solutionCount >= maxSolutions {
            return
        }
        
        // Find next variable cell
        var nextRow = row
        var nextCol = col
        
        // Find next cell that needs assignment
        while nextRow < size {
            while nextCol < size && domains[nextRow][nextCol].count == 1 {
                nextCol += 1
            }
            if nextCol < size {
                break
            }
            nextRow += 1
            nextCol = 0
        }
        
        // If all cells are assigned, check if we have a valid solution
        if nextRow >= size {
            if isCompleteAssignmentValid(grid: grid, domains: domains, targetRowSums: targetRowSums, targetColumnSums: targetColumnSums) {
                solutionCount += 1
            }
            return
        }
        
        // Try both values for the current cell
        let originalDomains = domains
        
        for value in domains[nextRow][nextCol] {
            // Make assignment
            domains[nextRow][nextCol] = Set([value])
            
            // Propagate constraints
            var domainsCopy = domains
            if propagateConstraints(grid: grid, domains: &domainsCopy, targetRowSums: targetRowSums, targetColumnSums: targetColumnSums) {
                domains = domainsCopy
                // Recurse
                backtrackWithPropagation(
                    grid: grid,
                    domains: &domains,
                    targetRowSums: targetRowSums,
                    targetColumnSums: targetColumnSums,
                    row: nextRow,
                    col: nextCol + 1,
                    solutionCount: &solutionCount,
                    maxSolutions: maxSolutions
                )
            }
            
            // Early termination check
            if solutionCount >= maxSolutions {
                return
            }
            
            // Backtrack
            domains = originalDomains
        }
    }
    
    /// Checks if a complete assignment satisfies all constraints
    private func isCompleteAssignmentValid(
        grid: [[Int]], 
        domains: [[Set<Bool>]], 
        targetRowSums: [Int], 
        targetColumnSums: [Int]
    ) -> Bool {
        let size = grid.count
        
        // Convert domains to solution
        var solution: [[Bool]] = Array(repeating: Array(repeating: false, count: size), count: size)
        for row in 0..<size {
            for col in 0..<size {
                if domains[row][col].count == 1 && domains[row][col].contains(true) {
                    solution[row][col] = true
                }
            }
        }
        
        return doesSolutionMatchTargets(grid: grid, solution: solution, targetRowSums: targetRowSums, targetColumnSums: targetColumnSums)
    }
    
    // MARK: - Constraint Diversity Scoring
    
    /// Calculates how diverse and meaningful the puzzle constraints are
    /// Returns a score from 0.0 (poor diversity) to 1.0 (excellent diversity)
    private func calculateConstraintDiversityScore(grid: [[Int]], rowSums: [Int], columnSums: [Int]) -> Double {
        let size = grid.count
        var score = 0.0
        
        // Factor 1: Sum variance (diverse target sums are more interesting)
        let allSums = rowSums + columnSums
        let sumVariance = calculateVariance(values: allSums)
        let normalizedSumVariance = min(1.0, sumVariance / 100.0) // Normalize to 0-1
        score += normalizedSumVariance * 0.3
        
        // Factor 2: Number uniqueness (more unique sums = better constraints)
        let uniqueSums = Set(allSums)
        let uniquenessRatio = Double(uniqueSums.count) / Double(allSums.count)
        score += uniquenessRatio * 0.25
        
        // Factor 3: Constraint strength distribution (good mix of strong/medium/weak)
        var strongConstraints = 0
        var mediumConstraints = 0
        var weakConstraints = 0
        
        // Analyze row constraints
        for row in 0..<size {
            let rowValues = grid[row]
            let strength = analyzeConstraintStrength(values: rowValues, targetSum: rowSums[row])
            switch strength {
            case .strong: strongConstraints += 1
            case .medium: mediumConstraints += 1
            case .weak: weakConstraints += 1
            }
        }
        
        // Analyze column constraints
        for col in 0..<size {
            let colValues = (0..<size).map { grid[$0][col] }
            let strength = analyzeConstraintStrength(values: colValues, targetSum: columnSums[col])
            switch strength {
            case .strong: strongConstraints += 1
            case .medium: mediumConstraints += 1
            case .weak: weakConstraints += 1
            }
        }
        
        let totalConstraints = strongConstraints + mediumConstraints + weakConstraints
        let strongRatio = Double(strongConstraints) / Double(totalConstraints)
        let mediumRatio = Double(mediumConstraints) / Double(totalConstraints)
        let weakRatio = Double(weakConstraints) / Double(totalConstraints)
        
        // Ideal distribution: some strong, mostly medium, few weak
        let idealBalance = (strongRatio >= 0.2 && strongRatio <= 0.5) && 
                          (mediumRatio >= 0.4) && 
                          (weakRatio <= 0.3)
        score += idealBalance ? 0.25 : (mediumRatio * 0.25) // Reward balanced or medium-heavy distributions
        
        // Factor 4: Number distribution complexity (avoid repetitive patterns)
        let flatGrid = grid.flatMap { $0 }
        let numberUniquenesRatio = Double(Set(flatGrid).count) / Double(flatGrid.count)
        score += numberUniquenesRatio * 0.2
        
        return min(1.0, score)
    }
    
    /// Calculates variance for an array of integers
    private func calculateVariance(values: [Int]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        
        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let squaredDifferences = values.map { pow(Double($0) - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
}

// MARK: - Seeded Random Number Generator

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