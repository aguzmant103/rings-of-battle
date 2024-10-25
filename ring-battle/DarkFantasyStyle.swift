import SwiftUI

struct CustomDarkFantasyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(minWidth: 200)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)), Color(#colorLiteral(red: 0.3, green: 0.1, blue: 0.1, alpha: 1))]), startPoint: .top, endPoint: .bottom)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(#colorLiteral(red: 0.8, green: 0.5, blue: 0.1, alpha: 1)), lineWidth: 2)
            )
            .foregroundColor(.white)
            .font(.custom("Copperplate", size: 20))
            .cornerRadius(15)
            .shadow(color: .red.opacity(0.5), radius: 5, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct CustomDarkFantasyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(#colorLiteral(red: 0.8, green: 0.5, blue: 0.1, alpha: 1)), lineWidth: 2)
            )
            .foregroundColor(.white)
            .font(.custom("Copperplate", size: 18))
            .shadow(color: .red.opacity(0.3), radius: 3, x: 0, y: 3)
    }
}
