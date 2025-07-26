import Foundation

/// Service responsible for persisting and loading player profile data
/// 
/// Uses UserDefaults for simple, reliable persistence of player progress,
/// settings, and hint counts. Handles data migration and error recovery gracefully.
public class PersistenceService {
    
    // MARK: - Constants
    
    private static let profileKey = "CrossSumsSimple_PlayerProfile"
    private static let dataVersionKey = "CrossSumsSimple_DataVersion"
    private static let currentDataVersion = 1
    
    // MARK: - Singleton
    
    public static let shared = PersistenceService()
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Saves the player profile to UserDefaults
    /// - Parameter profile: The PlayerProfile to save
    /// - Returns: true if save was successful, false otherwise
    @discardableResult
    public func saveProfile(_ profile: PlayerProfile) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(profile)
            UserDefaults.standard.set(data, forKey: Self.profileKey)
            UserDefaults.standard.set(Self.currentDataVersion, forKey: Self.dataVersionKey)
            UserDefaults.standard.synchronize()
            
            print("✅ Player profile saved successfully")
            return true
            
        } catch {
            print("❌ Failed to save player profile: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Loads the player profile from UserDefaults
    /// - Returns: PlayerProfile (either loaded from storage or default if none exists)
    public func loadProfile() -> PlayerProfile {
        // Check if profile exists
        guard let data = UserDefaults.standard.data(forKey: Self.profileKey) else {
            print("ℹ️ No saved profile found, creating default profile")
            return createDefaultProfile()
        }
        
        // Check data version for migration
        let savedVersion = UserDefaults.standard.integer(forKey: Self.dataVersionKey)
        if savedVersion != Self.currentDataVersion {
            print("⚠️ Data version mismatch (saved: \(savedVersion), current: \(Self.currentDataVersion))")
            return handleDataMigration(data: data, fromVersion: savedVersion)
        }
        
        // Decode profile
        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(PlayerProfile.self, from: data)
            print("✅ Player profile loaded successfully")
            return profile
            
        } catch {
            print("❌ Failed to decode player profile: \(error.localizedDescription)")
            print("🔄 Falling back to default profile")
            return createDefaultProfile()
        }
    }
    
    /// Checks if a saved profile exists
    /// - Returns: true if a profile is saved, false otherwise
    func profileExists() -> Bool {
        return UserDefaults.standard.data(forKey: Self.profileKey) != nil
    }
    
    /// Deletes the saved profile (for reset functionality)
    /// - Returns: true if deletion was successful
    @discardableResult
    func deleteProfile() -> Bool {
        UserDefaults.standard.removeObject(forKey: Self.profileKey)
        UserDefaults.standard.removeObject(forKey: Self.dataVersionKey)
        UserDefaults.standard.synchronize()
        
        print("🗑️ Player profile deleted")
        return true
    }
    
    /// Creates a backup of the current profile with timestamp
    /// - Parameter profile: The profile to backup
    /// - Returns: true if backup was successful
    @discardableResult
    func backupProfile(_ profile: PlayerProfile) -> Bool {
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupKey = "\(Self.profileKey)_backup_\(timestamp)"
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            UserDefaults.standard.set(data, forKey: backupKey)
            UserDefaults.standard.synchronize()
            
            print("💾 Profile backup created: \(backupKey)")
            return true
            
        } catch {
            print("❌ Failed to create profile backup: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Gets all available backup keys
    /// - Returns: Array of backup key strings
    func getBackupKeys() -> [String] {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        return allKeys.filter { $0.hasPrefix("\(Self.profileKey)_backup_") }
    }
    
    /// Restores a profile from backup
    /// - Parameter backupKey: The backup key to restore from
    /// - Returns: PlayerProfile if successful, nil if backup not found or corrupted
    func restoreFromBackup(_ backupKey: String) -> PlayerProfile? {
        guard let data = UserDefaults.standard.data(forKey: backupKey) else {
            print("❌ Backup not found: \(backupKey)")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(PlayerProfile.self, from: data)
            print("📦 Profile restored from backup: \(backupKey)")
            return profile
            
        } catch {
            print("❌ Failed to restore from backup: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates a default player profile for new users
    /// - Returns: A new PlayerProfile with default values
    private func createDefaultProfile() -> PlayerProfile {
        return PlayerProfile(hints: 5, soundEnabled: true)
    }
    
    /// Handles data migration between versions
    /// - Parameters:
    ///   - data: The raw data to migrate
    ///   - fromVersion: The version to migrate from
    /// - Returns: Migrated PlayerProfile or default if migration fails
    private func handleDataMigration(data: Data, fromVersion: Int) -> PlayerProfile {
        print("🔄 Attempting data migration from version \(fromVersion) to \(Self.currentDataVersion)")
        
        // Create backup before migration
        let timestamp = Int(Date().timeIntervalSince1970)
        let migrationBackupKey = "\(Self.profileKey)_migration_backup_v\(fromVersion)_\(timestamp)"
        UserDefaults.standard.set(data, forKey: migrationBackupKey)
        
        // For now, since we only have version 1, just try to decode normally
        // In future versions, add specific migration logic here
        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(PlayerProfile.self, from: data)
            
            // Save migrated profile with new version
            if saveProfile(profile) {
                print("✅ Data migration successful")
                return profile
            } else {
                print("❌ Failed to save migrated profile")
                return createDefaultProfile()
            }
            
        } catch {
            print("❌ Data migration failed: \(error.localizedDescription)")
            return createDefaultProfile()
        }
    }
    
    // MARK: - Debug Methods
    
    /// Prints debug information about the saved profile
    func debugPrintProfile() {
        let profile = loadProfile()
        print("🐛 Debug Profile Info:")
        print("  - Total Hints: \(profile.totalHints)")
        print("  - Sound Enabled: \(profile.soundEnabled)")
        print("  - Total Levels Completed: \(profile.totalLevelsCompleted)")
        print("  - Played Difficulties: \(profile.playedDifficulties)")
        print("  - Highest Levels: \(profile.highestLevelCompleted)")
    }
    
    /// Gets the size of saved profile data in bytes
    /// - Returns: Size in bytes, or 0 if no profile saved
    func getProfileDataSize() -> Int {
        guard let data = UserDefaults.standard.data(forKey: Self.profileKey) else {
            return 0
        }
        return data.count
    }
}