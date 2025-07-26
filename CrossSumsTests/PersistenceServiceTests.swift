
import XCTest
@testable import CrossSumsSimple

class PersistenceServiceTests: XCTestCase {

    var persistenceService: PersistenceService!
    let userDefaultsSuiteName = "testUserDefaults"

    override func setUpWithError() throws {
        // Initialize PersistenceService with a temporary UserDefaults suite
        persistenceService = PersistenceService()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        UserDefaults.standard.addSuite(named: userDefaultsSuiteName)
    }

    override func tearDownWithError() throws {
        // Clean up temporary UserDefaults suite
        UserDefaults.standard.removeSuite(named: userDefaultsSuiteName)
        persistenceService = nil
    }

    func testSaveAndLoadProfile() throws {
        var profile = PlayerProfile(hints: 10, soundEnabled: true)
        profile.completeLevel(5, for: "Easy")
        profile.completeLevel(2, for: "Medium")

        // Save the profile
        let saveSuccess = persistenceService.saveProfile(profile)
        XCTAssertTrue(saveSuccess, "Profile should save successfully")

        // Load the profile
        let loadedProfile = persistenceService.loadProfile()

        // Verify loaded profile matches saved profile
        XCTAssertEqual(loadedProfile.totalHints, profile.totalHints)
        XCTAssertEqual(loadedProfile.soundEnabled, profile.soundEnabled)
        XCTAssertEqual(loadedProfile.highestLevelCompleted["Easy"], profile.highestLevelCompleted["Easy"])
        XCTAssertEqual(loadedProfile.highestLevelCompleted["Medium"], profile.highestLevelCompleted["Medium"])
        XCTAssertNil(loadedProfile.highestLevelCompleted["Hard"])
    }

    func testLoadProfile_noSavedProfile() throws {
        // Ensure no profile is saved initially
        UserDefaults.standard.removeObject(forKey: "CrossSumsSimple_PlayerProfile")

        let loadedProfile = persistenceService.loadProfile()

        // Verify a default profile is loaded
        XCTAssertEqual(loadedProfile.totalHints, 5) // Default hints
        XCTAssertTrue(loadedProfile.soundEnabled) // Default sound setting
        XCTAssertTrue(loadedProfile.highestLevelCompleted.isEmpty)
    }

    func testProfileExists() throws {
        XCTAssertFalse(persistenceService.profileExists(), "Profile should not exist initially")

        let profile = PlayerProfile()
        _ = persistenceService.saveProfile(profile)

        XCTAssertTrue(persistenceService.profileExists(), "Profile should exist after saving")
    }

    func testDeleteProfile() throws {
        let profile = PlayerProfile()
        _ = persistenceService.saveProfile(profile)
        XCTAssertTrue(persistenceService.profileExists(), "Profile should exist before deletion")

        let deleteSuccess = persistenceService.deleteProfile()
        XCTAssertTrue(deleteSuccess, "Profile should delete successfully")
        XCTAssertFalse(persistenceService.profileExists(), "Profile should not exist after deletion")
    }

    func testBackupAndRestoreProfile() throws {
        var originalProfile = PlayerProfile(hints: 10, soundEnabled: true)
        originalProfile.completeLevel(1, for: "Easy")
        _ = persistenceService.saveProfile(originalProfile)

        // Create a backup
        let backupSuccess = persistenceService.backupProfile(originalProfile)
        XCTAssertTrue(backupSuccess, "Backup should be created successfully")

        // Modify the original profile and save it
        originalProfile.totalHints = 0
        originalProfile.completeLevel(5, for: "Hard")
        _ = persistenceService.saveProfile(originalProfile)

        // Get backup keys
        let backupKeys = persistenceService.getBackupKeys()
        XCTAssertFalse(backupKeys.isEmpty, "Should have at least one backup key")

        // Restore from the first backup key found
        let restoredProfile = persistenceService.restoreFromBackup(backupKeys.first!)
        XCTAssertNotNil(restoredProfile, "Restored profile should not be nil")
        XCTAssertEqual(restoredProfile?.totalHints, 10, "Restored profile hints should match original")
        XCTAssertEqual(restoredProfile?.highestLevelCompleted["Easy"], 1, "Restored profile level should match original")
        XCTAssertNil(restoredProfile?.highestLevelCompleted["Hard"], "Restored profile should not have new levels from modified profile")
    }

    func testHandleDataMigration_noMigrationNeeded() throws {
        // Simulate saving a profile with the current version
        let profile = PlayerProfile(hints: 5, soundEnabled: true)
        _ = persistenceService.saveProfile(profile)

        // Load the profile, no migration should occur
        let loadedProfile = persistenceService.loadProfile()
        XCTAssertEqual(loadedProfile.totalHints, 5)
    }

    // Note: Testing handleDataMigration with an actual old version would require
    // simulating an old data structure, which is more complex for a unit test.
    // This test focuses on the no-migration path.

    func testGetProfileDataSize() throws {
        XCTAssertEqual(persistenceService.getProfileDataSize(), 0, "Initial data size should be 0")

        let profile = PlayerProfile(hints: 1, soundEnabled: false)
        _ = persistenceService.saveProfile(profile)

        XCTAssertTrue(persistenceService.getProfileDataSize() > 0, "Data size should be greater than 0 after saving")
    }
}

