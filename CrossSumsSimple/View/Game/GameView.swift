import SwiftUI

struct GameView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showLevelComplete = false
    @State private var showGameOver = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                // HUD - Level info, lives, hints
                HUDView(gameViewModel: gameViewModel)
                    .padding(.horizontal)
                
                // Main game area
                ScrollView {
                    VStack(spacing: 12) {
                        // Grid - The main puzzle
                        GridView(gameViewModel: gameViewModel)
                            .frame(
                                width: min(geometry.size.width - 40, geometry.size.height * 0.6),
                                height: min(geometry.size.width - 40, geometry.size.height * 0.6)
                            )
                            .padding(.horizontal)
                        
                        // Controls instruction panel
                        ControlsInstructionView()
                            .padding(.horizontal)
                        
                        // Optional progress indicator
                        if gameViewModel.gameState != nil {
                            GameProgressView(gameViewModel: gameViewModel)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
                
                // Controls - Hint, Restart, Menu
                ControlsView(gameViewModel: gameViewModel)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            // Debug output when game view appears
            print("🎮 GameView appeared with puzzle: \(gameViewModel.currentPuzzle?.id ?? "none")")
            gameViewModel.debugPrintGameState()
        }
        .onChange(of: gameViewModel.isLevelComplete) { _, isComplete in
            if isComplete {
                showLevelComplete = true
            }
        }
        .onChange(of: gameViewModel.isGameOver) { _, isOver in
            if isOver {
                showGameOver = true
            }
        }
        .sheet(isPresented: $showLevelComplete) {
            LevelCompleteView(gameViewModel: gameViewModel, onDismiss: {
                // On dismiss, stay in game or navigate based on user choice
                showLevelComplete = false
            }, onNavigateToMainMenu: {
                // Navigate to main menu - same behavior as GameView's Menu button
                dismiss()
            })
        }
        .alert("Game Over", isPresented: $showGameOver) {
            Button("Restart Level") {
                gameViewModel.restartLevel()
                showGameOver = false
            }
            Button("Main Menu") {
                dismiss()
            }
        } message: {
            Text("You've run out of lives! Would you like to restart this level or return to the main menu?")
        }
        .alert("Error", isPresented: .constant(gameViewModel.errorMessage != nil)) {
            Button("OK") {
                gameViewModel.clearError()
            }
        } message: {
            if let errorMessage = gameViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Controls Instruction View

struct ControlsInstructionView: View {
    var body: some View {
        HStack(spacing: 20) {
            // Tap instruction
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14, weight: .medium))
                Text("Tap to keep")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            // Long press instruction
            HStack(spacing: 6) {
                Image(systemName: "hand.point.up.left.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 14, weight: .medium))
                Text("Hold to remove")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Drag instruction
            HStack(spacing: 6) {
                Image(systemName: "hand.draw.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .medium))
                Text("Drag to unmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Game View - Easy Puzzle") {
    let gameViewModel = GameViewModel()
    
    // Set up a sample puzzle for preview
    let puzzle = Puzzle(
        id: "preview-easy",
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
    
    gameViewModel.currentPuzzle = puzzle
    gameViewModel.gameState = GameState(for: puzzle)
    
    return NavigationStack {
        GameView(gameViewModel: gameViewModel)
    }
}

#Preview("Game View - Medium Puzzle") {
    let gameViewModel = GameViewModel()
    
    // Set up a medium puzzle for preview
    let puzzle = Puzzle(
        id: "preview-medium",
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
    
    gameViewModel.currentPuzzle = puzzle
    gameViewModel.gameState = GameState(for: puzzle)
    
    return NavigationStack {
        GameView(gameViewModel: gameViewModel)
    }
}

#Preview("Game View - Partially Solved") {
    let gameViewModel = GameViewModel()
    
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
    
    gameViewModel.currentPuzzle = puzzle
    
    var gameState = GameState(for: puzzle)
    // Make some correct moves
    _ = gameState.setCellState(row: 0, column: 0, state: true)  // Keep 5 ✓
    _ = gameState.setCellState(row: 0, column: 1, state: false) // Remove 3 ✓
    _ = gameState.setCellState(row: 1, column: 1, state: true)  // Keep 7 ✓
    _ = gameState.setCellState(row: 2, column: 0, state: true)  // Keep 9 ✓
    gameViewModel.gameState = gameState
    
    return NavigationStack {
        GameView(gameViewModel: gameViewModel)
    }
}