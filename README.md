# Simple Cross Sums

<div align="center">

**A production-ready iOS logic puzzle game built with SwiftUI**

[![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0+-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![Game Center](https://img.shields.io/badge/Game%20Center-Enabled-purple.svg)](https://developer.apple.com/game-center/)
[![Tests](https://img.shields.io/badge/Test%20Coverage-100%25-brightgreen.svg)](#testing)

*Challenge your mind with number puzzles where strategy meets logic*

</div>

## 📱 About

Simple Cross Sums is a sophisticated logic puzzle game where players solve number grids by strategically marking cells to match target row and column sums. Built with modern SwiftUI and MVVM architecture, it features Game Center integration, progressive difficulty levels, and an advanced puzzle generation system.

### 🎯 How to Play

- **Tap** numbers to keep them (green) - they count toward the sum
- **Long press** numbers to remove them (red) - they don't count toward the sum  
- **Drag** numbers to clear markings (back to unmarked)
- Match the target sums shown for each row and column
- Complete all sums correctly to win!

## ✨ Features

### 🎮 Core Gameplay
- **5 Difficulty Levels**: Easy → Medium → Hard → Extra Hard → Expert
- **Progressive Level System**: Unlock higher difficulties as you improve
- **Lives System**: Strategic gameplay with mistake penalties
- **Hint System**: Get help when you're stuck
- **Smart Puzzle Generation**: Advanced algorithms ensure unique, solvable puzzles

### 🏆 Game Center Integration
- **Achievements**: 7 unique achievements to unlock
  - First Steps, Getting Serious, Expert, Master
  - Lightning Fast, Speed Demon
  - Easy Master, Medium Master, Hard Master
- **Leaderboards**: Compete globally on total levels completed
- **Progress Tracking**: Automatic sync across devices

### 🎨 User Experience
- **Native SwiftUI Interface**: Modern, responsive design
- **Accessibility Support**: Full VoiceOver and accessibility features
- **Haptic Feedback**: Tactile responses for interactions
- **Auto-Save**: Never lose your progress
- **Help System**: In-game instructions and tips

### 🔧 Technical Excellence
- **100% Test Coverage**: Comprehensive unit and UI testing
- **Thread-Safe Architecture**: Robust concurrent puzzle caching
- **Memory Efficient**: Optimized for smooth performance
- **Error Handling**: Graceful fallbacks and error recovery

## 📱 Screenshots

| Main Menu | Game Board | Level Complete |
|-----------|------------|----------------|
| ![Main Menu](Screenshots/Manual/01-MainMenu_0_0B46A1AD-7A96-46E6-BE11-C4DC436F58C4.png) | ![Game Board](Screenshots/Manual/02-GameBoard_0_18D59734-EAEB-4DF4-86EA-BF22004EC524.png) | *Coming Soon* |

## 🛠 Technical Stack

### Architecture
- **Design Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI 4.0+
- **Concurrency**: Swift Concurrency with thread-safe caching
- **Data Persistence**: UserDefaults with file-based fallbacks
- **Testing**: XCTest with comprehensive UI automation

### Key Technologies
- **Swift 5.0+** - Modern, safe programming language
- **SwiftUI** - Declarative user interface framework  
- **Game Center** - Achievements, leaderboards, player authentication
- **GameKit** - iOS gaming framework integration
- **XCTest** - Unit testing and UI automation
- **Combine** - Reactive programming for data flow

### Project Structure
```
CrossSumsSimple/
├── Model/                  # Core data models
│   ├── Puzzle.swift       # Puzzle data structure
│   ├── GameState.swift    # Game state management
│   └── PlayerProfile.swift # Player progress tracking
├── View/                   # SwiftUI views
│   ├── Game/              # Game-related views
│   ├── MainMenu/          # Menu and navigation
│   ├── Popups/            # Modals and overlays
│   └── Reusable/          # Shared components
├── ViewModel/              # MVVM view models
│   └── GameViewModel.swift # Core game logic
├── Services/               # Business logic services
│   ├── PuzzleService.swift    # Puzzle generation/caching
│   ├── GameCenterManager.swift # Game Center integration
│   ├── PersistenceService.swift # Data persistence
│   └── AchievementTracker.swift # Achievement tracking
└── Resources/              # Assets and data files
    ├── Assets.xcassets    # App icons and images
    └── Puzzles/           # Puzzle data files
```

## 🚀 Getting Started

### Requirements
- **Xcode 15.0+**
- **iOS 18.0+** (iPhone and iPad)
- **macOS 14.0+** (for development)
- **Apple Developer Account** (for Game Center features)

### Installation & Setup

1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd cross-sums
   ```

2. **Open in Xcode**
   ```bash
   open CrossSumsSimple.xcodeproj
   ```

3. **Build and run**
   - Select your target device/simulator
   - Press `⌘+R` to build and run

### Development Commands

**Building:**
```bash
xcodebuild -project "CrossSumsSimple.xcodeproj" -scheme "Simple Cross Sums" -destination "platform=iOS Simulator,name=iPhone 16 Pro Max"
```

**Testing:**
```bash
# Run all tests
xcodebuild test -project "CrossSumsSimple.xcodeproj" -scheme "Simple Cross Sums" -destination "platform=iOS Simulator,name=iPhone 16 Pro Max"

# Unit tests only
xcodebuild test -project "CrossSumsSimple.xcodeproj" -scheme "Simple Cross Sums" -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" -only-testing "Simple Cross Sums Tests"

# UI tests only  
xcodebuild test -project "CrossSumsSimple.xcodeproj" -scheme "Simple Cross Sums" -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" -only-testing "Simple Cross Sums UI Tests"
```

**Cleaning:**
```bash
xcodebuild clean -project "CrossSumsSimple.xcodeproj"
```

## 🧪 Testing

This project maintains **100% test coverage** across all critical components:

### Test Suites
- **Unit Tests** (`CrossSumsTests/`)
  - `GameViewModelTests.swift` - Core game logic validation
  - `PuzzleServiceTests.swift` - Puzzle generation algorithms  
  - `PersistenceServiceTests.swift` - Data persistence functionality
  - **Concurrent Access Tests** - Thread-safety validation

- **UI Tests** (`CrossSumsUITests/`)
  - `CrossSumsUITests.swift` - User interaction flows
  - `AppStoreScreenshotTests.swift` - Automated screenshot generation
  - **Performance Tests** - Launch time and responsiveness

### Key Test Features
- **Robust Element Detection** - 30-second timeouts with fallback strategies
- **Accessibility Testing** - VoiceOver and accessibility identifier validation
- **Screenshot Automation** - Automatic App Store screenshot generation
- **Concurrency Testing** - Thread-safe service validation
- **Memory Testing** - Performance and memory usage validation

## 🎮 Game Mechanics

### Puzzle Generation
- **Advanced Algorithms**: Backtracking with constraint satisfaction
- **Difficulty Scaling**: Progressive complexity across 5 levels
- **Unique Solutions**: Every puzzle has exactly one correct solution
- **Quality Validation**: Automated testing ensures puzzle solvability

### Scoring & Progression
- **Level-Based Progression**: Complete levels to unlock new difficulties
- **Achievement System**: 7 unique achievements with Game Center integration
- **Mistake Penalties**: Limited lives encourage strategic thinking
- **Hint System**: Optional assistance without penalty

### User Interface
- **Visual Feedback**: Color-coded cell states (green=keep, red=remove)
- **Haptic Feedback**: Tactile responses for all interactions
- **Accessibility**: Full VoiceOver support with custom accessibility actions
- **Responsive Design**: Optimized for all iPhone and iPad screen sizes

## 🤝 Contributing

This is a production-ready application with comprehensive testing and documentation. When contributing:

1. **Maintain Test Coverage**: All new features must include tests
2. **Follow MVVM Architecture**: Keep business logic in ViewModels and Services
3. **Accessibility First**: Ensure all UI elements are accessible
4. **Code Quality**: Follow Swift best practices and existing conventions
5. **Documentation**: Update README and inline documentation as needed

### Development Guidelines
- **Build Must Succeed**: All commits must compile without warnings
- **Tests Must Pass**: 100% test pass rate is required
- **Thread Safety**: Consider concurrent access patterns
- **Error Handling**: Include graceful fallbacks and error recovery

## 📄 License

[Add your license information here]

## 🙏 Acknowledgments

- Built with modern SwiftUI and iOS frameworks
- Puzzle generation algorithms inspired by constraint satisfaction research
- Accessibility features following Apple's Human Interface Guidelines
- Game Center integration following Apple's best practices

---

<div align="center">

**[Download on the App Store](#)** • **[View Architecture Docs](Architecture.md)** • **[Report Issues](#)**

*Simple Cross Sums - Where numbers meet strategy* ✨

</div>