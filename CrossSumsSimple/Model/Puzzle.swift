import Foundation

/// US3: Represents a single, complete puzzle.
/// 
/// A puzzle consists of a grid of numbers where the player must mark cells as kept or removed
/// to match the target sums for each row and column. Each puzzle has a unique solution.
public struct Puzzle: Codable, Identifiable {
    /// Unique identifier for the puzzle (e.g., "hard-50")
    public let id: String
    
    /// Difficulty level of the puzzle (Easy, Medium, Hard, Extra Hard)
    public let difficulty: String
    
    /// 2D array of numbers representing the puzzle grid
    public let grid: [[Int]]
    
    /// The correct solution mask: true for kept cells, false for removed cells
    public let solution: [[Bool]]
    
    /// Target sums for each row
    public let rowSums: [Int]
    
    /// Target sums for each column
    public let columnSums: [Int]
    
    // MARK: - Computed Properties
    
    public var rowCount: Int {
        return grid.count
    }
    
    public var columnCount: Int {
        return grid.first?.count ?? 0
    }
    
    public var isValid: Bool {
        guard rowCount > 0 && columnCount > 0 else { return false }
        
        // Check that all rows have the same number of columns
        for row in grid {
            if row.count != columnCount {
                return false
            }
        }
        
        // Check that solution dimensions match grid dimensions
        guard solution.count == rowCount else { return false }
        for solutionRow in solution {
            if solutionRow.count != columnCount {
                return false
            }
        }
        
        // Check that row and column sums arrays have correct lengths
        return rowSums.count == rowCount && columnSums.count == columnCount
    }
    
    public var isEmpty: Bool {
        return rowCount == 0 || columnCount == 0
    }
    
    // MARK: - Methods
    
    public func isValidSolution(_ playerMask: [[Bool]]) -> Bool {
        guard playerMask.count == rowCount else { return false }
        
        for (rowIndex, row) in playerMask.enumerated() {
            guard row.count == columnCount else { return false }
            
            for (colIndex, cellState) in row.enumerated() {
                if cellState != solution[rowIndex][colIndex] {
                    return false
                }
            }
        }
        
        return true
    }
    
    public func calculateRowSum(for playerMask: [[Bool]], row: Int) -> Int? {
        guard row >= 0 && row < rowCount,
              playerMask.count > row,
              playerMask[row].count == columnCount else {
            return nil
        }
        
        var sum = 0
        for (colIndex, isKept) in playerMask[row].enumerated() {
            if isKept {
                sum += grid[row][colIndex]
            }
        }
        
        return sum
    }
    
    public func calculateColumnSum(for playerMask: [[Bool]], column: Int) -> Int? {
        guard column >= 0 && column < columnCount,
              playerMask.count == rowCount else {
            return nil
        }
        
        var sum = 0
        for (rowIndex, row) in playerMask.enumerated() {
            guard row.count > column else { return nil }
            
            if row[column] {
                sum += grid[rowIndex][column]
            }
        }
        
        return sum
    }
    
    public func number(at row: Int, column: Int) -> Int? {
        guard row >= 0 && row < rowCount,
              column >= 0 && column < columnCount else {
            return nil
        }
        
        return grid[row][column]
    }
    
    public func solutionState(at row: Int, column: Int) -> Bool? {
        guard row >= 0 && row < rowCount,
              column >= 0 && column < columnCount else {
            return nil
        }
        
        return solution[row][column]
    }
}