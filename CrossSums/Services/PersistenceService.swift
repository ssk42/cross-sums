import Foundation

class PersistenceService {
    // TODO: Implement PersistenceService
    // This will be implemented in Task 3.1
    
    func saveProfile(_ profile: PlayerProfile) {
        // TODO: Save profile to UserDefaults or file storage
    }
    
    func loadProfile() -> PlayerProfile {
        // TODO: Load profile from device storage
        // Return default profile if none exists
        return PlayerProfile(highestLevelCompleted: [:], totalHints: 5, soundEnabled: true)
    }
}