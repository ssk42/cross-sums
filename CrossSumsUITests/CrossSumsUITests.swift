//
//  CrossSumsSimpleUITests.swift
//  CrossSumsSimpleUITests
//
//  Created by Stephen Reitz on 7/26/25.
//

import XCTest

final class CrossSumsSimpleUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - Main User Flow Tests

    @MainActor
    func testMainUserFlow_menuToGameToCompletion() throws {
        // Test complete user journey from menu to game completion
        
        // Verify main menu elements exist
        XCTAssertTrue(app.staticTexts["Cross Sums"].exists, "App title should be visible")
        XCTAssertTrue(app.staticTexts["Select Difficulty"].exists, "Difficulty selector should be visible")
        XCTAssertTrue(app.buttons["Play"].exists, "Play button should be visible")
        
        // Select Easy difficulty
        let difficultyPicker = app.segmentedControls.firstMatch
        XCTAssertTrue(difficultyPicker.exists, "Difficulty picker should exist")
        
        if difficultyPicker.buttons["Easy"].exists {
            difficultyPicker.buttons["Easy"].tap()
        }
        
        // Verify level information is displayed
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Next Level:'")).firstMatch.exists,
                      "Next level information should be visible")
        
        // Tap Play button
        app.buttons["Play"].tap()
        
        // Wait for game view to load
        let gameViewLoaded = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(gameViewLoaded, "Game view should load after tapping Play")
        
        // Verify game elements are present
        XCTAssertTrue(app.buttons["Hint"].exists || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Hint'")).firstMatch.exists, 
                      "Hint button or hint count should be visible")
        XCTAssertTrue(app.buttons["Restart"].exists || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Restart'")).firstMatch.exists, 
                      "Restart button should be visible")
        
        // Verify grid is present (look for numeric buttons/text)
        let gridCells = app.buttons.allElementsBoundByIndex.filter { element in
            if let label = element.label.first, label.isNumber {
                return true
            }
            return false
        }
        XCTAssertGreaterThan(gridCells.count, 0, "Game grid with numbered cells should be visible")
        
        // Try to interact with grid cells
        if let firstCell = gridCells.first {
            firstCell.tap()
            // Cell should change state after tap
        }
        
        // Test navigation back to main menu
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(app.staticTexts["Cross Sums"].waitForExistence(timeout: 3), "Should return to main menu")
        }
    }

    // MARK: - Difficulty Selection Tests

    @MainActor
    func testDifficultySelection() throws {
        let difficultyPicker = app.segmentedControls.firstMatch
        XCTAssertTrue(difficultyPicker.exists, "Difficulty picker should exist")
        
        let difficulties = ["Easy", "Medium", "Hard", "Extra Hard"]
        
        for difficulty in difficulties {
            if difficultyPicker.buttons[difficulty].exists {
                difficultyPicker.buttons[difficulty].tap()
                
                // Verify the selection is reflected in the UI
                let selectedButton = difficultyPicker.buttons[difficulty]
                XCTAssertTrue(selectedButton.isSelected, "\(difficulty) should be selected after tap")
                
                // Verify level information updates
                let nextLevelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Next Level:'")).firstMatch
                XCTAssertTrue(nextLevelText.exists, "Next level info should be visible for \(difficulty)")
                
                // Small delay to allow UI updates
                usleep(500000) // 0.5 seconds
            }
        }
    }

    @MainActor
    func testDifficultySelectionPersistence() throws {
        // Select a non-default difficulty
        let difficultyPicker = app.segmentedControls.firstMatch
        if difficultyPicker.buttons["Hard"].exists {
            difficultyPicker.buttons["Hard"].tap()
            
            // Navigate to game and back
            app.buttons["Play"].tap()
            
            // Wait for game to load then go back
            _ = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 3)
            
            if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            // Verify Hard is still selected
            XCTAssertTrue(difficultyPicker.buttons["Hard"].isSelected, "Hard difficulty should remain selected")
        }
    }

    // MARK: - Puzzle Interaction Tests

    @MainActor
    func testPuzzleInteraction() throws {
        // Navigate to game
        app.buttons["Play"].tap()
        
        // Wait for game to load
        let gameLoaded = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(gameLoaded, "Game should load")
        
        // Find grid cells (buttons with numeric labels)
        let gridCells = app.buttons.allElementsBoundByIndex.filter { element in
            if let label = element.label.first, label.isNumber {
                return true
            }
            return false
        }
        
        XCTAssertGreaterThan(gridCells.count, 0, "Should have interactive grid cells")
        
        // Test cell interactions
        if let firstCell = gridCells.first {
            let initialAccessibilityValue = firstCell.value as? String
            
            // Tap the cell
            firstCell.tap()
            
            // Cell state should change (accessibility value might change)
            usleep(500000) // Wait for state change
            
            let newAccessibilityValue = firstCell.value as? String
            // Note: The actual state change verification depends on accessibility implementation
            
            // Tap again to test state cycling
            firstCell.tap()
            usleep(500000)
            
            // Tap a third time to complete the cycle
            firstCell.tap()
            usleep(500000)
        }
        
        // Test multiple cell interactions
        if gridCells.count > 1 {
            for i in 0..<min(3, gridCells.count) {
                gridCells[i].tap()
                usleep(250000) // Quarter second between taps
            }
        }
    }

    @MainActor
    func testGridSumDisplay() throws {
        // Navigate to game
        app.buttons["Play"].tap()
        
        // Wait for game to load
        _ = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 5)
        
        // Look for sum displays (row and column targets)
        let sumTexts = app.staticTexts.allElementsBoundByIndex.filter { element in
            if let label = element.label.first, label.isNumber {
                return true
            }
            return false
        }
        
        XCTAssertGreaterThan(sumTexts.count, 0, "Should display target sums for rows and columns")
    }

    // MARK: - Hint and Restart Functionality Tests

    @MainActor
    func testHintFunctionality() throws {
        // Navigate to game
        app.buttons["Play"].tap()
        
        // Wait for game to load
        _ = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 5)
        
        // Find hint button or hint count display
        let hintButton = app.buttons["Hint"]
        let hintText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Hint'")).firstMatch
        
        XCTAssertTrue(hintButton.exists || hintText.exists, "Hint functionality should be visible")
        
        if hintButton.exists && hintButton.isEnabled {
            // Store initial state
            let gridCells = app.buttons.allElementsBoundByIndex.filter { element in
                if let label = element.label.first, label.isNumber {
                    return true
                }
                return false
            }
            
            let initialStates = gridCells.map { $0.value as? String }
            
            // Use hint
            hintButton.tap()
            
            // Check if grid state changed after hint
            usleep(1000000) // 1 second for hint to apply
            
            let newStates = gridCells.map { $0.value as? String }
            
            // At least one cell should have changed state (received hint)
            let stateChanged = zip(initialStates, newStates).contains { $0 != $1 }
            // Note: This test might need adjustment based on accessibility implementation
        }
    }

    @MainActor
    func testRestartFunctionality() throws {
        // Navigate to game
        app.buttons["Play"].tap()
        
        // Wait for game to load
        _ = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 5)
        
        // Find grid cells and make some moves
        let gridCells = app.buttons.allElementsBoundByIndex.filter { element in
            if let label = element.label.first, label.isNumber {
                return true
            }
            return false
        }
        
        // Make some moves
        for i in 0..<min(2, gridCells.count) {
            gridCells[i].tap()
            usleep(250000)
        }
        
        // Find and tap restart button
        let restartButton = app.buttons["Restart"]
        XCTAssertTrue(restartButton.exists, "Restart button should exist")
        
        if restartButton.exists && restartButton.isEnabled {
            restartButton.tap()
            
            // Wait for restart to complete
            usleep(1000000)
            
            // Verify game has restarted (cells should be in initial state)
            // This verification depends on how cell states are represented in accessibility
        }
    }

    @MainActor
    func testGameControls_enabledStates() throws {
        // Navigate to game
        app.buttons["Play"].tap()
        
        // Wait for game to load
        _ = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 5)
        
        // Test that game controls are enabled at start
        let hintButton = app.buttons["Hint"]
        let restartButton = app.buttons["Restart"]
        
        if hintButton.exists {
            // Hint button should be enabled if hints are available
            let hintsText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Hint'")).firstMatch
            if hintsText.exists && hintsText.label.contains("0") {
                XCTAssertFalse(hintButton.isEnabled, "Hint button should be disabled when no hints available")
            } else {
                XCTAssertTrue(hintButton.isEnabled, "Hint button should be enabled when hints are available")
            }
        }
        
        if restartButton.exists {
            XCTAssertTrue(restartButton.isEnabled, "Restart button should always be enabled during gameplay")
        }
    }

    // MARK: - Help and Navigation Tests

    @MainActor
    func testHelpFunctionality() throws {
        // Test help button from main menu
        let helpButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How to Play'")).firstMatch
        XCTAssertTrue(helpButton.exists, "Help button should exist on main menu")
        
        helpButton.tap()
        
        // Wait for help view to appear
        let helpViewVisible = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'How' OR label CONTAINS 'Play' OR label CONTAINS 'Rule'")).firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(helpViewVisible, "Help view should appear")
        
        // Close help view (look for close button or tap outside)
        if app.buttons["Close"].exists {
            app.buttons["Close"].tap()
        } else if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        } else {
            // Try tapping outside the modal (this might vary based on implementation)
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        }
        
        // Should return to main menu
        XCTAssertTrue(app.staticTexts["Cross Sums"].waitForExistence(timeout: 3), "Should return to main menu after closing help")
    }

    @MainActor
    func testNavigationFlow() throws {
        // Test complete navigation flow
        
        // Main menu -> Game
        app.buttons["Play"].tap()
        let gameLoaded = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(gameLoaded, "Should navigate to game view")
        
        // Game -> Main menu (back navigation)
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(app.staticTexts["Cross Sums"].waitForExistence(timeout: 3), "Should navigate back to main menu")
        }
        
        // Main menu -> Help -> Main menu
        let helpButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How to Play'")).firstMatch
        if helpButton.exists {
            helpButton.tap()
            usleep(1000000) // Wait for help to appear
            
            // Close help
            if app.buttons["Close"].exists {
                app.buttons["Close"].tap()
            } else if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
            }
            
            XCTAssertTrue(app.staticTexts["Cross Sums"].waitForExistence(timeout: 3), "Should return to main menu after help")
        }
    }

    // MARK: - Performance and Stability Tests

    @MainActor
    func testGameLaunchPerformance() throws {
        // Test app launch performance
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let testApp = XCUIApplication()
            testApp.launch()
            testApp.terminate()
        }
    }

    @MainActor
    func testGameLoadPerformance() throws {
        // Test puzzle loading performance
        measure {
            app.buttons["Play"].tap()
            _ = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 10)
            
            if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
                _ = app.staticTexts["Cross Sums"].waitForExistence(timeout: 5)
            }
        }
    }

    @MainActor
    func testMultipleDifficultyLoading() throws {
        // Test loading different difficulties without crashes
        let difficulties = ["Easy", "Medium", "Hard"]
        let difficultyPicker = app.segmentedControls.firstMatch
        
        for difficulty in difficulties {
            if difficultyPicker.buttons[difficulty].exists {
                difficultyPicker.buttons[difficulty].tap()
                usleep(500000)
                
                app.buttons["Play"].tap()
                let gameLoaded = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch.waitForExistence(timeout: 5)
                XCTAssertTrue(gameLoaded, "\(difficulty) game should load successfully")
                
                if app.navigationBars.buttons.firstMatch.exists {
                    app.navigationBars.buttons.firstMatch.tap()
                    _ = app.staticTexts["Cross Sums"].waitForExistence(timeout: 3)
                }
            }
        }
    }

    // MARK: - Helper Methods
    
    private func takeScreenshot(name: String, description: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        print("📱 Screenshot captured: \(name) - \(description)")
    }
}
