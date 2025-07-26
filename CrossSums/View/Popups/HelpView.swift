import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to Play Cross Sums")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Cross Sums is a number puzzle game where you select numbers to match target sums for each row and column.")
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rules:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("• Tap numbers to keep them (green) or remove them (red)")
                            Text("• Each row must sum to its target number")
                            Text("• Each column must sum to its target number")
                            Text("• You have limited lives - wrong moves cost a life")
                            Text("• Use hints if you get stuck")
                            Text("• Complete all sums correctly to win!")
                        }
                        .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tips:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("• Start with rows/columns that have obvious solutions")
                            Text("• Look for large numbers that must be kept")
                            Text("• Use process of elimination")
                            Text("• Save hints for difficult puzzles")
                        }
                        .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HelpView()
}