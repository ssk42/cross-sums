# Cross Sums - Spec-Driven Architecture (iOS)

This document serves as the formal specification for the "Cross Sums" iOS application. It is the single source of truth for all features, components, and data models, intended to guide development.

---

## 1. Product Requirements & Overview

Cross Sums is a logic-based number puzzle game for iOS. The player is presented with a grid of numbers. The objective is to mark numbers in each row and column so that the sum of the remaining ("kept") numbers matches the target sums provided for that row and column. Each puzzle has a unique solution.

---

## 2. User Stories

As a user, I want to...

* **US1:** ...be able to choose a difficulty level (e.g., Easy, Medium, Hard, Extra Hard) so I can play a puzzle that matches my skill.
* **US2:** ...start a new game or continue from the last level I played for a chosen difficulty.
* **US3:** ...see a grid of numbers with target sums for each row and column.
* **US4:** ...tap on numbers in the grid to mark them for either keeping or removing, so I can solve the puzzle.
* **US5:** ...clearly distinguish between numbers I've marked for removal and those I'm keeping.
* **US6:** ...have a limited number of lives, which decrease if I make a mistake (e.g., removing a number that is part of the solution).
* **US7:** ...use a "hint" to reveal a correct number if I get stuck.
* **US8:** ...be notified with a clear "Level Complete" message when I solve the puzzle correctly.
* **US9:** ...have my progress (highest level completed per difficulty) saved automatically so I can pick up where I left off.
* **US10:** ...be able to restart the current puzzle at any time.

---

## 3. Data Models

These are the core data structures for the application.

```swift
import Foundation

/// US3: Represents a single, complete puzzle.
struct Puzzle: Codable, Identifiable {
    let id: String // e.g., "hard-50"
    let difficulty: String
    let grid: [[Int]]
    let solution: [[Bool]] // The correct mask: true for kept, false for removed
    let rowSums: [Int]
    let columnSums: [Int]
}

/// US9: Holds the player's persistent data.
struct PlayerProfile: Codable {
    var highestLevelCompleted: [String: Int] // Key: difficulty, Value: level
    var totalHints: Int
    var soundEnabled: Bool
}

/// Represents the player's active state within a single puzzle. This is ephemeral and not saved.
struct GameState {
    var playerGridMask: [[Bool]] // The player's current selections
    var livesRemaining: Int
}
4. Screens & Components (MVVM)The application will be built using the MVVM (Model-View-ViewModel) architecture with SwiftUI.4.1. MainMenuViewPurpose: The entry point of the game. Allows the user to select a difficulty and start playing. (US1, US2)State:isLoading: Bool - True while player profile is being loaded.selectedDifficulty: String - The difficulty currently highlighted by the slider.levelToPlay: Int - The level number displayed on the "Play" button.Actions:onAppear(): Triggers loading of the PlayerProfile.didChangeDifficulty(to: String): Updates the selectedDifficulty and fetches the corresponding levelToPlay.didTapPlay(): Navigates to the GameView with the selected puzzle.didTapHelp(): Shows a "How to Play" modal.4.2. GameViewPurpose: The main screen for gameplay, composing the grid, HUD, and controls. (US3, US4, US5, US6, US7, US10)ViewModel: GameViewModelState (managed by ViewModel):puzzle: Puzzle - The current puzzle being played.gameState: GameState - The player's current progress in the puzzle.isLevelComplete: Bool - True when the puzzle is solved correctly.isGameOver: Bool - True when the player runs out of lives.Components:HUDView: Displays the current level, lives remaining, and hint count.GridView: Renders the interactive grid of PuzzleCellViews.ControlsView: Contains buttons for "Restart" and "Hint".Actions (handled by ViewModel):toggleCell(row: Int, col: Int): Updates the playerGridMask and checks for mistakes.useHint(): Reveals a correct cell from the solution.restartLevel(): Resets the gameState to its initial state.checkForWinCondition(): Called after every move to check if the puzzle is solved.4.3. LevelCompleteViewPurpose: A modal view shown upon successful completion of a level. (US8)State:difficulty: String - The difficulty of the completed level.levelNumber: Int - The number of the completed level.Actions:didTapNextLevel(): Dismisses the modal and signals the GameViewModel to load the next puzzle.didTapMainMenu(): Dismisses the modal and navigates back to the MainMenuView.5. ServicesServices handle discrete logic and are injected into ViewModels.5.1. PersistenceServicePurpose: Handles saving and loading the PlayerProfile. (US9)Functions:// Saves the profile to device storage (e.g., UserDefaults or a file).
func saveProfile(_ profile: PlayerProfile)

// Loads the profile from device storage. Returns a default profile if none exists.
func loadProfile() -> PlayerProfile
5.2. PuzzleServicePurpose: Responsible for providing Puzzle objects to the game.Functions:// Fetches a specific puzzle from the local puzzle data (e.g., a JSON file).
func getPuzzle(difficulty: String, level: Int) -> Puzzle?
6. Project Structure (Xcode)CrossSums/
├── CrossSumsApp.swift      // Main app entry point
|
├── Model/
│   ├── Puzzle.swift
│   ├── PlayerProfile.swift
│   └── GameState.swift
|
├── ViewModel/
│   └── GameViewModel.swift
|
├── View/
│   ├── MainMenu/
│   │   └── MainMenuView.swift
│   ├── Game/
│   │   ├── GameView.swift
│   │   ├── GridView.swift
│   │   ├── HUDView.swift
│   │   └── ControlsView.swift
│   ├── Popups/
│   │   └── LevelCompleteView.swift
│   └── Reusable/
│       └── PuzzleCellView.swift
|
├── Services/
│   ├── PuzzleService.swift
│   └── PersistenceService.swift
|
└── Resources/
    ├── Assets.xcassets     // App icon, images, colors
    └── Puzzles/
        └── puzzles.json    // Puzzle data file
