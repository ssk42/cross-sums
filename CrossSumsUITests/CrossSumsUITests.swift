//
//  CrossSumsSimpleUITests.swift
//  CrossSumsSimpleUITests
//
//  Created by Stephen Reitz on 7/26/25.
//

import XCTest

final class CrossSumsSimpleUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - App Store Screenshots

    @MainActor
    func testAppStoreScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to fully load
        sleep(2)
        
        // Screenshot 1: Main Menu
        takeScreenshot(name: "01-MainMenu", description: "Main menu showing difficulty selection and game options")
        
        // Navigate to Easy game (assuming there's a way to select difficulty)
        // You'll need to replace these with actual UI element identifiers from your app
        if app.buttons["Easy"].exists {
            app.buttons["Easy"].tap()
            sleep(1)
            
            // Screenshot 2: Game Board
            takeScreenshot(name: "02-GameBoard", description: "Puzzle gameplay showing interactive grid")
        }
        
        // If there's a help or tutorial button
        if app.buttons["Help"].exists {
            app.buttons["Help"].tap()
            sleep(1)
            
            // Screenshot 3: Help Screen
            takeScreenshot(name: "03-HelpScreen", description: "Game instructions and rules")
            
            // Go back
            if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
        
        // Try to trigger a level completion scenario
        // This would need to be customized based on your app's flow
        
        // Screenshot 4: Settings (if available)
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
            sleep(1)
            takeScreenshot(name: "04-Settings", description: "Game settings and preferences")
        }
    }

    @MainActor
    func testGameplayScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        
        sleep(2)
        
        // Test different difficulty levels for variety
        let difficulties = ["Easy", "Medium", "Hard"]
        
        for (index, difficulty) in difficulties.enumerated() {
            if app.buttons[difficulty].exists {
                app.buttons[difficulty].tap()
                sleep(2)
                
                // Take screenshot of this difficulty level
                takeScreenshot(
                    name: "Gameplay-\(difficulty)-\(String(format: "%02d", index + 5))",
                    description: "\(difficulty) difficulty puzzle gameplay"
                )
                
                // Go back to main menu (adjust based on your navigation)
                if app.navigationBars.buttons.firstMatch.exists {
                    app.navigationBars.buttons.firstMatch.tap()
                }
                sleep(1)
            }
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Helper Methods
    
    private func takeScreenshot(name: String, description: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        
        // Add descriptive information
        add(attachment)
        
        // Print for build logs
        print("📱 Screenshot captured: \(name) - \(description)")
    }
}
