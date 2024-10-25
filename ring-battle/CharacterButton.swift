import SwiftUI

struct CharacterButton: View {
    let imageName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
                )
        }
        .background(Color.gray.opacity(0.3))
        .cornerRadius(10)
    }
}
