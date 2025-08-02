import SwiftUI

struct DailyPuzzleCardView: View {
    @ObservedObject var dailyPuzzleService: DailyPuzzleService
    let onTap: () -> Void
    let onShare: (() -> Void)?
    
    private var isCompleted: Bool {
        dailyPuzzleService.isTodayCompleted()
    }
    
    private var completionTime: TimeInterval? {
        dailyPuzzleService.getTodayCompletionTime()
    }
    
    private var currentStreak: Int {
        dailyPuzzleService.getCurrentStreak()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }
    
    // Color scheme for the card
    private var primaryColor: Color {
        isCompleted ? Color.green : Color.blue
    }
    
    private var accentColor: Color {
        isCompleted ? Color.green : Color.indigo
    }
    
    var body: some View {
        Button(action: isCompleted ? {} : onTap) {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(accentColor)
                                
                                Text("Daily Puzzle")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            
                            Text(dateFormatter.string(from: Date()).uppercased())
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Status Badge
                        statusBadge
                    }
                    
                    // Progress Bar for Streak
                    if currentStreak > 0 {
                        streakProgressView
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Main Content Section
                HStack(spacing: 24) {
                    // Streak Display
                    streakDisplayView
                    
                    Spacer()
                    
                    // Center Action Area
                    centerActionView
                    
                    Spacer()
                    
                    // Difficulty Badge
                    difficultyBadgeView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Bottom Section
                if !isCompleted {
                    bottomCallToActionView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                } else {
                    completedCallToActionView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
            .background(cardBackground)
        }
        .buttonStyle(CardButtonStyle(isEnabled: !isCompleted))
        .shadow(
            color: isCompleted ? Color.green.opacity(0.2) : Color.blue.opacity(0.2),
            radius: 12,
            x: 0,
            y: 6
        )
        .accessibilityLabel(isCompleted ? "Daily puzzle completed" : "Daily puzzle available")
        .accessibilityHint(isCompleted ? "Today's daily puzzle is already completed. Come back tomorrow for the next puzzle." : "Play today's daily puzzle")
        .accessibilityValue(isCompleted ? "Completed in \(completionTime.map(formatTime) ?? "unknown time"). Next puzzle available tomorrow." : "Not completed")
        .padding(.horizontal, 20)
    }
    
    // MARK: - View Components
    
    private var statusBadge: some View {
        Group {
            if isCompleted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("DONE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.green)
                )
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("PLAY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(accentColor)
                )
            }
        }
    }
    
    private var streakProgressView: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
                
                Text("Streak")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(currentStreak) days")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
            
            ProgressView(value: min(Double(currentStreak) / 7.0, 1.0))
                .tint(.orange)
                .scaleEffect(y: 2.0)
        }
    }
    
    private var streakDisplayView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.red.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                if currentStreak > 0 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 2) {
                Text("\(currentStreak)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(currentStreak > 0 ? .orange : .gray)
                
                Text("STREAK")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var centerActionView: some View {
        VStack(spacing: 8) {
            if isCompleted {
                // Completion Display
                VStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    if let time = completionTime {
                        Text(formatTime(time))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    Text("COMPLETED!")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                // Play Prompt
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("START PUZZLE")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(accentColor)
                }
            }
        }
    }
    
    private var difficultyBadgeView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 2) {
                Text("Medium")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                
                Text("LEVEL")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var bottomCallToActionView: some View {
        HStack {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(accentColor.opacity(0.7))
            
            Text("Tap to start today's challenge")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(accentColor.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.08))
        )
    }
    
    private var completedCallToActionView: some View {
        VStack(spacing: 12) {
            // Share button (if callback provided)
            if let onShare = onShare {
                Button(action: onShare) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Share your result")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.08))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Come back tomorrow message
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green.opacity(0.7))
                
                Text("Come back tomorrow for the next puzzle!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.green.opacity(0.8))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.08))
            )
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(.systemBackground), location: 0.0),
                        .init(color: isCompleted ? Color.green.opacity(0.03) : Color.blue.opacity(0.03), location: 0.6),
                        .init(color: isCompleted ? Color.green.opacity(0.08) : Color.blue.opacity(0.08), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                primaryColor.opacity(0.2),
                                primaryColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Custom Button Style

struct CardButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.7)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 30) {
            // Completed state
            DailyPuzzleCardView(
                dailyPuzzleService: {
                    let service = DailyPuzzleService.shared
                    // Mock completed state for preview
                    return service
                }(),
                onTap: {
                    print("Daily puzzle tapped - completed")
                },
                onShare: {
                    print("Daily puzzle share tapped")
                }
            )
            
            // Not completed state  
            DailyPuzzleCardView(
                dailyPuzzleService: DailyPuzzleService.shared,
                onTap: {
                    print("Daily puzzle tapped - not completed")
                },
                onShare: nil
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}