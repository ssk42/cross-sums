import SwiftUI

struct MacGameView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLevelComplete = false
    @State private var showingHelp = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top HUD
                MacHUDView(gameViewModel: gameViewModel)
                
                // Main game area
                HStack(spacing: 40) {
                    // Left side - Grid
                    VStack {
                        if let puzzle = gameViewModel.currentPuzzle {
                            MacGridView(
                                puzzle: puzzle,
                                gameState: gameViewModel.gameState,
                                currentRowSums: gameViewModel.currentRowSums,
                                currentColumnSums: gameViewModel.currentColumnSums,
                                onCellTap: { row, col in
                                    gameViewModel.toggleCell(row: row, column: col)
                                }
                            )
                        }
                    }
                    
                    // Right side - Controls
                    VStack(spacing: 20) {
                        MacControlsView(gameViewModel: gameViewModel)
                        
                        Spacer()
                        
                        // Additional Mac-specific info
                        VStack(spacing: 10) {
                            Text("Keyboard Shortcuts")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("H - Hint")
                                Text("R - Restart")
                                Text("⌘Q - Quit")
                                Text("⌘, - Settings")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .frame(width: 200)
                }
                
                Spacer()
            }
            .padding(30)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back to Menu") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Help") {
                    showingHelp = true
                }
            }
        }
        .onKeyPress(.init("h")) {
            gameViewModel.useHint()
            return .handled
        }
        .onKeyPress(.init("r")) {
            gameViewModel.restartLevel()
            return .handled
        }
        .sheet(isPresented: $showingHelp) {
            MacHelpView()
        }
        .sheet(isPresented: $showingLevelComplete) {
            MacLevelCompleteView(gameViewModel: gameViewModel) {
                showingLevelComplete = false
            }
        }
        .onChange(of: gameViewModel.isLevelComplete) { _, isComplete in
            if isComplete {
                showingLevelComplete = true
            }
        }
        .onChange(of: gameViewModel.isGameOver) { _, isGameOver in
            if isGameOver {
                // Handle game over state
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }
}

struct MacHUDView: View {
    @ObservedObject var gameViewModel: GameViewModel
    
    var body: some View {
        HStack {
            // Level info
            VStack(alignment: .leading) {
                Text("Level \(gameViewModel.currentLevel)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(gameViewModel.currentDifficulty)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Lives
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(gameViewModel.livesRemaining)")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Hints
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("\(gameViewModel.hintsAvailable)")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Progress indicator
            VStack(alignment: .trailing) {
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                let completionPercentage = gameViewModel.gameState?.completionPercentage ?? 0
                ProgressView(value: completionPercentage)
                    .frame(width: 100)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color(.windowBackgroundColor).opacity(0.8))
        .cornerRadius(12)
    }
}

struct MacGridView: View {
    let puzzle: Puzzle
    let gameState: GameState?
    let currentRowSums: [Int]
    let currentColumnSums: [Int]
    let onCellTap: (Int, Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Column sums header
            HStack(spacing: 8) {
                // Empty corner
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 50, height: 30)
                
                ForEach(0..<puzzle.columnCount, id: \.self) { col in
                    VStack(spacing: 2) {
                        Text("\(puzzle.columnSums[col])")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Text("\(currentColumnSums.count > col ? currentColumnSums[col] : 0)")
                            .font(.caption)
                            .foregroundColor(
                                currentColumnSums.count > col && currentColumnSums[col] == puzzle.columnSums[col] 
                                ? .green : .primary
                            )
                    }
                    .frame(width: 50, height: 30)
                }
            }
            
            // Grid with row sums
            ForEach(0..<puzzle.rowCount, id: \.self) { row in
                HStack(spacing: 8) {
                    // Row sum
                    HStack(spacing: 4) {
                        Text("\(puzzle.rowSums[row])")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Text("\(currentRowSums.count > row ? currentRowSums[row] : 0)")
                            .font(.caption)
                            .foregroundColor(
                                currentRowSums.count > row && currentRowSums[row] == puzzle.rowSums[row] 
                                ? .green : .primary
                            )
                    }
                    .frame(width: 50, height: 50)
                    
                    // Grid cells
                    ForEach(0..<puzzle.columnCount, id: \.self) { col in
                        MacPuzzleCellView(
                            value: puzzle.grid[row][col],
                            state: gameState?.getCellState(row: row, column: col) ?? nil,
                            onTap: { onCellTap(row, col) }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.windowBackgroundColor).opacity(0.8))
        .cornerRadius(15)
    }
}

struct MacPuzzleCellView: View {
    let value: Int
    let state: Bool?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(foregroundColor)
                .frame(width: 50, height: 50)
                .background(backgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        switch state {
        case .some(true): return Color.green.opacity(0.3)
        case .some(false): return Color.red.opacity(0.3)
        case nil: return Color.gray.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        switch state {
        case .some(false): return Color.secondary
        default: return Color.primary
        }
    }
    
    private var borderColor: Color {
        switch state {
        case .some(true): return Color.green
        case .some(false): return Color.red
        case nil: return Color.gray
        }
    }
}

struct MacControlsView: View {
    @ObservedObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Hint button
            Button(action: { gameViewModel.useHint() }) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("Use Hint")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(gameViewModel.canUseHint ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(gameViewModel.canUseHint ? .primary : .secondary)
                .cornerRadius(8)
            }
            .disabled(!gameViewModel.canUseHint)
            .buttonStyle(PlainButtonStyle())
            
            // Restart button
            Button(action: { gameViewModel.restartLevel() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Restart")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct MacLevelCompleteView: View {
    @ObservedObject var gameViewModel: GameViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎉 Level Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Level \(gameViewModel.currentLevel)")
                .font(.title2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 40) {
                Button("Next Level") {
                    gameViewModel.loadNextLevel()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Back to Menu") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

struct MacHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How to Play Cross Sums")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("🎯 Goal")
                    .font(.headline)
                
                Text("Mark cells as 'kept' or 'removed' so that the sum of kept numbers in each row and column matches the target sums.")
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("🎮 Controls")
                    .font(.headline)
                
                Text("• Click a cell to cycle: unmarked → kept → removed → unmarked")
                Text("• Green cells are kept and count toward sums")
                Text("• Red cells are removed and don't count")
                Text("• Use hints when stuck")
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("⌨️ Keyboard Shortcuts")
                    .font(.headline)
                
                Text("• H - Use hint")
                Text("• R - Restart level")
                Text("• ⌘Q - Quit game")
            }
            
            Spacer()
        }
        .padding(40)
        .frame(width: 500, height: 400)
    }
}

#Preview {
    let gameViewModel = GameViewModel()
    return MacGameView(gameViewModel: gameViewModel)
}