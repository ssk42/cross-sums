import SwiftUI

struct PuzzleCellView: View {
    let number: Int
    let cellState: Bool?? // nil = unmarked, true = kept, false = removed
    let onTap: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                onTap()
            }
        }) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .stroke(borderColor, lineWidth: 2)
                
                // Number text
                Text("\(number)")
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                // State indicator overlay
                if let state = cellState, let actualState = state {
                    // Show state indicator
                    RoundedRectangle(cornerRadius: 6)
                        .fill(stateOverlayColor(for: actualState))
                        .opacity(0.3)
                        .scaleEffect(0.85)
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cellState)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        if let state = cellState, let actualState = state {
            switch actualState {
            case true:  // Kept
                return Color.green.opacity(0.2)
            case false: // Removed
                return Color.red.opacity(0.2)
            }
        } else {
            // Unmarked
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if let state = cellState, let actualState = state {
            switch actualState {
            case true:  // Kept
                return Color.green
            case false: // Removed
                return Color.red
            }
        } else {
            // Unmarked
            return Color(.systemGray4)
        }
    }
    
    private var textColor: Color {
        if let state = cellState, let actualState = state {
            switch actualState {
            case true:  // Kept
                return Color.green.opacity(0.9)
            case false: // Removed
                return Color.red.opacity(0.9)
            }
        } else {
            // Unmarked
            return Color.primary
        }
    }
    
    private func stateOverlayColor(for state: Bool) -> Color {
        switch state {
        case true:  // Kept
            return Color.green
        case false: // Removed
            return Color.red
        }
    }
    
    private var fontSize: CGFloat {
        // Dynamic font size based on cell size - will be adjusted by container
        return 20
    }
}

// MARK: - Preview

#Preview("Cell States") {
    VStack(spacing: 20) {
        Text("Puzzle Cell States")
            .font(.headline)
            .padding()
        
        HStack(spacing: 20) {
            VStack {
                Text("Unmarked")
                    .font(.caption)
                PuzzleCellView(number: 5, cellState: nil) {
                    print("Unmarked cell tapped")
                }
                .frame(width: 60, height: 60)
            }
            
            VStack {
                Text("Kept")
                    .font(.caption)
                PuzzleCellView(number: 8, cellState: true) {
                    print("Kept cell tapped")
                }
                .frame(width: 60, height: 60)
            }
            
            VStack {
                Text("Removed")
                    .font(.caption)
                PuzzleCellView(number: 3, cellState: false) {
                    print("Removed cell tapped")
                }
                .frame(width: 60, height: 60)
            }
        }
        
        Text("Tap cells to change states")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
    }
    .padding()
}

#Preview("Interactive Demo") {
    struct InteractiveDemo: View {
        @State private var cellState: Bool?? = nil
        
        var body: some View {
            VStack(spacing: 30) {
                Text("Interactive Cell Demo")
                    .font(.headline)
                
                PuzzleCellView(number: 12, cellState: cellState) {
                    // Cycle through states: nil -> true -> false -> nil
                    if cellState == nil {
                        cellState = true // Mark as kept
                    } else if let state = cellState, let actualState = state {
                        if actualState {
                            cellState = false // Mark as removed
                        } else {
                            cellState = nil // Mark as unmarked
                        }
                    }
                }
                .frame(width: 80, height: 80)
                
                Text(stateDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("Tap to cycle through states")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        
        private var stateDescription: String {
            if cellState == nil {
                return "Unmarked"
            } else if let state = cellState, let actualState = state {
                return actualState ? "Kept (included in sum)" : "Removed (excluded from sum)"
            } else {
                return "Unknown state"
            }
        }
    }
    
    return InteractiveDemo()
}