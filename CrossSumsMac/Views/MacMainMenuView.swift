import SwiftUI

struct MacMainMenuView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var selectedDifficulty: String = "Easy"
    @State private var isLoading: Bool = false
    @State private var showHelp: Bool = false
    @State private var navigateToGame: Bool = false
    
    private let difficulties = ["Easy", "Medium", "Hard", "Extra Hard"]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Title
                VStack(spacing: 15) {
                    Text("Cross Sums")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Add numbers to match target sums")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)
                
                // Main content in HStack for Mac layout
                HStack(spacing: 60) {
                    // Left side - Difficulty Selection
                    VStack(spacing: 25) {
                        Text("Select Difficulty")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ForEach(difficulties, id: \.self) { difficulty in
                                DifficultyButton(
                                    difficulty: difficulty,
                                    isSelected: selectedDifficulty == difficulty,
                                    highestLevel: gameViewModel.getHighestLevel(for: difficulty)
                                ) {
                                    selectedDifficulty = difficulty
                                }
                            }
                        }
                    }
                    .frame(width: 280)
                    
                    // Right side - Game info and controls
                    VStack(spacing: 25) {
                        // Level info
                        VStack(spacing: 10) {
                            Text("Next Level")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(gameViewModel.getNextLevel(for: selectedDifficulty))")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        // Hints info
                        VStack(spacing: 10) {
                            Text("Available Hints")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(gameViewModel.hintsAvailable)")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        // Action buttons
                        VStack(spacing: 15) {
                            Button(action: startGame) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Play")
                                        .fontWeight(.semibold)
                                }
                                .frame(width: 160, height: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                            }
                            .disabled(isLoading)
                            
                            Button(action: { showHelp = true }) {
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                    Text("Help")
                                }
                                .frame(width: 160, height: 40)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .frame(width: 200)
                }
                
                Spacer()
                
                // Footer
                Text("macOS Version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .padding(40)
        }
        .navigationDestination(isPresented: $navigateToGame) {
            MacGameView(gameViewModel: gameViewModel)
        }
        .sheet(isPresented: $showHelp) {
            MacHelpView()
        }
        .overlay {
            if isLoading {
                ProgressView("Loading puzzle...")
                    .padding(20)
                    .background(Color(.windowBackgroundColor).opacity(0.9))
                    .cornerRadius(10)
            }
        }
    }
    
    private func startGame() {
        isLoading = true
        let nextLevel = gameViewModel.getNextLevel(for: selectedDifficulty)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            gameViewModel.loadPuzzle(difficulty: selectedDifficulty, level: nextLevel)
            isLoading = false
            
            if gameViewModel.currentPuzzle != nil {
                navigateToGame = true
            }
        }
    }
}

struct DifficultyButton: View {
    let difficulty: String
    let isSelected: Bool
    let highestLevel: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Best: Level \(highestLevel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MacMainMenuView()
}