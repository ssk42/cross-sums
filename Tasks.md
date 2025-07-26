# Cross Sums - Implementation Tasks

This document breaks down all tasks required to implement the Cross Sums iOS application based on the Architecture.md specification. Tasks are organized by component and feature, with clear acceptance criteria and user story mappings.

---

## 1. Project Setup & Infrastructure

### 1.1 Create Xcode Project
**Acceptance Criteria:**
- [ ] Create new iOS project named "CrossSums"
- [ ] Set minimum iOS deployment target (iOS 18+)
- [ ] Configure bundle identifier
- [ ] Set up proper folder structure matching Architecture.md:66-98

### 1.2 Configure Build Settings
**Acceptance Criteria:**
- [ ] Configure build settings for SwiftUI
- [ ] Set up code signing
- [ ] Configure app metadata (name, version, etc.)

### 1.3 Set Up Assets
**Acceptance Criteria:**
- [ ] Create Assets.xcassets with app icon
- [ ] Add color assets for UI theming
- [ ] Add any required image assets

---

## 2. Data Models Implementation

### 2.1 Create Puzzle Model (US3)
**File:** `Model/Puzzle.swift`
**Acceptance Criteria:**
- [ ] Implement Puzzle struct with Codable and Identifiable protocols
- [ ] Include all required properties: id, difficulty, grid, solution, rowSums, columnSums
- [ ] Add proper documentation comments

### 2.2 Create PlayerProfile Model (US9)
**File:** `Model/PlayerProfile.swift`
**Acceptance Criteria:**
- [ ] Implement PlayerProfile struct with Codable protocol
- [ ] Include highestLevelCompleted dictionary, totalHints, soundEnabled
- [ ] Add default initializer for new players

### 2.3 Create GameState Model
**File:** `Model/GameState.swift`
**Acceptance Criteria:**
- [ ] Implement GameState struct
- [ ] Include playerGridMask and livesRemaining properties
- [ ] Add methods for grid state management

---

## 3. Services Layer

### 3.1 Implement PersistenceService (US9)
**File:** `Services/PersistenceService.swift`
**Acceptance Criteria:**
- [ ] Create PersistenceService class
- [ ] Implement saveProfile(_ profile: PlayerProfile) method
- [ ] Implement loadProfile() -> PlayerProfile method
- [ ] Use UserDefaults or file storage for persistence
- [ ] Handle error cases gracefully

### 3.2 Implement PuzzleService
**File:** `Services/PuzzleService.swift`
**Acceptance Criteria:**
- [ ] Create PuzzleService class
- [ ] Implement getPuzzle(difficulty: String, level: Int) -> Puzzle? method
- [ ] Load puzzle data from JSON file
- [ ] Handle missing puzzles gracefully
- [ ] Validate puzzle data integrity

### 3.3 Create Puzzle Data
**File:** `Resources/Puzzles/puzzles.json`
**Acceptance Criteria:**
- [ ] Create JSON file with puzzle data structure
- [ ] Include puzzles for Easy, Medium, Hard, Extra Hard difficulties
- [ ] Ensure each puzzle has valid solution
- [ ] Include at least 10 puzzles per difficulty level

---

## 4. ViewModels

### 4.1 Implement GameViewModel
**File:** `ViewModel/GameViewModel.swift`
**Acceptance Criteria:**
- [ ] Create GameViewModel class conforming to ObservableObject
- [ ] Implement all required @Published properties (puzzle, gameState, isLevelComplete, isGameOver)
- [ ] Implement toggleCell(row: Int, col: Int) method (US4, US5, US6)
- [ ] Implement useHint() method (US7)
- [ ] Implement restartLevel() method (US10)
- [ ] Implement checkForWinCondition() method (US8)
- [ ] Add game logic for lives and mistake detection
- [ ] Integrate with PuzzleService and PersistenceService

---

## 5. Views Implementation

### 5.1 Create App Entry Point
**File:** `CrossSumsApp.swift`
**Acceptance Criteria:**
- [ ] Create main App struct
- [ ] Set up initial navigation to MainMenuView
- [ ] Configure app-level dependencies

### 5.2 Implement MainMenuView (US1, US2)
**File:** `View/MainMenu/MainMenuView.swift`
**Acceptance Criteria:**
- [ ] Create SwiftUI view with difficulty selection
- [ ] Implement isLoading, selectedDifficulty, levelToPlay state
- [ ] Add onAppear() to load PlayerProfile
- [ ] Implement didChangeDifficulty(to: String) action
- [ ] Implement didTapPlay() navigation action
- [ ] Implement didTapHelp() modal action
- [ ] Display current level for selected difficulty

### 5.3 Implement GameView (US3, US4, US5, US6, US7, US10)
**File:** `View/Game/GameView.swift`
**Acceptance Criteria:**
- [ ] Create main gameplay view
- [ ] Compose HUDView, GridView, and ControlsView
- [ ] Integrate with GameViewModel
- [ ] Handle navigation to LevelCompleteView
- [ ] Handle game over states

### 5.4 Implement GridView (US3, US4, US5)
**File:** `View/Game/GridView.swift`
**Acceptance Criteria:**
- [ ] Create grid layout for puzzle cells
- [ ] Display row and column target sums
- [ ] Integrate PuzzleCellView components
- [ ] Handle grid sizing and layout

### 5.5 Implement PuzzleCellView (US4, US5)
**File:** `View/Reusable/PuzzleCellView.swift`
**Acceptance Criteria:**
- [ ] Create interactive cell component
- [ ] Display number value
- [ ] Show visual states (kept/removed/unmarked)
- [ ] Handle tap gestures
- [ ] Animate state changes

