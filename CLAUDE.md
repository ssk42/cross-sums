# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CrossSumsSimple is an iOS logic puzzle game built with SwiftUI and MVVM architecture. Players solve number puzzles by marking grid cells to match target row and column sums. Currently in specification phase - no actual implementation exists yet.

## Development Commands

This project appears to be in the specification/planning phase. No build configuration files (Xcode project, Package.swift, Podfile, etc.) are present yet.

When the project is implemented, typical iOS development commands will include:
- Building: Use Xcode's build system (⌘+B) or `xcodebuild`
- Testing: Xcode's test runner (⌘+U) or `xcodebuild test`
- Running: iOS Simulator via Xcode or command line tools

## Architecture

The project follows MVVM (Model-View-ViewModel) architecture with SwiftUI:

### Core Data Models (Architecture.md:34-58)
- `Puzzle`: Represents a single puzzle with grid, solution, and target sums
- `PlayerProfile`: Persistent player data including progress and settings
- `GameState`: Ephemeral state during active gameplay

### Planned Project Structure (Architecture.md:66-98)
```
CrossSumsSimple/
├── Model/ (Puzzle, PlayerProfile, GameState)
├── ViewModel/ (GameViewModel)
├── View/ (MainMenu, Game, Popups, Reusable components)
├── Services/ (PuzzleService, PersistenceService)
└── Resources/ (Assets, puzzle data JSON)
```

### Key Views
- `MainMenuView`: Difficulty selection and level progression
- `GameView`: Main gameplay with grid, HUD, and controls
- `LevelCompleteView`: Success modal

### Services
- `PersistenceService`: PlayerProfile save/load via UserDefaults or files
- `PuzzleService`: Puzzle data management from JSON resources

## Game Logic
- Grid-based number puzzle with target row/column sums
- Player marks numbers for keeping/removing to match targets
- Lives system with mistake penalties
- Hint system for assistance
- Difficulty-based level progression

## Must-do's
- After any task is done, a build must be run. 
- Whenever a build is run, the build must succeed. If there's any failure, it must be corrected before anything else can continue. 
- When a test is run, the test must succeed. If there's a failure, or if there's any compilation failure, it must be corrected before anything else can con tinue.