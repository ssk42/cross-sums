import SwiftUI

struct LevelCompleteView: View {
    @ObservedObject var gameViewModel: GameViewModel
    let onDismiss: () -> Void
    let onNavigateToMainMenu: () -> Void
    
    @State private var showCelebration = false
    @State private var confettiCount = 0
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss
    
    private let shareService = ShareResultsService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.1),
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Celebration particles
                if showCelebration {
                    ForEach(0..<confettiCount, id: \.self) { _ in
                        ConfettiView()
                    }
                }
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.green)
                            .scaleEffect(showCelebration ? 1.2 : 1.0)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showCelebration)
                    
                    // Success Message
                    VStack(spacing: 12) {
                        Text("Level Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let puzzle = gameViewModel.currentPuzzle {
                            Text("\(puzzle.difficulty) - Level \(gameViewModel.currentLevel)")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Achievement text
                        Text(achievementText)
                            .font(.body)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Stats Section
                    if let gameState = gameViewModel.gameState {
                        VStack(spacing: 16) {
                            Text("Level Stats")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 30) {
                                StatItem(
                                    icon: "timer",
                                    title: "Time",
                                    value: formatTime(gameState.elapsedTime),
                                    color: .blue
                                )
                                
                                StatItem(
                                    icon: "arrow.turn.up.right",
                                    title: "Moves",
                                    value: "\(gameState.moveCount)",
                                    color: .orange
                                )
                                
                                StatItem(
                                    icon: "heart.fill",
                                    title: "Lives Left",
                                    value: "\(gameState.livesRemaining)",
                                    color: .red
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Share Button
                        Button(action: didTapShare) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Result")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .accessibilityIdentifier("shareButton")
                        .accessibilityLabel("Share Result")
                        .accessibilityHint("Share your puzzle completion on social media")
                        
                        // Next Level Button
                        Button(action: didTapNextLevel) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text(nextLevelButtonText)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!hasNextLevel)
                        
                        // Stay Here Button
                        Button(action: didTapStayHere) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Stay Here")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // Main Menu Button
                        Button(action: didTapMainMenu) {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("Main Menu")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("Success!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        didTapMainMenu()
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareContent = generateShareContent() {
                ShareSheet(activityItems: [shareContent.text, shareContent.image].compactMap { $0 })
            }
        }
        .onAppear {
            // Start celebration animation
            withAnimation(.easeInOut(duration: 0.8)) {
                showCelebration = true
                confettiCount = 20
            }
            
            // Remove confetti after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 1.0)) {
                    confettiCount = 0
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var achievementText: String {
        if let gameState = gameViewModel.gameState {
            if gameState.livesRemaining == 3 {
                return "Perfect! No mistakes made! 🏆"
            } else if gameState.livesRemaining >= 2 {
                return "Great job! Excellent solving! ⭐"
            } else {
                return "Well done! You completed the level! 🎉"
            }
        }
        return "Congratulations! 🎉"
    }
    
    private var hasNextLevel: Bool {
        guard let puzzle = gameViewModel.currentPuzzle else { return false }
        let currentLevel = gameViewModel.currentLevel
        let maxLevel = gameViewModel.getAvailableDifficulties().contains(puzzle.difficulty) ? 
            PuzzleService.shared.getMaxLevel(for: puzzle.difficulty) : 0
        return currentLevel < maxLevel
    }
    
    private var nextLevelButtonText: String {
        if hasNextLevel {
            return "Next Level"
        } else {
            return "All Levels Complete!"
        }
    }
    
    // MARK: - Actions
    
    private func didTapNextLevel() {
        guard hasNextLevel,
              let puzzle = gameViewModel.currentPuzzle else {
            return
        }
        
        let nextLevel = gameViewModel.currentLevel + 1
        gameViewModel.loadPuzzle(difficulty: puzzle.difficulty, level: nextLevel)
        
        onDismiss()
        dismiss()
    }
    
    private func didTapStayHere() {
        onDismiss()
        dismiss()
    }
    
    private func didTapMainMenu() {
        onDismiss()
        dismiss()
        onNavigateToMainMenu()
    }
    
    private func didTapShare() {
        showShareSheet = true
    }
    
    private func generateShareContent() -> ShareContent? {
        guard let puzzle = gameViewModel.currentPuzzle,
              let gameState = gameViewModel.gameState else {
            return nil
        }
        
        let completionTime = gameState.elapsedTime
        let movesUsed = gameState.moveCount
        let livesLeft = gameState.livesRemaining
        let isDaily = gameViewModel.isCurrentPuzzleDaily
        
        var streak: Int? = nil
        if isDaily {
            streak = gameViewModel.playerProfile.calculateDailyStreak()
        }
        
        return shareService.generateShareContent(
            puzzle: puzzle,
            completionTime: completionTime,
            movesUsed: movesUsed,
            livesLeft: livesLeft,
            isDaily: isDaily,
            streak: streak
        )
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Stat Item Component

struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Confetti Animation Component

struct ConfettiView: View {
    @State private var offsetY: CGFloat = -100
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    private let randomColor: Color
    private let randomDelay: Double
    private let randomDuration: Double
    private let randomXOffset: CGFloat
    
    init() {
        randomColor = colors.randomElement() ?? .blue
        randomDelay = Double.random(in: 0...2)
        randomDuration = Double.random(in: 2...4)
        randomXOffset = CGFloat.random(in: -200...200)
    }
    
    var body: some View {
        Circle()
            .fill(randomColor)
            .frame(width: 8, height: 8)
            .offset(x: offsetX, y: offsetY)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeOut(duration: randomDuration)
                    .delay(randomDelay)
                ) {
                    offsetY = 800
                    offsetX = randomXOffset
                    rotation = Double.random(in: 0...720)
                    scale = 0.1
                }
            }
    }
}

// MARK: - Previews

#Preview("Level Complete") {
    let gameViewModel = GameViewModel()
    
    // Set up completed state
    let puzzle = Puzzle(
        id: "preview-complete",
        difficulty: "Medium",
        grid: [[5, 3], [2, 7]],
        solution: [[true, false], [false, true]],
        rowSums: [5, 7],
        columnSums: [2, 3]
    )
    
    gameViewModel.currentPuzzle = puzzle
    var gameState = GameState(for: puzzle)
    gameState.moveCount = 12
    gameViewModel.gameState = gameState
    
    return LevelCompleteView(gameViewModel: gameViewModel, onDismiss: {
        print("Level complete dismissed")
    }, onNavigateToMainMenu: {
        print("Navigate to main menu")
    })
}

#Preview("Perfect Score") {
    let gameViewModel = GameViewModel()
    
    let puzzle = Puzzle(
        id: "preview-perfect",
        difficulty: "Easy",
        grid: [[1, 2], [3, 4]],
        solution: [[true, false], [false, true]],
        rowSums: [1, 4],
        columnSums: [3, 2]
    )
    
    gameViewModel.currentPuzzle = puzzle
    var gameState = GameState(for: puzzle)
    gameState.moveCount = 4
    // Keep all 3 lives for perfect score
    gameViewModel.gameState = gameState
    
    return LevelCompleteView(gameViewModel: gameViewModel, onDismiss: {
        print("Perfect level complete dismissed")
    }, onNavigateToMainMenu: {
        print("Navigate to main menu from perfect")
    })
}