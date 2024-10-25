import SwiftUI
import CoreNFC

struct FormBattleSquadView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var nfcReader = NFCReader()
    @State private var selectedCharacter: String?
    @State private var alertItem: AlertItem?

    var body: some View {
        ZStack {
            // Background Image
            Image("battleground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
            
            // Semi-transparent overlay to improve text readability
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Form Battle Squad")
                    .font(.custom("Papyrus", size: 36))
                    .foregroundColor(.white)
                    .padding()

                HStack(spacing: 20) {
                    CharacterButton(imageName: "archer", isSelected: selectedCharacter == "Archer") {
                        selectedCharacter = "Archer"
                    }
                    CharacterButton(imageName: "warrior", isSelected: selectedCharacter == "Warrior") {
                        selectedCharacter = "Warrior"
                    }
                    CharacterButton(imageName: "mage", isSelected: selectedCharacter == "Mage") {
                        selectedCharacter = "Mage"
                    }
                }
                .padding()

                if let character = selectedCharacter {
                    Text(character)
                        .foregroundColor(.white)
                        .padding()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(#colorLiteral(red: 0.8, green: 0.5, blue: 0.1, alpha: 1)), lineWidth: 2)
                        )
                        .shadow(color: .red.opacity(0.3), radius: 3, x: 0, y: 3)
                        .padding(.horizontal)
                } else {
                    Text("Select a character")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(#colorLiteral(red: 0.8, green: 0.5, blue: 0.1, alpha: 1)), lineWidth: 2)
                        )
                        .shadow(color: .red.opacity(0.3), radius: 3, x: 0, y: 3)
                        .padding(.horizontal)
                }

                Button(action: {
                    addToBattleSquad()
                }) {
                    Text("Add to Battle Squad")
                }
                .buttonStyle(CustomDarkFantasyButtonStyle())
                .disabled(selectedCharacter == nil)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton(action: { presentationMode.wrappedValue.dismiss() }))
        .navigationBarTitle("", displayMode: .inline)
        .alert(item: $alertItem) { alertItem in
            Alert(title: Text(alertItem.title), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
        }
    }

    private func addToBattleSquad() {
        guard let character = selectedCharacter else { return }
        
        nfcReader.writeToNFC(character) { result in
            switch result {
            case .success:
                self.alertItem = AlertItem(title: "Success", message: "Successfully added \(character) to your battle squad!")
                self.selectedCharacter = nil
            case .failure(let error):
                self.alertItem = AlertItem(title: "Error", message: error.localizedDescription)
            }
        }
    }
}

struct CustomBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(#colorLiteral(red: 0.8, green: 0.5, blue: 0.1, alpha: 1)))
                    .imageScale(.large)
            }
            .padding(10)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)), Color(#colorLiteral(red: 0.3, green: 0.1, blue: 0.1, alpha: 1))]), startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(#colorLiteral(red: 0.8, green: 0.5, blue: 0.1, alpha: 1)), lineWidth: 2)
            )
            .shadow(color: .red.opacity(0.5), radius: 5, x: 0, y: 5)
        }
    }
}

struct FormBattleSquadView_Previews: PreviewProvider {
    static var previews: some View {
        FormBattleSquadView()
    }
}

// Add the AlertItem struct at the end of this file
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
