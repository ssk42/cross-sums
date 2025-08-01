import SwiftUI
import UIKit

struct PuzzleCellView: View {
    let number: Int
    let cellState: Bool?? // nil = unmarked, true = kept, false = removed
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDrag: (Bool) -> Void
    
    @State private var isPressed: Bool = false
    @State private var isLongPressing: Bool = false
    @State private var longPressTimer: Timer?
    
    // Accessibility properties
    private var accessibilityStateDescription: String {
        if let state = cellState, let actualState = state {
            return actualState ? "kept" : "removed"
        } else {
            return "unmarked"
        }
    }
    
    private var accessibilityFullDescription: String {
        "Number \(number), currently \(accessibilityStateDescription)"
    }
    
    private var accessibilityHintText: String {
        if let state = cellState, let actualState = state {
            if actualState {
                return "This number is kept and included in the sum. Double tap to remove, or triple tap to clear."
            } else {
                return "This number is removed and excluded from the sum. Double tap to keep, or triple tap to clear."
            }
        } else {
            return "This number is unmarked. Double tap to keep, triple tap to remove."
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .stroke(borderColor, lineWidth: 2)
            
            // Number text
            Text("\(number)")
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .scaleEffect(isPressed ? 0.95 : 1.0)
            
            // State indicator overlay
            if let state = cellState, let actualState = state {
                // Show state indicator
                RoundedRectangle(cornerRadius: 6)
                    .fill(stateOverlayColor(for: actualState))
                    .opacity(0.3)
                    .scaleEffect(0.85)
            }
            
            // Long press feedback overlay
            if isLongPressing {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.red)
                    .opacity(0.4)
                    .scaleEffect(0.9)
                    .overlay(
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(isLongPressing ? 1.2 : 0.8)
                    )
                    .animation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true), value: isLongPressing)
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
            // Medium haptic feedback for long press
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.15)) {
                longPressTimer?.invalidate()
                longPressTimer = nil
                isLongPressing = false
                onLongPress()
            }
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
                
                if pressing {
                    // Start timer to show long press visual after delay
                    longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isLongPressing = true
                        }
                    }
                } else {
                    // Cancel timer and hide long press visual
                    longPressTimer?.invalidate()
                    longPressTimer = nil
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isLongPressing = false
                    }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // Cancel long press timer if drag starts
                    longPressTimer?.invalidate()
                    longPressTimer = nil
                    isLongPressing = false
                    
                    // This is called when the drag starts or changes
                    // We can use this to indicate a drag is in progress
                    onDrag(true)
                }
                .onEnded { _ in
                    // This is called when the drag ends
                    onDrag(false)
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cellState)
        .modifier(PuzzleCellAccessibilityModifier(
            number: number,
            cellState: cellState,
            onTap: onTap,
            onLongPress: onLongPress,
            onDrag: onDrag
        ))
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
        let numberString = String(number)
        switch numberString.count {
        case 1:
            return 20 // Original size for single digits
        case 2:
            return 20 // Better readability for double digits with automatic scaling fallback
        default:
            return 11 // Better readability for three or more digits with automatic scaling fallback
        }
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
                PuzzleCellView(
                    number: 5, 
                    cellState: nil,
                    onTap: { print("Unmarked cell tapped") },
                    onLongPress: { print("Unmarked cell long pressed") },
                    onDrag: { _ in print("Unmarked cell dragged") }
                )
                .frame(width: 60, height: 60)
            }
            
            VStack {
                Text("Kept")
                    .font(.caption)
                PuzzleCellView(
                    number: 8, 
                    cellState: true,
                    onTap: { print("Kept cell tapped") },
                    onLongPress: { print("Kept cell long pressed") },
                    onDrag: { _ in print("Kept cell dragged") }
                )
                .frame(width: 60, height: 60)
            }
            
            VStack {
                Text("Removed")
                    .font(.caption)
                PuzzleCellView(
                    number: 3, 
                    cellState: false,
                    onTap: { print("Removed cell tapped") },
                    onLongPress: { print("Removed cell long pressed") },
                    onDrag: { _ in print("Removed cell dragged") }
                )
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
                
                PuzzleCellView(
                    number: 12, 
                    cellState: cellState,
                    onTap: {
                        // Single tap -> Keep
                        cellState = true
                    },
                    onLongPress: {
                        // Long press -> Remove
                        cellState = false
                    },
                    onDrag: { isDragging in
                        // Handle drag gesture for clearing
                        if !isDragging {
                            cellState = nil
                        }
                    }
                )
                .frame(width: 80, height: 80)
                
                Text(stateDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack {
                    Text("Single tap: Keep (green)")
                        .font(.caption)
                    Text("Long press: Remove (red)")
                        .font(.caption)
                    Text("Drag: Clear")
                        .font(.caption)
                }
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

// MARK: - Accessibility Modifier

struct PuzzleCellAccessibilityModifier: ViewModifier {
    let number: Int
    let cellState: Bool??
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDrag: (Bool) -> Void
    
    private var accessibilityStateDescription: String {
        if let state = cellState, let actualState = state {
            return actualState ? "kept" : "removed"
        } else {
            return "unmarked"
        }
    }
    
    private var accessibilityFullDescription: String {
        "Number \(number), currently \(accessibilityStateDescription)"
    }
    
    private var accessibilityHintText: String {
        if let state = cellState, let actualState = state {
            if actualState {
                return "This number is kept and included in the sum. Double tap to remove, or triple tap to clear."
            } else {
                return "This number is removed and excluded from the sum. Double tap to keep, or triple tap to clear."
            }
        } else {
            return "This number is unmarked. Double tap to keep, triple tap to remove."
        }
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(accessibilityFullDescription)
            .accessibilityHint(accessibilityHintText)
            .accessibilityValue(accessibilityStateDescription)
            .accessibilityAction(.default) {
                onTap()
            }
            .accessibilityAction(named: "Mark as kept") {
                if cellState != true {
                    onTap()
                }
            }
            .accessibilityAction(named: "Mark as removed") {
                onLongPress()
            }
            .accessibilityAction(named: "Clear marking") {
                if cellState != nil {
                    onDrag(true)
                    onDrag(false)
                }
            }
    }
    }
