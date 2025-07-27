import SwiftUI

struct MainMenuView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var selectedDifficulty: String = "Easy"
    @State private var isLoading: Bool = false
    @State private var showHelp: Bool = false
    @State private var navigateToGame: Bool = false
    
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
                        .accessibilityIdentifier("appTitle")
                        .accessibilityLabel("Cross Sums")
                        .accessibilityHint("Main title of the puzzle game")
                    
                    Text("Add numbers to match target sums")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("gameDescription")
                        .accessibilityLabel("Add numbers to match target sums")
                        .accessibilityHint("Brief description of the game rules")
                }
                
                Spacer()
                
                // Difficulty Selection
                VStack(spacing: 20) {
                    Text("Select Difficulty")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .accessibilityIdentifier("difficultyLabel")
                        .accessibilityLabel("Select Difficulty")
                        .accessibilityHint("Choose the difficulty level for your puzzle")
                    
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(difficulties, id: \.self) { difficulty in
                            Text(difficulty)
                                .tag(difficulty)
                                .accessibilityLabel(difficulty)
                                .accessibilityHint("Select \(difficulty) difficulty level")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .accessibilityIdentifier("difficultyPicker")
                    .accessibilityLabel("Difficulty selector")
                    .accessibilityHint("Currently selected: \(selectedDifficulty). Double tap to change difficulty.")
                    
                    // Level info for selected difficulty
                    VStack(spacing: 5) {
                        let nextLevel = gameViewModel.getNextLevel(for: selectedDifficulty)
                        let highestLevel = gameViewModel.getHighestLevel(for: selectedDifficulty)
                        
                        Text("Next Level: \(nextLevel)")
                            .font(.body)
                            .foregroundColor(.primary)
                            .accessibilityIdentifier("nextLevelInfo")
                            .accessibilityLabel("Next Level: \(nextLevel)")
                            .accessibilityHint("The next level you will play for \(selectedDifficulty) difficulty")
                        
                        if highestLevel > 0 {
                            Text("Highest Completed: \(highestLevel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("highestLevelInfo")
                                .accessibilityLabel("Highest Completed: \(highestLevel)")
                                .accessibilityHint("The highest level you have completed for \(selectedDifficulty) difficulty")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(10)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("levelProgressInfo")
                    .accessibilityLabel("Level Progress: Next level \(gameViewModel.getNextLevel(for: selectedDifficulty))" + (gameViewModel.getHighestLevel(for: selectedDifficulty) > 0 ? ", highest completed \(gameViewModel.getHighestLevel(for: selectedDifficulty))" : ""))
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 15) {
                    // Play Button
                    Button(action: didTapPlay) {
                        HStack {
                            Image(systemName: "play.fill")
                                .accessibilityHidden(true)
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
                    .accessibilityIdentifier("playButton")
                    .accessibilityLabel("Play")
                    .accessibilityHint("Start playing the selected difficulty level")
                    
                    // Help Button
                    Button(action: didTapHelp) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .accessibilityHidden(true)
                            Text("How to Play")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .accessibilityIdentifier("helpButton")
                    .accessibilityLabel("How to Play")
                    .accessibilityHint("Learn the rules and instructions for playing Cross Sums")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Player Stats
                VStack(spacing: 5) {
                    Text("Hints Available: \(gameViewModel.hintsAvailable)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("hintsAvailable")
                        .accessibilityLabel("Hints Available: \(gameViewModel.hintsAvailable)")
                        .accessibilityHint("Number of hints you can use during gameplay")
                }
                .padding(.bottom)
            }
            .padding()
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                
                ProgressView("Loading puzzle...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .accessibilityIdentifier("loadingIndicator")
                    .accessibilityLabel("Loading puzzle")
                    .accessibilityHint("Please wait while the puzzle is being prepared")
            }
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .navigationDestination(isPresented: $navigateToGame) {
            GameView(gameViewModel: gameViewModel)
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
        print("🎮 MainMenuView: Play button tapped")
        print("🎮 Selected difficulty: \(selectedDifficulty)")
        
        let nextLevel = gameViewModel.getNextLevel(for: selectedDifficulty)
        print("🎮 Next level to load: \(nextLevel)")
        
        isLoading = true
        print("🎮 Setting loading state to true")
        
        // Load the puzzle for the selected difficulty and level
        print("🎮 Calling gameViewModel.loadPuzzle(\(selectedDifficulty), \(nextLevel))")
        gameViewModel.loadPuzzle(difficulty: selectedDifficulty, level: nextLevel)
        
        // Puzzle loading is now synchronous, so we can navigate immediately
        isLoading = false
        
        if let puzzle = gameViewModel.currentPuzzle {
            print("✅ Puzzle loaded successfully: \(puzzle.id)")
            print("🎮 Triggering navigation to game")
            navigateToGame = true
        } else {
            print("❌ Failed to load puzzle for \(selectedDifficulty) level \(nextLevel)")
            if let errorMessage = gameViewModel.errorMessage {
                print("❌ Error message: \(errorMessage)")
            }
            print("🎮 Navigation will not work - no puzzle loaded")
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