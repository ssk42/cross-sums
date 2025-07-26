import SwiftUI

struct MainMenuView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var selectedDifficulty: String = "Easy"
    @State private var isLoading: Bool = false
    @State private var showHelp: Bool = false
    @State private var showGame: Bool = false
    
    private let difficulties = ["Easy", "Medium", "Hard", "Extra Hard"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Title
                    VStack(spacing: 10) {
                        Text("Cross Sums")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Add numbers to match target sums")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Difficulty Selection
                    VStack(spacing: 20) {
                        Text("Select Difficulty")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(difficulties, id: \.self) { difficulty in
                                Text(difficulty).tag(difficulty)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Level info for selected difficulty
                        VStack(spacing: 5) {
                            let nextLevel = gameViewModel.getNextLevel(for: selectedDifficulty)
                            let highestLevel = gameViewModel.getHighestLevel(for: selectedDifficulty)
                            
                            Text("Next Level: \(nextLevel)")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            if highestLevel > 0 {
                                Text("Highest Completed: \(highestLevel)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        // Play Button
                        Button(action: didTapPlay) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        
                        // Help Button
                        Button(action: didTapHelp) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("How to Play")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Player Stats
                    VStack(spacing: 5) {
                        Text("Hints Available: \(gameViewModel.hintsAvailable)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                }
                .padding()
                
                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Loading puzzle...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                }
            }
        }
        .navigationDestination(isPresented: $showGame) {
            GameView(gameViewModel: gameViewModel)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .onAppear {
            // Load player profile when view appears
            // GameViewModel automatically loads profile in init
        }
        .onChange(of: selectedDifficulty) { _, newValue in
            didChangeDifficulty(to: newValue)
        }
    }
    
    // MARK: - Actions
    
    private func didTapPlay() {
        let nextLevel = gameViewModel.getNextLevel(for: selectedDifficulty)
        
        isLoading = true
        
        // Load the puzzle for the selected difficulty and level
        gameViewModel.loadPuzzle(difficulty: selectedDifficulty, level: nextLevel)
        
        // Wait a moment for the puzzle to load, then navigate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            
            if gameViewModel.currentPuzzle != nil {
                showGame = true
            } else {
                // Handle error - puzzle couldn't be loaded
                print("Failed to load puzzle for \(selectedDifficulty) level \(nextLevel)")
            }
        }
    }
    
    private func didTapHelp() {
        showHelp = true
    }
    
    private func didChangeDifficulty(to difficulty: String) {
        // Update UI to reflect new difficulty selection
        // Level info will automatically update due to @StateObject binding
    }
}

#Preview {
    MainMenuView()
}