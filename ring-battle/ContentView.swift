//
//  ContentView.swift
//  ring-battle
//
//  Created by Andres Guzman  on 21/10/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedOption: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Image
                Image("ring-battle-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                
                // Semi-transparent overlay to improve text readability
                Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                
                // Menu Content
                VStack(spacing: 30) {
                    Text("Ring Battle")
                        .font(.custom("Papyrus", size: 48)) // You can replace "Papyrus" with any fantasy-style font you have
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 0)

                    NavigationLink(value: "Duel") {
                        Text("Duel (offline)")
                    }
                    .buttonStyle(CustomDarkFantasyButtonStyle())

                    NavigationLink(value: "FormBattleSquad") {
                        Text("Form Battle Squad")
                    }
                    .buttonStyle(CustomDarkFantasyButtonStyle())

                    Button("Battle Arena (online)") {
                        // TODO: Implement Battle Arena functionality
                    }
                    .buttonStyle(CustomDarkFantasyButtonStyle())
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "Duel":
                    DuelView()
                case "FormBattleSquad":
                    FormBattleSquadView()
                default:
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct DarkFantasyButtonStyle: ButtonStyle {
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
            .font(.custom("Copperplate", size: 20)) // You can replace "Copperplate" with any fantasy-style font you have
            .cornerRadius(15)
            .shadow(color: .red.opacity(0.5), radius: 5, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
