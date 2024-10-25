import SwiftUI

struct CharacterButton: View {
    let character: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(character.lowercased())
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color(#colorLiteral(red: 0.8, green: 0.5, blue: 0.1, alpha: 1)) : Color.clear, lineWidth: 3)
                )
        }
    }
}
