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
        sleep(2) // Give the app time to launch and render initial UI
    }

    override func tearDownWithError() throws {
        app.terminate()
        sleep(1) // Give the app time to fully quit
    }

    // MARK: - Main User Flow Tests

    @MainActor
    func testMainUserFlow_menuToGameToCompletion() throws {
        // Test complete user journey from menu to game completion
        
        // Verify main menu elements exist
        let crossSumsTitle = app.staticTexts["Cross Sums"]
        XCTAssertTrue(crossSumsTitle.waitForExistence(timeout: 5), "App title should be visible")
        
        let difficultySelector = app.staticTexts["Select Difficulty"]
        XCTAssertTrue(difficultySelector.waitForExistence(timeout: 2), "Difficulty selector should be visible")
        
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 2) && playButton.isHittable, "Play button should be visible and hittable")
        
        // Select Easy difficulty
        let difficultyPicker = app.segmentedControls.firstMatch
        XCTAssertTrue(difficultyPicker.waitForExistence(timeout: 2), "Difficulty picker should exist")
        
        let easyButton = difficultyPicker.buttons["Easy"]
        XCTAssertTrue(easyButton.waitForExistence(timeout: 2) && easyButton.isHittable, "Easy button should exist and be hittable")
        easyButton.tap()
        
        // Verify the selection is reflected in the UI
        let easySelectedPredicate = NSPredicate(format: "isSelected == TRUE")
        let easySelectedExpectation = XCTNSPredicateExpectation(predicate: easySelectedPredicate, object: easyButton)
        XCTWaiter().wait(for: [easySelectedExpectation], timeout: 1.0)
        XCTAssertTrue(easyButton.isSelected, "Easy should be selected after tap")
        
        // Verify level information is displayed
        let nextLevelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Next Level:'")).firstMatch
        XCTAssertTrue(nextLevelText.waitForExistence(timeout: 3),
                      "Next level information should be visible")
        
        // Tap Play button
        playButton.tap()
        
        // Wait for game view to load
        let gameViewLoaded = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch
        XCTAssertTrue(gameViewLoaded.waitForExistence(timeout: 5), "Game view should load after tapping Play")
        
        // Verify game elements are present
        let hintButton = app.buttons["Hint"]
        let restartButton = app.buttons["Restart"]
        XCTAssertTrue(hintButton.waitForExistence(timeout: 2) || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Hint'")).firstMatch.waitForExistence(timeout: 2), 
                      "Hint button or hint count should be visible")
        XCTAssertTrue(restartButton.waitForExistence(timeout: 2) || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Restart'")).firstMatch.waitForExistence(timeout: 2), 
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
        if let firstCell = gridCells.first, firstCell.isHittable {
            firstCell.tap()
            // Cell should change state after tap
        }
        
        // Test navigation back to main menu
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 2) && backButton.isHittable, "Back button should exist and be hittable")
        backButton.tap()
        XCTAssertTrue(app.staticTexts["Cross Sums"].waitForExistence(timeout: 5), "Should return to main menu")
    }

    // MARK: - Difficulty Selection Tests

    @MainActor
    func testDifficultySelection() throws {
        let difficultyPicker = app.segmentedControls.firstMatch
        XCTAssertTrue(difficultyPicker.waitForExistence(timeout: 5), "Difficulty picker should exist")
        
        let difficulties = ["Easy", "Medium", "Hard", "Extra Hard"]
        
        for difficulty in difficulties {
            let difficultyButton = difficultyPicker.buttons[difficulty]
            XCTAssertTrue(difficultyButton.waitForExistence(timeout: 2) && difficultyButton.isHittable, "\(difficulty) button should exist and be hittable")
            difficultyButton.tap()
            
            let predicate = NSPredicate(format: "isSelected == TRUE")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: difficultyButton)
            XCTWaiter().wait(for: [expectation], timeout: 1.0)
            
            // Verify the selection is reflected in the UI
            XCTAssertTrue(difficultyButton.isSelected, "\(difficulty) should be selected after tap")
            
            // Verify level information updates
            let nextLevelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Next Level:'")).firstMatch
            XCTAssertTrue(nextLevelText.waitForExistence(timeout: 3), "Next level info should be visible for \(difficulty)")
        }
    }

    @MainActor
    func testDifficultySelectionPersistence() throws {
        // Select a non-default difficulty
        let difficultyPicker = app.segmentedControls.firstMatch
        XCTAssertTrue(difficultyPicker.waitForExistence(timeout: 5), "Difficulty picker should exist")

        let hardButton = difficultyPicker.buttons["Hard"]
        XCTAssertTrue(hardButton.waitForExistence(timeout: 2) && hardButton.isHittable, "Hard button should exist and be hittable")
        hardButton.tap()
        XCTAssertTrue(hardButton.isSelected, "Hard difficulty should be selected")

        // Navigate to game and back
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 2) && playButton.isHittable, "Play button should be hittable")
        playButton.tap()

        // Wait for game to load then go back
        let gameLevelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch
        XCTAssertTrue(gameLevelText.waitForExistence(timeout: 5), "Game view should load")

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 2) && backButton.isHittable, "Back button should exist and be hittable")
        backButton.tap()
        XCTAssertTrue(app.staticTexts["Cross Sums"].waitForExistence(timeout: 5), "Should return to main menu")

        // Verify Hard is still selected
        XCTAssertTrue(hardButton.isSelected, "Hard difficulty should remain selected after returning to main menu")
    }

    // MARK: - Puzzle Interaction Tests

    @MainActor
    func testPuzzleInteraction() throws {
        // Navigate to game
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.exists && playButton.isHittable, "Play button should be hittable")
        playButton.tap()

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
        if let firstCell = gridCells.first, firstCell.isHittable {
            let initialAccessibilityValue = firstCell.value as? String

            // Tap the cell
            firstCell.tap()
            usleep(250000) // Small delay for UI to react

            // Cell state should change (accessibility value might change)
            var currentAccessibilityValue = firstCell.value as? String
            let firstTapPredicate = NSPredicate(format: "value != %@", initialAccessibilityValue ?? "")
            let firstTapExpectation = XCTNSPredicateExpectation(predicate: firstTapPredicate, object: firstCell)
            XCTWaiter().wait(for: [firstTapExpectation], timeout: 1.0)
            XCTAssertNotEqual(initialAccessibilityValue, currentAccessibilityValue, "Cell accessibility value should change after first tap")

            // Tap again to test state cycling
            let secondTapInitialValue = currentAccessibilityValue
            firstCell.tap()
            usleep(250000) // Small delay for UI to react
            currentAccessibilityValue = firstCell.value as? String
            let secondTapPredicate = NSPredicate(format: "value != %@", secondTapInitialValue ?? "")
            let secondTapExpectation = XCTNSPredicateExpectation(predicate: secondTapPredicate, object: firstCell)
            XCTWaiter().wait(for: [secondTapExpectation], timeout: 1.0)
            XCTAssertNotEqual(secondTapInitialValue, currentAccessibilityValue, "Cell accessibility value should change after second tap")

            // Tap a third time to complete the cycle
            let thirdTapInitialValue = currentAccessibilityValue
            firstCell.tap()
            usleep(250000) // Small delay for UI to react
            currentAccessibilityValue = firstCell.value as? String
            let thirdTapPredicate = NSPredicate(format: "value != %@", thirdTapInitialValue ?? "")
            let thirdTapExpectation = XCTNSPredicateExpectation(predicate: thirdTapPredicate, object: firstCell)
            XCTWaiter().wait(for: [thirdTapExpectation], timeout: 1.0)
            XCTAssertNotEqual(thirdTapInitialValue, currentAccessibilityValue, "Cell accessibility value should change after third tap")
        }

        // Test multiple cell interactions
        if gridCells.count > 1 {
            for i in 0..<min(3, gridCells.count) {
                if gridCells[i].isHittable {
                    gridCells[i].tap()
                    let existsPredicate = NSPredicate(format: "exists == true")
                    let existsExpectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: gridCells[i])
                    XCTWaiter().wait(for: [existsExpectation], timeout: 0.5)
                }
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
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 2) && playButton.isHittable, "Play button should be hittable")
        playButton.tap()
        
        // Wait for game to load
        let gameLevelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch
        XCTAssertTrue(gameLevelText.waitForExistence(timeout: 5), "Game view should load")
        
        // Find hint button or hint count display
        let hintButton = app.buttons["Hint"]
        let hintText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Hint'")).firstMatch
        
        XCTAssertTrue(hintButton.waitForExistence(timeout: 2) || hintText.waitForExistence(timeout: 2), "Hint functionality should be visible")
        
        if hintButton.exists && hintButton.isHittable && hintButton.isEnabled {
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
            let stateChangedPredicate = NSPredicate(format: "SELF != %@", initialStates as CVarArg)
            let stateChangedExpectation = XCTNSPredicateExpectation(predicate: stateChangedPredicate, object: gridCells)
            XCTWaiter().wait(for: [stateChangedExpectation], timeout: 2.0) // Increased timeout for hint to apply
            
            let newStates = gridCells.map { $0.value as? String }
            
            // At least one cell should have changed state (received hint)
            let stateChanged = zip(initialStates, newStates).contains { $0 != $1 }
            XCTAssertTrue(stateChanged, "At least one cell state should have changed after hint")
        }
    }

    @MainActor
    func testRestartFunctionality() throws {
        // Navigate to game
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 2) && playButton.isHittable, "Play button should be hittable")
        playButton.tap()
        
        // Wait for game to load
        let gameLevelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch
        XCTAssertTrue(gameLevelText.waitForExistence(timeout: 5), "Game view should load")
        
        // Find grid cells and make some moves
        let gridCells = app.buttons.allElementsBoundByIndex.filter { element in
            if let label = element.label.first, label.isNumber {
                return true
            }
            return false
        }
        
        XCTAssertGreaterThan(gridCells.count, 0, "Should have interactive grid cells")

        // Make some moves
        if gridCells.count > 0 && gridCells[0].isHittable {
            gridCells[0].tap()
            usleep(250000)
        }
        if gridCells.count > 1 && gridCells[1].isHittable {
            gridCells[1].tap()
            usleep(250000)
        }
        
        // Find and tap restart button
        let restartButton = app.buttons["Restart"]
        XCTAssertTrue(restartButton.waitForExistence(timeout: 2) && restartButton.isHittable, "Restart button should exist and be hittable")
        
        if restartButton.exists && restartButton.isEnabled {
            restartButton.tap()
            
            // Wait for restart to complete (e.g., game level text reappears or changes)
            XCTAssertTrue(gameLevelText.waitForExistence(timeout: 5), "Game should restart and level text should reappear")
            
            // Verify game has restarted (cells should be in initial state - this might require more specific checks)
            // For now, we'll just check if the game view is still present.
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
            let playButton = app.buttons["Play"]
            XCTAssertTrue(playButton.exists && playButton.isHittable, "Play button should be hittable")
            playButton.tap()

            let gameLevelText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Level'")).firstMatch
            XCTAssertTrue(gameLevelText.waitForExistence(timeout: 10), "Game view should load")
            
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists && backButton.isHittable {
                backButton.tap()
                XCTAssertTrue(app.staticTexts["Cross Sums"].waitForExistence(timeout: 5), "Should return to main menu")
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
                let selectedPredicate = NSPredicate(format: "isSelected == TRUE")
                let selectedExpectation = XCTNSPredicateExpectation(predicate: selectedPredicate, object: difficultyPicker.buttons[difficulty])
                XCTWaiter().wait(for: [selectedExpectation], timeout: 1.0)
                
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
