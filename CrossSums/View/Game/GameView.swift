import SwiftUI

struct GameView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Game View")
                .font(.title)
            
            Text("Puzzle: \(gameViewModel.currentPuzzle?.id ?? "none")")
                .font(.body)
            
            Button("Back to Menu") {
                dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("← Menu") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    GameView(gameViewModel: GameViewModel())
}