import SwiftUI

struct GridView: View {
    @ObservedObject var gameViewModel: GameViewModel
    
    private let spacing: CGFloat = 4
    private let sumLabelWidth: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            if let puzzle = gameViewModel.currentPuzzle,
               let gameState = gameViewModel.gameState {
                
                let availableWidth = geometry.size.width - sumLabelWidth - spacing
                let cellSize = min(
                    (availableWidth - spacing * CGFloat(puzzle.columnCount - 1)) / CGFloat(puzzle.columnCount),
                    (geometry.size.height - sumLabelWidth - spacing * CGFloat(puzzle.rowCount)) / CGFloat(puzzle.rowCount + 1)
                )
                
                VStack(spacing: spacing) {
                    // Column sums header
                    HStack(spacing: spacing) {
                        // Empty space for row sum column
                        Spacer()
                            .frame(width: sumLabelWidth, height: sumLabelWidth)
                        
                        // Column sum labels
                        ForEach(0..<puzzle.columnCount, id: \.self) { col in
                            SumLabel(
                                target: puzzle.columnSums[col],
                                current: calculateCurrentColumnSum(puzzle: puzzle, gameState: gameState, column: col),
                                size: cellSize
                            )
                        }
                    }
                    
                    // Grid rows with row sums
                    ForEach(0..<puzzle.rowCount, id: \.self) { row in
                        HStack(spacing: spacing) {
                            // Row sum label
                            SumLabel(
                                target: puzzle.rowSums[row],
                                current: calculateCurrentRowSum(puzzle: puzzle, gameState: gameState, row: row),
                                size: cellSize
                            )
                            
                            // Row cells
                            ForEach(0..<puzzle.columnCount, id: \.self) { col in
                                PuzzleCellView(
                                    number: puzzle.grid[row][col],
                                    cellState: gameState.getCellState(row: row, column: col)
                                ) {
                                    gameViewModel.toggleCell(row: row, column: col)
                                }
                                .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading puzzle...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateCurrentRowSum(puzzle: Puzzle, gameState: GameState, row: Int) -> Int {
        var sum = 0
        for col in 0..<puzzle.columnCount {
            if let cellState = gameState.getCellState(row: row, column: col),
               let state = cellState,
               state == true { // Only count cells marked as "kept"
                sum += puzzle.grid[row][col]
            }
        }
        return sum
    }
    
    private func calculateCurrentColumnSum(puzzle: Puzzle, gameState: GameState, column: Int) -> Int {
        var sum = 0
        for row in 0..<puzzle.rowCount {
            if let cellState = gameState.getCellState(row: row, column: column),
               let state = cellState,
               state == true { // Only count cells marked as "kept"
                sum += puzzle.grid[row][column]
            }
        }
        return sum
    }
}

// MARK: - Sum Label Component

struct SumLabel: View {
    let target: Int
    let current: Int
    let size: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .stroke(borderColor, lineWidth: 1.5)
            
            VStack(spacing: 2) {
                Text("\(current)")
                    .font(.system(size: fontSize * 0.7, weight: .semibold, design: .rounded))
                    .foregroundColor(currentColor)
                
                Rectangle()
                    .fill(Color.primary.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 4)
                
                Text("\(target)")
                    .font(.system(size: fontSize * 0.6, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.2), value: current)
    }
    
    private var backgroundColor: Color {
        if current == target && current > 0 {
            return Color.green.opacity(0.1)
        } else if current > target {
            return Color.red.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var borderColor: Color {
        if current == target && current > 0 {
            return Color.green
        } else if current > target {
            return Color.red
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var currentColor: Color {
        if current == target && current > 0 {
            return Color.green
        } else if current > target {
            return Color.red
        } else {
            return Color.primary
        }
    }
    
    private var fontSize: CGFloat {
        return min(size * 0.25, 16)
    }
}

// MARK: - Previews

#Preview("Small Grid") {
    // Create a simple 3x3 puzzle for preview
    let puzzle = Puzzle(
        id: "preview-3x3",
        difficulty: "Easy",
        grid: [
            [5, 3, 8],
            [2, 7, 1],
            [9, 4, 6]
        ],
        solution: [
            [true, false, true],
            [false, true, false],
            [true, false, true]
        ],
        rowSums: [13, 7, 15],
        columnSums: [14, 7, 14]
    )
    
    let gameViewModel = GameViewModel()
    gameViewModel.currentPuzzle = puzzle
    gameViewModel.gameState = GameState(for: puzzle)
    
    return GridView(gameViewModel: gameViewModel)
        .padding()
        .frame(width: 300, height: 300)
}

#Preview("Medium Grid") {
    // Create a 4x4 puzzle for preview
    let puzzle = Puzzle(
        id: "preview-4x4",
        difficulty: "Medium",
        grid: [
            [12, 5, 8, 15],
            [7, 20, 3, 11],
            [14, 9, 18, 6],
            [4, 13, 10, 22]
        ],
        solution: [
            [true, false, true, false],
            [false, true, false, true],
            [true, false, false, true],
            [false, true, true, false]
        ],
        rowSums: [20, 31, 20, 23],
        columnSums: [12, 33, 18, 17]
    )
    
    let gameViewModel = GameViewModel()
    gameViewModel.currentPuzzle = puzzle
    gameViewModel.gameState = GameState(for: puzzle)
    
    return GridView(gameViewModel: gameViewModel)
        .padding()
        .frame(width: 400, height: 400)
}

#Preview("Partially Solved") {
    // Create a puzzle with some moves made
    let puzzle = Puzzle(
        id: "preview-partial",
        difficulty: "Easy",
        grid: [
            [5, 3, 8],
            [2, 7, 1],
            [9, 4, 6]
        ],
        solution: [
            [true, false, true],
            [false, true, false],
            [true, false, true]
        ],
        rowSums: [13, 7, 15],
        columnSums: [14, 7, 14]
    )
    
    let gameViewModel = GameViewModel()
    gameViewModel.currentPuzzle = puzzle
    
    var gameState = GameState(for: puzzle)
    // Make some moves
    _ = gameState.setCellState(row: 0, column: 0, state: true)  // Keep 5
    _ = gameState.setCellState(row: 0, column: 1, state: false) // Remove 3
    _ = gameState.setCellState(row: 1, column: 1, state: true)  // Keep 7
    gameViewModel.gameState = gameState
    
    return GridView(gameViewModel: gameViewModel)
        .padding()
        .frame(width: 300, height: 300)
}