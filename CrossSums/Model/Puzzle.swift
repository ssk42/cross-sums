import Foundation

/// US3: Represents a single, complete puzzle.
/// 
/// A puzzle consists of a grid of numbers where the player must mark cells as kept or removed
/// to match the target sums for each row and column. Each puzzle has a unique solution.
struct Puzzle: Codable, Identifiable {
    /// Unique identifier for the puzzle (e.g., "hard-50")
    let id: String
    
    /// Difficulty level of the puzzle (Easy, Medium, Hard, Extra Hard)
    let difficulty: String
    
    /// 2D array of numbers representing the puzzle grid
    let grid: [[Int]]
    
    /// The correct solution mask: true for kept cells, false for removed cells
    let solution: [[Bool]]
    
    /// Target sums for each row
    let rowSums: [Int]
    
    /// Target sums for each column
    let columnSums: [Int]
    
    // MARK: - Computed Properties
    
    /// The number of rows in the puzzle grid
    var rowCount: Int {
        return grid.count
    }
    
    /// The number of columns in the puzzle grid
    var columnCount: Int {
        return grid.first?.count ?? 0
    }
    
    /// Returns true if the puzzle has valid dimensions
    var isValid: Bool {
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
    
    /// Returns true if the puzzle grid is empty
    var isEmpty: Bool {
        return rowCount == 0 || columnCount == 0
    }
    
    // MARK: - Methods
    
    /// Validates if a given player mask matches the puzzle solution
    /// - Parameter playerMask: 2D boolean array representing player's current selections
    /// - Returns: true if the player mask matches the solution exactly
    func isValidSolution(_ playerMask: [[Bool]]) -> Bool {
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
    
    /// Calculates the current row sum for a given player mask
    /// - Parameters:
    ///   - playerMask: 2D boolean array representing player's current selections
    ///   - row: The row index to calculate
    /// - Returns: The sum of kept numbers in the specified row, or nil if invalid
    func calculateRowSum(for playerMask: [[Bool]], row: Int) -> Int? {
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
    
    /// Calculates the current column sum for a given player mask
    /// - Parameters:
    ///   - playerMask: 2D boolean array representing player's current selections
    ///   - column: The column index to calculate
    /// - Returns: The sum of kept numbers in the specified column, or nil if invalid
    func calculateColumnSum(for playerMask: [[Bool]], column: Int) -> Int? {
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
    
    /// Gets the number at a specific grid position
    /// - Parameters:
    ///   - row: Row index
    ///   - column: Column index
    /// - Returns: The number at the specified position, or nil if out of bounds
    func number(at row: Int, column: Int) -> Int? {
        guard row >= 0 && row < rowCount,
              column >= 0 && column < columnCount else {
            return nil
        }
        
        return grid[row][column]
    }
    
    /// Gets the solution state for a specific cell
    /// - Parameters:
    ///   - row: Row index
    ///   - column: Column index
    /// - Returns: true if the cell should be kept in the solution, false if removed, nil if out of bounds
    func solutionState(at row: Int, column: Int) -> Bool? {
        guard row >= 0 && row < rowCount,
              column >= 0 && column < columnCount else {
            return nil
        }
        
        return solution[row][column]
    }
}