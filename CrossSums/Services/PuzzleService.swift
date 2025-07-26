import Foundation

/// Service responsible for loading and managing puzzle data
/// 
/// Loads puzzles from JSON files, provides caching for performance,
/// and validates puzzle integrity to ensure a good game experience.
class PuzzleService {
    
    // MARK: - Constants
    
    private static let puzzleFileName = "puzzles.json"
    
    // MARK: - Properties
    
    private var puzzleCache: [String: [Puzzle]] = [:]
    private var isLoaded = false
    
    // MARK: - Singleton
    
    static let shared = PuzzleService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Gets a specific puzzle by difficulty and level
    /// - Parameters:
    ///   - difficulty: The difficulty level (e.g., "Easy", "Medium", "Hard", "Extra Hard")
    ///   - level: The level number within that difficulty
    /// - Returns: The requested Puzzle, or nil if not found
    func getPuzzle(difficulty: String, level: Int) -> Puzzle? {
        // Ensure puzzles are loaded
        loadPuzzlesIfNeeded()
        
        // Get puzzles for the difficulty
        guard let puzzlesForDifficulty = puzzleCache[difficulty] else {
            print("❌ No puzzles found for difficulty: \(difficulty)")
            return nil
        }
        
        // Find puzzle with matching level
        let puzzle = puzzlesForDifficulty.first { $0.id.contains("-\(level)") }
        
        if puzzle == nil {
            print("❌ Puzzle not found for \(difficulty) level \(level)")
        }
        
        return puzzle
    }
    
    /// Gets all puzzles for a specific difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Array of puzzles for that difficulty, or empty array if none found
    func getPuzzles(for difficulty: String) -> [Puzzle] {
        loadPuzzlesIfNeeded()
        return puzzleCache[difficulty] ?? []
    }
    
    /// Gets all available difficulties
    /// - Returns: Array of difficulty strings
    func getAvailableDifficulties() -> [String] {
        loadPuzzlesIfNeeded()
        return Array(puzzleCache.keys).sorted()
    }
    
    /// Gets the number of levels available for a difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: Number of levels available
    func getLevelCount(for difficulty: String) -> Int {
        loadPuzzlesIfNeeded()
        return puzzleCache[difficulty]?.count ?? 0
    }
    
    /// Gets the highest available level for a difficulty
    /// - Parameter difficulty: The difficulty level
    /// - Returns: The highest level number, or 0 if no puzzles
    func getMaxLevel(for difficulty: String) -> Int {
        let puzzles = getPuzzles(for: difficulty)
        
        let maxLevel = puzzles.compactMap { puzzle in
            // Extract level number from ID (format: "difficulty-level")
            let components = puzzle.id.split(separator: "-")
            return components.last.flatMap { Int($0) }
        }.max()
        
        return maxLevel ?? 0
    }
    
    /// Validates that all puzzles have correct solutions
    /// - Returns: Dictionary mapping puzzle IDs to validation results
    func validateAllPuzzles() -> [String: Bool] {
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
    func clearCache() {
        puzzleCache.removeAll()
        isLoaded = false
        print("🗑️ Puzzle cache cleared")
    }
    
    // MARK: - Private Methods
    
    /// Loads puzzles from JSON file if not already loaded
    private func loadPuzzlesIfNeeded() {
        guard !isLoaded else { return }
        loadAllPuzzles()
    }
    
    /// Loads all puzzles from the JSON file
    private func loadAllPuzzles() {
        guard let url = Bundle.main.url(forResource: Self.puzzleFileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Failed to load puzzle file: \(Self.puzzleFileName)")
            return
        }
        
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
    func debugPrintPuzzles() {
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
    func getMemoryUsage() -> Int {
        let puzzleCount = puzzleCache.values.map { $0.count }.reduce(0, +)
        return puzzleCount * 1024 // Rough estimate
    }
}

// MARK: - Supporting Types

/// Root structure for puzzle JSON data
private struct PuzzleData: Codable {
    let puzzles: [Puzzle]
}