### 5.6 Implement HUDView (US6, US7)
**File:** `View/Game/HUDView.swift`
**Acceptance Criteria:**
- [ ] Display current level number
- [ ] Display lives remaining
- [ ] Display available hints count
- [ ] Update in real-time with game state

### 5.7 Implement ControlsView (US7, US10)
**File:** `View/Game/ControlsView.swift`
**Acceptance Criteria:**
- [ ] Create "Hint" button
- [ ] Create "Restart" button
- [ ] Handle button actions via GameViewModel
- [ ] Disable buttons when appropriate (no hints left, etc.)

### 5.8 Implement LevelCompleteView (US8)
**File:** `View/Popups/LevelCompleteView.swift`
**Acceptance Criteria:**
- [ ] Create modal view for level completion
- [ ] Display completion message with difficulty and level
- [ ] Implement didTapNextLevel() action
- [ ] Implement didTapMainMenu() action
- [ ] Show celebration/success UI elements

### 5.9 Create Help/How to Play Modal
**Acceptance Criteria:**
- [ ] Create modal view explaining game rules
- [ ] Include visual examples of gameplay
- [ ] Add close/dismiss functionality

---

## 6. Game Logic & Features

### 6.1 Implement Cell Selection Logic (US4, US5)
**Acceptance Criteria:**
- [x] Track cell states (kept/removed/unmarked)
- [x] Validate cell selections against solution
- [x] Provide visual feedback for user actions

### 6.2 Implement Lives System (US6)
**Acceptance Criteria:**
- [x] Start each level with defined number of lives
- [x] Decrease lives on incorrect moves
- [x] Trigger game over when lives reach zero
- [x] Prevent further moves when game over

### 6.3 Implement Hint System (US7)
**Acceptance Criteria:**
- [x] Track available hints in PlayerProfile
- [x] Reveal correct cell when hint used
- [x] Decrease hint count on usage
- [x] Handle case when no hints available

### 6.4 Implement Win Condition Checking (US8)
**Acceptance Criteria:**
- [x] Check row sums against targets
- [x] Check column sums against targets
- [x] Trigger level complete when all sums match
- [x] Update player progress on completion

### 6.5 Implement Level Progression (US2, US9)
**Acceptance Criteria:**
- [x] Track highest completed level per difficulty
- [x] Save progress automatically
- [x] Load next available level for difficulty
- [x] Handle completion of all levels in difficulty

---

## 7. Data & Resources

### 7.1 Generate Puzzle Content
**Acceptance Criteria:**
- [x] Create algorithm to generate valid puzzles
- [x] Ensure each puzzle has unique solution
- [x] Create puzzles across all difficulty levels
- [x] Validate puzzle solvability

### 7.2 Design Visual Assets
**Acceptance Criteria:**
- [x] Design app icon
- [x] Create color scheme for UI
- [x] Design cell states visual indicators
- [x] Create any additional UI graphics

---

## 8. Testing & Polish

### 8.1 Unit Tests
**Acceptance Criteria:**
- [x] Test Puzzle model validation
- [ ] Test GameViewModel logic
- [ ] Test PersistenceService save/load
- [ ] Test PuzzleService data loading
- [ ] Test game logic (win conditions, lives, hints)

### 8.2 UI Tests
**Acceptance Criteria:**
- [ ] Test main user flow (menu -> game -> completion)
- [ ] Test difficulty selection
- [ ] Test puzzle interaction
- [ ] Test hint and restart functionality

### 8.3 Performance & Polish
**Acceptance Criteria:**
- [ ] Optimize view rendering performance
- [ ] Add smooth animations and transitions
- [ ] Handle edge cases and error states
- [ ] Test on various iOS devices/screen sizes

### 8.4 Accessibility
**Acceptance Criteria:**
- [ ] Add VoiceOver support
- [ ] Ensure proper contrast ratios
- [ ] Add accessibility labels and hints
- [ ] Test with accessibility features enabled

---

## Dependencies & Order

**Phase 1 (Foundation):**
1. Project Setup (1.1-1.3)
2. Data Models (2.1-2.3)
3. Services (3.1-3.2)

**Phase 2 (Core Features):**
4. Puzzle Data (3.3)
5. GameViewModel (4.1)
6. Game Logic (6.1-6.4)

**Phase 3 (UI Implementation):**
7. Views (5.1-5.9)
8. Level Progression (6.5)

**Phase 4 (Polish):**
9. Testing (8.1-8.2)
10. Assets & Polish (7.2, 8.3-8.4)

---

## User Story Mapping

- **US1:** MainMenuView difficulty selection (5.2)
- **US2:** Level progression logic (6.5), MainMenuView continue feature (5.2)
- **US3:** GridView puzzle display (5.4), GameView composition (5.3)
- **US4:** PuzzleCellView interaction (5.5), Cell selection logic (6.1)
- **US5:** PuzzleCellView visual states (5.5), Cell selection logic (6.1)
- **US6:** Lives system (6.2), HUDView display (5.6), GameViewModel integration (4.1)
- **US7:** Hint system (6.3), ControlsView hint button (5.7), HUDView display (5.6)
- **US8:** Win condition checking (6.4), LevelCompleteView (5.8)
- **US9:** PersistenceService (3.1), PlayerProfile model (2.2), Level progression (6.5)
- **US10:** ControlsView restart button (5.7), GameViewModel restart logic (4.1)