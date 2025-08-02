import SwiftUI

struct MainMenuView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @StateObject private var dailyPuzzleService = DailyPuzzleService.shared
    @State private var selectedDifficulty: String = "Easy"
    @State private var isLoading: Bool = false
    @State private var showHelp: Bool = false
    @State private var navigateToGame: Bool = false
    @State private var navigateToDailyPuzzle: Bool = false
    @State private var showDailyShareSheet: Bool = false
    
    private let difficulties = ["Easy", "Medium", "Hard", "Extra Hard", "Expert"]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: geometry.size.height * 0.008) {
                Spacer().frame(maxHeight: geometry.size.height * 0.005)
                
                // Title
                VStack(spacing: 6) {
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
                
                Spacer().frame(maxHeight: geometry.size.height * 0.005)
                
                // Daily Puzzle Section
                DailyPuzzleCardView(
                    dailyPuzzleService: dailyPuzzleService,
                    onTap: {
                        didTapDailyPuzzle()
                    },
                    onShare: dailyPuzzleService.isTodayCompleted() ? {
                        didTapShareDailyPuzzle()
                    } : nil
                )
                .accessibilityIdentifier("dailyPuzzleCard")
                
                Spacer().frame(maxHeight: geometry.size.height * 0.005)
                
                // Difficulty Selection
                VStack(spacing: 12) {
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
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .accessibilityIdentifier("difficultyPicker")
                    .accessibilityLabel("Difficulty selector")
                    .accessibilityHint("Currently selected: \(selectedDifficulty). Double tap to change difficulty.")
                    
                    // Level info for selected difficulty
                    VStack(spacing: 3) {
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
                
                Spacer().frame(maxHeight: geometry.size.height * 0.005)
                
                // Action Buttons
                VStack(spacing: 10) {
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
                .padding(.horizontal, geometry.size.width * 0.1)
                
                // Game Center Section
                if gameCenterManager.isAuthenticated {
                    VStack(spacing: 6) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(.green)
                                .accessibilityHidden(true)
                            Text("Game Center")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .accessibilityIdentifier("gameCenterTitle")
                        .accessibilityLabel("Game Center")
                        .accessibilityHint("Access Game Center features")
                        
                        HStack(spacing: 15) {
                            // Leaderboards Button
                            Button(action: {
                                gameViewModel.showLeaderboards()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "list.number")
                                        .font(.title2)
                                        .accessibilityHidden(true)
                                    Text("Leaderboards")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                            }
                            .accessibilityIdentifier("leaderboardsButton")
                            .accessibilityLabel("Leaderboards")
                            .accessibilityHint("View completion time and level rankings")
                            
                            // Achievements Button
                            Button(action: {
                                gameViewModel.showAchievements()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.title2)
                                        .accessibilityHidden(true)
                                    Text("Achievements")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                            }
                            .accessibilityIdentifier("achievementsButton")
                            .accessibilityLabel("Achievements")
                            .accessibilityHint("View your achievement progress")
                            
                            // Game Center Dashboard Button
                            Button(action: {
                                gameViewModel.showGameCenter()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .accessibilityHidden(true)
                                    Text("Dashboard")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                            }
                            .accessibilityIdentifier("gameCenterDashboardButton")
                            .accessibilityLabel("Game Center Dashboard")
                            .accessibilityHint("Open full Game Center interface")
                        }
                        .padding(.horizontal, geometry.size.width * 0.1)
                    }
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal, geometry.size.width * 0.05)
                }
                
                Spacer().frame(maxHeight: geometry.size.height * 0.005)
                
                // Player Stats
                VStack(spacing: 3) {
                    Text("Hints Available: \(gameViewModel.hintsAvailable)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("hintsAvailable")
                        .accessibilityLabel("Hints Available: \(gameViewModel.hintsAvailable)")
                        .accessibilityHint("Number of hints you can use during gameplay")
                    
                    if gameCenterManager.isAuthenticated, let player = gameCenterManager.localPlayer {
                        Text("Welcome, \(player.displayName)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .accessibilityIdentifier("gameCenterPlayer")
                            .accessibilityLabel("Game Center player: \(player.displayName)")
                            .accessibilityHint("You are signed in to Game Center")
                    }
                }
                .padding(.bottom)
            }
            .frame(minHeight: geometry.size.height)
            .padding(geometry.size.width * 0.05)
                }
            }
            
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
        .sheet(isPresented: $showDailyShareSheet) {
            if let shareContent = generateDailyPuzzleShareContent() {
                ShareSheet(activityItems: [shareContent.text, shareContent.image].compactMap { $0 })
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            GameView(gameViewModel: gameViewModel)
        }
        .navigationDestination(isPresented: $navigateToDailyPuzzle) {
            GameView(gameViewModel: gameViewModel)
        }
        .onAppear {
            // Load player profile when view appears
            // GameViewModel automatically loads profile in init
            
            // Initialize Game Center authentication
            gameCenterManager.authenticatePlayer()
            
            // Refresh daily puzzle state
            dailyPuzzleService.refreshDailyState()
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
    
    private func didTapDailyPuzzle() {
        print("🗓️ MainMenuView: Daily puzzle button tapped")
        
        isLoading = true
        
        // Load today's daily puzzle
        let dailyPuzzle = dailyPuzzleService.getTodaysPuzzle()
        print("🗓️ Loading daily puzzle: \(dailyPuzzle.id)")
        
        // Validate puzzle integrity before proceeding
        guard dailyPuzzle.isValid else {
            print("❌ Daily puzzle failed validation: \(dailyPuzzle.id)")
            isLoading = false
            return
        }
        
        // Set up the puzzle and game state
        gameViewModel.currentPuzzle = dailyPuzzle
        gameViewModel.gameState = GameState(for: dailyPuzzle)
        gameViewModel.isLevelComplete = false
        gameViewModel.isGameOver = false
        
        // CRITICAL: Initialize all derived state that GridView depends on
        gameViewModel.updateHintAvailability()
        gameViewModel.updateCurrentSums()
        
        isLoading = false
        
        print("✅ Daily puzzle loaded successfully: \(dailyPuzzle.id)")
        print("🗓️ Current sums initialized - rows: \(gameViewModel.currentRowSums.count), columns: \(gameViewModel.currentColumnSums.count)")
        print("🗓️ Triggering navigation to daily puzzle")
        navigateToDailyPuzzle = true
    }
    
    private func didTapShareDailyPuzzle() {
        showDailyShareSheet = true
    }
    
    private func generateDailyPuzzleShareContent() -> ShareContent? {
        guard dailyPuzzleService.isTodayCompleted(),
              let completionData = dailyPuzzleService.getTodayCompletionData() else {
            return nil
        }
        
        // Create a mock daily puzzle for share content generation
        let dailyPuzzle = dailyPuzzleService.getTodaysPuzzle()
        let currentStreak = dailyPuzzleService.getCurrentStreak()
        
        // Use actual performance data from when the player completed the puzzle
        return ShareResultsService.shared.generateShareContent(
            puzzle: dailyPuzzle,
            completionTime: completionData.timeInSeconds,
            movesUsed: completionData.movesUsed,
            livesLeft: completionData.livesLeft,
            isDaily: true,
            streak: currentStreak > 0 ? currentStreak : nil
        )
    }
}

#Preview {
    MainMenuView()
}