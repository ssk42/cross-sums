import Foundation
import UIKit

/// Service responsible for generating shareable content for puzzle completions
/// 
/// Creates Wordle-style visual representations of puzzle solutions and
/// formats them for sharing on social media platforms.
public class ShareResultsService {
    
    // MARK: - Constants
    
    private static let appName = "Cross Sums"
    private static let dailyEmoji = "🗓️"
    private static let puzzleEmoji = "🧩"
    private static let timeEmoji = "⏱️"
    private static let movesEmoji = "🎯"
    private static let livesEmoji = "❤️"
    private static let streakEmoji = "🔥"
    
    // MARK: - Singleton
    
    public static let shared = ShareResultsService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Generates shareable text content for a completed puzzle
    /// - Parameters:
    ///   - puzzle: The completed puzzle
    ///   - completionTime: Time taken to complete
    ///   - movesUsed: Number of moves made during gameplay
    ///   - livesLeft: Number of lives remaining
    ///   - isDaily: Whether this is a daily puzzle
    ///   - streak: Daily streak (if daily puzzle)
    /// - Returns: Formatted shareable text
    public func generateShareText(
        puzzle: Puzzle,
        completionTime: TimeInterval,
        movesUsed: Int,
        livesLeft: Int,
        isDaily: Bool = false,
        streak: Int? = nil
    ) -> String {
        var result = ""
        
        // Header
        if isDaily {
            result += "\(Self.dailyEmoji) \(Self.appName) Daily Puzzle\n"
            if let streak = streak, streak > 0 {
                result += "\(Self.streakEmoji) \(streak) day streak\n"
            }
        } else {
            result += "\(Self.puzzleEmoji) \(Self.appName)\n"
            result += "Level \(extractLevelNumber(from: puzzle.id) ?? 0) - \(puzzle.difficulty)\n"
        }
        
        result += "\n"
        
        // Stats (clean and focused)
        result += "\(Self.timeEmoji) \(formatTime(completionTime))\n"
        result += "\(Self.movesEmoji) \(movesUsed) moves\n"
        result += "\(Self.livesEmoji) \(livesLeft) \(livesLeft == 1 ? "life" : "lives") left\n"
        
        return result
    }
    
    
    /// Generates shareable content with simplified stats
    /// - Parameters:
    ///   - puzzle: The completed puzzle
    ///   - completionTime: Time taken to complete
    ///   - movesUsed: Number of moves made during gameplay
    ///   - livesLeft: Number of lives remaining
    ///   - isDaily: Whether this is a daily puzzle
    ///   - streak: Daily streak (if daily puzzle)
    /// - Returns: Share data including text and image
    public func generateShareContent(
        puzzle: Puzzle,
        completionTime: TimeInterval,
        movesUsed: Int,
        livesLeft: Int,
        isDaily: Bool = false,
        streak: Int? = nil
    ) -> ShareContent {
        let text = generateShareText(
            puzzle: puzzle,
            completionTime: completionTime,
            movesUsed: movesUsed,
            livesLeft: livesLeft,
            isDaily: isDaily,
            streak: streak
        )
        
        let image = generateShareImage(
            puzzle: puzzle,
            completionTime: completionTime,
            movesUsed: movesUsed,
            livesLeft: livesLeft,
            isDaily: isDaily,
            streak: streak
        )
        
        return ShareContent(text: text, image: image)
    }
    
    /// Generates a simple stats card image for sharing
    /// - Parameters:
    ///   - puzzle: The completed puzzle
    ///   - completionTime: Time taken to complete
    ///   - movesUsed: Number of moves made during gameplay
    ///   - livesLeft: Number of lives remaining
    ///   - isDaily: Whether this is a daily puzzle
    ///   - streak: Daily streak (if daily puzzle)
    /// - Returns: UIImage for sharing
    private func generateShareImage(
        puzzle: Puzzle,
        completionTime: TimeInterval,
        movesUsed: Int,
        livesLeft: Int,
        isDaily: Bool,
        streak: Int?
    ) -> UIImage? {
        // Create a simple image with the grid visualization
        let size = CGSize(width: 400, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            cgContext.setFillColor(UIColor.systemBackground.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Title
            let titleText = isDaily ? "🗓️ Daily Cross Sums" : "🧩 Cross Sums"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.label
            ]
            
            let titleRect = CGRect(x: 20, y: 20, width: 360, height: 40)
            titleText.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Stats section
            let statsStartY: CGFloat = 80
            var currentY = statsStartY
            
            // Time stat
            let timeText = "\(Self.timeEmoji) \(formatTime(completionTime))"
            let timeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.label
            ]
            let timeRect = CGRect(x: 20, y: currentY, width: 360, height: 30)
            timeText.draw(in: timeRect, withAttributes: timeAttributes)
            currentY += 40
            
            // Moves stat
            let movesText = "\(Self.movesEmoji) \(movesUsed) moves"
            let movesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
            let movesRect = CGRect(x: 20, y: currentY, width: 360, height: 25)
            movesText.draw(in: movesRect, withAttributes: movesAttributes)
            currentY += 35
            
            // Lives stat
            let livesText = "\(Self.livesEmoji) \(livesLeft) \(livesLeft == 1 ? "life" : "lives") left"
            let livesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
            let livesRect = CGRect(x: 20, y: currentY, width: 360, height: 25)
            livesText.draw(in: livesRect, withAttributes: livesAttributes)
            currentY += 35
            
            // Streak (if daily)
            if let streak = streak, streak > 0, isDaily {
                let streakText = "\(Self.streakEmoji) \(streak) day streak"
                let streakAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18),
                    .foregroundColor: UIColor.systemOrange
                ]
                let streakRect = CGRect(x: 20, y: currentY, width: 360, height: 25)
                streakText.draw(in: streakRect, withAttributes: streakAttributes)
                currentY += 35
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    private func extractLevelNumber(from puzzleId: String) -> Int? {
        let components = puzzleId.components(separatedBy: "-")
        guard components.count >= 2,
              let level = Int(components.last ?? "") else {
            return nil
        }
        return level
    }
}

// MARK: - Supporting Types

/// Contains shareable content including text and image
public struct ShareContent {
    public let text: String
    public let image: UIImage?
    
    public init(text: String, image: UIImage?) {
        self.text = text
        self.image = image
    }
}