# CLAUDE.md


This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CrossSumsSimple is a fully implemented, production-ready iOS logic puzzle game built with SwiftUI and MVVM architecture. Players solve number puzzles by marking grid cells to match target row and column sums. The app features Game Center integration, comprehensive testing suite (100% pass rate), and advanced puzzle generation algorithms.

## Development Commands

This project is fully implemented with complete Xcode project structure. All development commands are operational:

### Building and Running
- **Build**: `xcodebuild -project "CrossSumsSimple.xcodeproj" -scheme "Simple Cross Sums" -destination "platform=iOS Simulator,name=iPhone 16 Pro Max"`
- **Run**: Use Xcode (⌘+R) or iOS Simulator via command line tools
- **Clean**: `xcodebuild clean -project "CrossSumsSimple.xcodeproj"`

### Testing (100% Pass Rate)
- **All Tests**: `xcodebuild test -project "CrossSumsSimple.xcodeproj" -scheme "Simple Cross Sums" -destination "platform=iOS Simulator,name=iPhone 16 Pro Max"`
- **Unit Tests Only**: `xcodebuild test -project "CrossSumsSimple.xcodeproj" -scheme "Simple Cross Sums" -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" -only-testing "Simple Cross Sums Tests"`
- **UI Tests Only**: `xcodebuild test -project "CrossSumsSimple.xcodeproj" -scheme "Simple Cross Sums" -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" -only-testing "Simple Cross Sums UI Tests"`

### Code Quality
- All tests must pass before any changes are considered complete
- Build must succeed without warnings for production readiness
- UI tests use robust element detection with 30-second timeouts

## Architecture

The project follows MVVM (Model-View-ViewModel) architecture with SwiftUI:

### Core Data Models (Architecture.md:34-58)
- `Puzzle`: Represents a single puzzle with grid, solution, and target sums
- `PlayerProfile`: Persistent player data including progress and settings
- `GameState`: Ephemeral state during active gameplay

### Implemented Project Structure
```
CrossSumsSimple/ (Xcode Project)
├── CrossSumsSimple/                    // Main app target
│   ├── Model/                          // ✅ Core data models
│   │   ├── Puzzle.swift
│   │   ├── PlayerProfile.swift
│   │   └── GameState.swift
│   ├── ViewModel/                      // ✅ MVVM ViewModels
│   │   └── GameViewModel.swift
│   ├── View/                           // ✅ SwiftUI Views
│   │   ├── MainMenuView.swift
│   │   ├── GameView.swift
│   │   ├── GridView.swift
│   │   ├── GameHUDView.swift
│   │   ├── PuzzleCellView.swift
│   │   └── LevelCompleteView.swift
│   ├── Services/                       // ✅ Business logic services
│   │   ├── PuzzleService.swift
│   │   ├── PersistenceService.swift
│   │   └── GameCenterManager.swift     // Game Center integration
│   └── Resources/                      // ✅ Assets and resources
│       ├── Assets.xcassets
│       └── Info.plist
├── CrossSumsSimpleTests/               // ✅ Unit tests (100% passing)
├── CrossSumsUITests/                   // ✅ UI tests (100% passing)
└── Simple Cross Sums.xctestplan       // ✅ Test plan configuration
```

### Key Views
- `MainMenuView`: Difficulty selection and level progression
- `GameView`: Main gameplay with grid, HUD, and controls
- `LevelCompleteView`: Success modal

### Services
- `PersistenceService`: PlayerProfile save/load via UserDefaults or files  
- `PuzzleService`: Advanced puzzle generation algorithm with backtracking
- `GameCenterManager`: Achievements and leaderboard integration

## Game Logic
- Grid-based number puzzle with target row/column sums
- Player marks numbers for keeping/removing to match targets
- Lives system with mistake penalties
- Hint system for assistance
- Difficulty-based level progression
- Game Center achievements and leaderboards

## Game Center Integration

### Achievements
- ✅ "first_level": Complete your first level
- ✅ "difficulty_easy": Complete 10 Easy levels
- ✅ "difficulty_medium": Complete 10 Medium levels  
- ✅ "difficulty_hard": Complete 10 Hard levels
- ✅ "puzzle_master": Complete 50 levels total
- ✅ "hint_master": Use 20 hints
- ✅ "perfectionist": Complete a level without mistakes

### Leaderboards
- ✅ Total levels completed across all difficulties
- ✅ Automatic progress submission
- ✅ Privacy-compliant integration

## Testing Strategy

### Unit Tests (100% Pass Rate)
- **GameViewModelTests**: Core game logic, state management, hint system
- **PuzzleServiceTests**: Puzzle generation algorithm validation  
- **PersistenceServiceTests**: Data persistence functionality
- **Concurrent Access Tests**: Thread-safety validation

### UI Tests (100% Pass Rate)
- **testAppLaunch**: App startup and main menu validation
- **testDifficultySelection**: Difficulty picker functionality
- **testBasicGameplay**: Grid interaction and game loading
- **testNavigationFlow**: Navigation between screens
- **testPerformance**: Launch performance metrics

### UI Test Element Identifiers
When working with UI tests, use these element identifiers:
- Grid cells: `cell00`, `cell01`, `cell02`, etc. (row/column format)
- Game controls: `hintButton`, `restartButton`, `mainMenuButton`
- Main menu: Uses text-based detection for "Cross Sums", "Play" button
- Difficulty selector: Segmented control with "Easy", "Medium", "Hard" segments

### Testing Best Practices
- All UI tests use 30-second timeouts for reliability
- Robust element detection with multiple fallback strategies
- App launch retry logic handles simulator timing issues
- Tests run in parallel for performance

## Must-do's
- After any task is done, a build must be run. 
- Whenever a build is run, the build must succeed. If there's any failure, it must be corrected before anything else can continue. 
- When a test is run, the test must succeed. If there's a failure, or if there's any compilation failure, it must be corrected before anything else can con tinue.
- Treat this app like a high level enterprise app. This needs to be top notch quality. Well architected, well tested, well developed. Using first class principles. 
- Before any commits, increase build numbers