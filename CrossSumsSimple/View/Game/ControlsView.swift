import SwiftUI

struct ControlsView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showRestartConfirmation = false
    @State private var showMainMenuConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Main Menu Button
            ControlButton(
                icon: "house.fill",
                title: "Menu",
                subtitle: "Exit game",
                color: .gray,
                isEnabled: true
            ) {
                showMainMenuConfirmation = true
            }
            .accessibilityIdentifier("mainMenuButton")
            .accessibilityLabel("Main Menu")
            .accessibilityHint("Return to the main menu. Current progress will be lost.")
            
            // Hint Button
            ControlButton(
                icon: "lightbulb.fill",
                title: "Hint",
                subtitle: hintSubtitle,
                color: .orange,
                isEnabled: canUseHint
            ) {
                gameViewModel.useHint()
            }
            .accessibilityIdentifier("hintButton")
            .accessibilityLabel("Hint")
            .accessibilityHint(canUseHint ? "Use a hint to reveal a correct cell" : "No hints available")
            
            // Restart Button
            ControlButton(
                icon: "arrow.clockwise",
                title: "Restart",
                subtitle: "Reset level",
                color: .blue,
                isEnabled: gameViewModel.isGameActive
            ) {
                showRestartConfirmation = true
            }
            .accessibilityIdentifier("restartButton")
            .accessibilityLabel("Restart")
            .accessibilityHint(gameViewModel.isGameActive ? "Restart the current level. All progress will be lost." : "Cannot restart - game is not active")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .confirmationDialog(
            "Restart Level",
            isPresented: $showRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restart", role: .destructive) {
                gameViewModel.restartLevel()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to restart this level? Your current progress will be lost.")
        }
        .confirmationDialog(
            "Return to Main Menu",
            isPresented: $showMainMenuConfirmation,
            titleVisibility: .visible
        ) {
            Button("Exit to Menu", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to return to the main menu? Your current progress will be lost.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var canUseHint: Bool {
        return gameViewModel.canUseHint && gameViewModel.isGameActive
    }
    
    private var hintSubtitle: String {
        if !gameViewModel.isGameActive {
            return "Game over"
        } else if gameViewModel.hintsAvailable == 0 {
            return "None left"
        } else if !gameViewModel.canUseHint {
            return "Not available"
        } else {
            return "Reveal cell"
        }
    }
}

// MARK: - Control Button Component

struct ControlButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            if isEnabled {
                withAnimation(.easeInOut(duration: 0.1)) {
                    action()
                }
            }
        }) {
            VStack(spacing: 6) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                // Title
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)
                
                // Subtitle
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(subtitleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .stroke(borderColor, lineWidth: isEnabled ? 1.5 : 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if isEnabled {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEnabled)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if isEnabled {
            return color.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var borderColor: Color {
        if isEnabled {
            return color.opacity(0.3)
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var iconColor: Color {
        if isEnabled {
            return color
        } else {
            return Color(.systemGray3)
        }
    }
    
    private var textColor: Color {
        if isEnabled {
            return .primary
        } else {
            return Color(.systemGray3)
        }
    }
    
    private var subtitleColor: Color {
        if isEnabled {
            return .secondary
        } else {
            return Color(.systemGray4)
        }
    }
}

// MARK: - Quick Actions View (Optional Enhancement)

struct QuickActionsView: View {
    @ObservedObject var gameViewModel: GameViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Undo last move (if implemented)
            QuickActionButton(
                icon: "arrow.uturn.backward",
                color: .purple,
                isEnabled: false // Placeholder for future undo functionality
            ) {
                // TODO: Implement undo functionality
            }
            
            // Show/hide solution preview (for development/testing)
            QuickActionButton(
                icon: "eye.fill",
                color: .indigo,
                isEnabled: true
            ) {
                // TODO: Implement solution preview
                gameViewModel.debugPrintGameState()
            }
            
            // Auto-solve one step (for testing)
            QuickActionButton(
                icon: "wand.and.stars",
                color: .pink,
                isEnabled: gameViewModel.isGameActive
            ) {
                // Use hint as auto-solve for now
                gameViewModel.useHint()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct QuickActionButton: View {
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isEnabled ? color : Color(.systemGray3))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isEnabled ? color.opacity(0.1) : Color(.systemGray6))
                        .stroke(isEnabled ? color.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
                )
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Previews

#Preview("Controls View") {
    let gameViewModel = GameViewModel()
    
    // Set up a mock state for preview
    let puzzle = Puzzle(
        id: "preview-controls",
        difficulty: "Easy",
        grid: [[1, 2], [3, 4]],
        solution: [[true, false], [false, true]],
        rowSums: [1, 4],
        columnSums: [3, 2]
    )
    
    gameViewModel.currentPuzzle = puzzle
    gameViewModel.gameState = GameState(for: puzzle)
    
    return VStack(spacing: 20) {
        ControlsView(gameViewModel: gameViewModel)
            .padding()
        
        QuickActionsView(gameViewModel: gameViewModel)
            .padding()
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
}

#Preview("Button States") {
    VStack(spacing: 20) {
        Text("Control Button States")
            .font(.headline)
            .padding()
        
        HStack(spacing: 16) {
            ControlButton(
                icon: "lightbulb.fill",
                title: "Hint",
                subtitle: "Reveal cell",
                color: .orange,
                isEnabled: true
            ) {
                print("Hint tapped")
            }
            
            ControlButton(
                icon: "lightbulb.fill",
                title: "Hint",
                subtitle: "None left",
                color: .orange,
                isEnabled: false
            ) {
                print("Disabled hint tapped")
            }
            
            ControlButton(
                icon: "arrow.clockwise",
                title: "Restart",
                subtitle: "Reset level",
                color: .blue,
                isEnabled: true
            ) {
                print("Restart tapped")
            }
        }
        .padding()
        
        Spacer()
    }
}