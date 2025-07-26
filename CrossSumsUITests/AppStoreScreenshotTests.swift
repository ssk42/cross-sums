//
//  AppStoreScreenshotTests.swift
//  CrossSumsSimpleUITests
//
//  Created by Claude on 7/26/25.
//

import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Set up the app for screenshots
        let app = XCUIApplication()
        
        // Configure for App Store screenshots
        app.launchArguments += ["--screenshot-mode"]
        app.launchEnvironment["SCREENSHOTS"] = "true"
    }
    
    // MARK: - iPhone Screenshots
    
    @MainActor
    func testIPhoneScreenshots() throws {
        // This test should be run on iPhone simulators for App Store
        let app = XCUIApplication()
        app.launch()
        
        // Wait for launch
        sleep(3)
        
        captureAppStoreScreenshots(app: app, deviceType: "iPhone")
    }
    
    // MARK: - iPad Screenshots
    
    @MainActor
    func testIPadScreenshots() throws {
        // This test should be run on iPad simulators for App Store
        let app = XCUIApplication()
        app.launch()
        
        // Wait for launch
        sleep(3)
        
        captureAppStoreScreenshots(app: app, deviceType: "iPad")
    }
    
    // MARK: - Core Screenshot Capture
    
    private func captureAppStoreScreenshots(app: XCUIApplication, deviceType: String) {
        
        // Screenshot 1: Welcome/Main Menu
        takeAppStoreScreenshot(
            name: "\(deviceType)-01-Welcome",
            description: "Welcome screen showcasing the clean, intuitive interface"
        )
        
        // Try to navigate to game selection
        navigateToGameSelection(app: app)
        
        // Screenshot 2: Game Selection/Difficulty
        takeAppStoreScreenshot(
            name: "\(deviceType)-02-GameSelection", 
            description: "Choose your challenge level - Easy to Expert puzzles available"
        )
        
        // Start an easy game
        startGame(app: app, difficulty: "Easy")
        
        // Screenshot 3: Active Gameplay
        takeAppStoreScreenshot(
            name: "\(deviceType)-03-Gameplay",
            description: "Engaging number puzzle gameplay with intuitive grid interaction"
        )
        
        // Try to show game features
        demonstrateGameFeatures(app: app)
        
        // Screenshot 4: Game Features (hints, lives, etc.)
        takeAppStoreScreenshot(
            name: "\(deviceType)-04-Features",
            description: "Helpful features including hints system and progress tracking"
        )
        
        // Navigate to completion scenario if possible
        if simulateGameCompletion(app: app) {
            // Screenshot 5: Success/Completion
            takeAppStoreScreenshot(
                name: "\(deviceType)-05-Success",
                description: "Celebrate your victories with satisfying completion effects"
            )
        }
    }
    
    // MARK: - Navigation Helpers
    
    private func navigateToGameSelection(app: XCUIApplication) {
        // The main menu already shows difficulty selection
        // No need to navigate - difficulty picker is on main screen
        sleep(1)
    }
    
    private func startGame(app: XCUIApplication, difficulty: String) {
        // Select difficulty in segmented picker
        if app.segmentedControls.buttons[difficulty].exists {
            app.segmentedControls.buttons[difficulty].tap()
            sleep(1)
        }
        
        // Tap the Play button to start the game
        if app.buttons["Play"].exists {
            app.buttons["Play"].tap()
            sleep(3) // Allow time for game to load
        }
    }
    
    private func demonstrateGameFeatures(app: XCUIApplication) {
        // Try to highlight game features for screenshots
        
        // Look for hint button
        if app.buttons["Hint"].exists {
            // Don't tap, just ensure it's visible for screenshot
            sleep(1)
        }
        
        // Look for settings or menu
        if app.buttons["Menu"].exists || app.buttons["Settings"].exists {
            // Position for a good screenshot showing available options
            sleep(1)
        }
    }
    
    private func simulateGameCompletion(app: XCUIApplication) -> Bool {
        // This is challenging without knowing the exact game mechanics
        // For now, just check if there are any completion-related elements visible
        
        if app.alerts.firstMatch.exists {
            return true
        }
        
        if app.staticTexts["Congratulations"].exists {
            return true
        }
        
        if app.staticTexts["Level Complete"].exists {
            return true
        }
        
        return false
    }
    
    // MARK: - Screenshot Utilities
    
    private func takeAppStoreScreenshot(name: String, description: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        
        add(attachment)
        
        // Log for CI/CD systems
        print("📱 App Store Screenshot: \(name)")
        print("   Description: \(description)")
        print("   Device: \(UIDevice.current.name)")
        print("   Orientation: \(UIDevice.current.orientation.rawValue)")
        
        // Small delay between screenshots
        sleep(1)
    }
}

// MARK: - Device Configuration Extensions

extension AppStoreScreenshotTests {
    
    /// Configure the test for specific device screenshot requirements
    func configureForDevice(_ deviceType: String) {
        // This could be expanded to set specific device configurations
        // such as locale, appearance (light/dark), accessibility settings, etc.
        
        switch deviceType.lowercased() {
        case "iphone":
            // iPhone-specific configurations
            break
        case "ipad":
            // iPad-specific configurations  
            break
        default:
            break
        }
    }
}