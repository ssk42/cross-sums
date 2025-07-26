import SwiftUI

struct HUDView: View {
    @ObservedObject var gameViewModel: GameViewModel
    
    var body: some View {
        HStack {
            // Level Info
            HUDItem(
                icon: "gamecontroller.fill",
                title: "Level",
                value: "\(gameViewModel.currentLevel)",
                subtitle: gameViewModel.currentDifficulty,
                color: .blue
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Level \(gameViewModel.currentLevel)")
            .accessibilityValue("\(gameViewModel.currentDifficulty) difficulty")
            .accessibilityHint("Current level and difficulty")
            
            Spacer()
            
            // Lives Remaining
            HUDItem(
                icon: livesIcon,
                title: "Lives",
                value: "\(gameViewModel.livesRemaining)",
                subtitle: livesSubtitle,
                color: livesColor
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Lives remaining: \(gameViewModel.livesRemaining)")
            .accessibilityValue(livesSubtitle)
            .accessibilityHint("Number of incorrect moves you can make before game over")
            
            Spacer()
            
            // Hints Available
            HUDItem(
                icon: "lightbulb.fill",
                title: "Hints",
                value: "\(gameViewModel.hintsAvailable)",
                subtitle: hintsSubtitle,
                color: .orange
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Hints available: \(gameViewModel.hintsAvailable)")
            .accessibilityValue(hintsSubtitle)
            .accessibilityHint("Number of hints you can use to reveal correct answers")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var livesIcon: String {
        switch gameViewModel.livesRemaining {
        case 3:
            return "heart.fill"
        case 2:
            return "heart.fill"
        case 1:
            return "heart.fill"
        default:
            return "heart.slash.fill"
        }
    }
    
    private var livesColor: Color {
        switch gameViewModel.livesRemaining {
        case 3:
            return .green
        case 2:
            return .yellow
        case 1:
            return .red
        default:
            return .gray
        }
    }
    
    private var livesSubtitle: String {
        switch gameViewModel.livesRemaining {
        case 3:
            return "Great!"
        case 2:
            return "Good"
        case 1:
            return "Careful!"
        default:
            return "Game Over"
        }
    }
    
    private var hintsSubtitle: String {
        if gameViewModel.hintsAvailable == 0 {
            return "None left"
        } else if gameViewModel.hintsAvailable == 1 {
            return "Last one!"
        } else {
            return "Available"
        }
    }
}

// MARK: - HUD Item Component

struct HUDItem: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon and value
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            // Title
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            // Subtitle
            Text(subtitle)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: value)
        .animation(.easeInOut(duration: 0.3), value: subtitle)
    }
}

// MARK: - Game Progress View (Optional Enhancement)

struct GameProgressView: View {
    @ObservedObject var gameViewModel: GameViewModel
    
    var body: some View {
        if let gameState = gameViewModel.gameState {
            VStack(spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(gameState.completionPercentage * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                }
                
                ProgressView(value: gameState.completionPercentage)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(y: 0.8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - Previews

#Preview("HUD View") {
    let gameViewModel = GameViewModel()
    
    // Set up a mock state for preview
    let puzzle = Puzzle(
        id: "preview-hud",
        difficulty: "Medium",
        grid: [[1, 2], [3, 4]],
        solution: [[true, false], [false, true]],
        rowSums: [1, 4],
        columnSums: [3, 2]
    )
    
    gameViewModel.currentPuzzle = puzzle
    gameViewModel.gameState = GameState(for: puzzle)
    
    return VStack(spacing: 20) {
        HUDView(gameViewModel: gameViewModel)
            .padding()
        
        GameProgressView(gameViewModel: gameViewModel)
            .padding()
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
}

#Preview("Different States") {
    VStack(spacing: 20) {
        // Full lives
        HUDItem(
            icon: "heart.fill",
            title: "Lives",
            value: "3",
            subtitle: "Great!",
            color: .green
        )
        
        // Low lives
        HUDItem(
            icon: "heart.fill",
            title: "Lives",
            value: "1",
            subtitle: "Careful!",
            color: .red
        )
        
        // No hints
        HUDItem(
            icon: "lightbulb.fill",
            title: "Hints",
            value: "0",
            subtitle: "None left",
            color: .orange
        )
        
        // Level info
        HUDItem(
            icon: "gamecontroller.fill",
            title: "Level",
            value: "12",
            subtitle: "Hard",
            color: .blue
        )
    }
    .padding()
}